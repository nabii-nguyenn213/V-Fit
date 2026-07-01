"""
Flask API server for V-FIT realtime form checking and body analysis.

The mobile app streams camera frames through the Spring WebSocket gateway.
Spring forwards each frame here as base64. This server keeps lightweight
session state so frame-by-frame responses are stable enough for realtime UI.
"""

import base64
import logging
import logging.handlers
import threading
import time
from dataclasses import dataclass, field
from typing import Any
import os

import cv2
import mediapipe as mp
import numpy as np
from flask import Flask, jsonify, request
from flask_cors import CORS

from body_analysis.body_analyzer import BodyAnalyzer
from form_check.feedback_generator import FEEDBACK_DATABASE
from form_check.feedback_stabilizer import FeedbackStabilizer
from form_check.form_checker import FormChecker
from shared.angle_calculator import calculate_body_angles
from ai_rep_counter.realtime_rep_counter import AIRealtimeRepCounter
from settings import config, ENVIRONMENT

# ==================== LOGGING SETUP ====================
# Configure logging for production-readiness
logger = logging.getLogger(__name__)
logger.setLevel(getattr(logging, config.LOG_LEVEL))

# Console handler
console_handler = logging.StreamHandler()
console_handler.setLevel(getattr(logging, config.LOG_LEVEL))

# File handler (for production)
if not os.path.exists(os.path.dirname(config.LOG_FILE)):
    os.makedirs(os.path.dirname(config.LOG_FILE), exist_ok=True)

file_handler = logging.handlers.RotatingFileHandler(
    config.LOG_FILE,
    maxBytes=10 * 1024 * 1024,  # 10MB
    backupCount=5  # Keep 5 backup files
)
file_handler.setLevel(getattr(logging, config.LOG_LEVEL))

# Formatter
formatter = logging.Formatter(
    '[%(asctime)s] %(levelname)s - %(name)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
console_handler.setFormatter(formatter)
file_handler.setFormatter(formatter)

logger.addHandler(console_handler)
logger.addHandler(file_handler)

logger.info(f"V-Fit AI Server Starting... (Environment: {ENVIRONMENT})")

# ==================== FLASK APP SETUP ====================
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = config.MAX_CONTENT_LENGTH
app.config['SECRET_KEY'] = config.SECRET_KEY

# CORS Configuration - Production-safe
cors_config = {
    "origins": config.CORS_ORIGINS if config.CORS_ORIGINS != ["*"] else "*",
    "methods": ["GET", "POST", "OPTIONS"],
    "allow_headers": ["Content-Type"]
}
CORS(app, resources={r"/api/*": cors_config})

mp_pose = mp.solutions.pose
pose = mp_pose.Pose(
    model_complexity=1,
    min_detection_confidence=0.6,
    min_tracking_confidence=0.6,
    enable_segmentation=False,
)
pose_lock = threading.Lock()

body_analyzer = BodyAnalyzer()
model_lock = threading.Lock()

BODY_SHAPE_REFRESH_SECONDS = 3.0
SESSION_TTL_SECONDS = 10 * 60


@dataclass
class RealtimeSession:
    session_id: str
    frame_count: int = 0
    last_seen_at: float = field(default_factory=time.time)
    last_body_report: dict[str, Any] | None = None
    last_body_report_at: float = 0.0
    stabilizers: dict[str, FeedbackStabilizer] = field(default_factory=dict)
    rep_counter: Any = None


sessions: dict[str, RealtimeSession] = {}
sessions_lock = threading.Lock()
form_checkers: dict[str, FormChecker] = {}


def get_session(session_id: str) -> RealtimeSession:
    now = time.time()
    with sessions_lock:
        expired = [
            key
            for key, value in sessions.items()
            if now - value.last_seen_at > SESSION_TTL_SECONDS
        ]
        for key in expired:
            sessions.pop(key, None)

        session = sessions.get(session_id)
        if session is None:
            session = RealtimeSession(session_id=session_id)
            api_dir = os.path.dirname(os.path.abspath(__file__))
            model_path = os.path.join(api_dir, "ai_rep_counter", "models", "phase_model.pt")
            try:
                session.rep_counter = AIRealtimeRepCounter(model_path=model_path)
            except Exception as e:
                logger.error("Error creating AIRealtimeRepCounter: %s", e)
            sessions[session_id] = session
        session.last_seen_at = now
        return session


def get_or_create_form_checker(exercise: str, camera_view: str = "side"):
    key = f"{exercise}_{camera_view}"
    if key not in form_checkers:
        try:
            form_checkers[key] = FormChecker(exercise=exercise, camera_view=camera_view)
        except Exception as exc:
            logger.error("Error creating form checker: %s", exc)
            return None
    return form_checkers[key]


def decode_frame(frame_base64: str):
    try:
        if "," in frame_base64 and frame_base64.startswith("data:"):
            frame_base64 = frame_base64.split(",", 1)[1]
        frame_data = base64.b64decode(frame_base64)
        nparr = np.frombuffer(frame_data, np.uint8)
        return cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    except Exception as exc:
        logger.error("Error decoding frame: %s", exc)
        return None


def extract_keypoints(results, width: int, height: int):
    if not results.pose_landmarks:
        return None

    keypoints = {}
    for landmark in mp.solutions.pose.PoseLandmark:
        pt = results.pose_landmarks.landmark[landmark.value]
        keypoints[landmark.name.lower()] = {
            "x": pt.x * width,
            "y": pt.y * height,
            "visibility": pt.visibility,
        }
    return keypoints


def detect_pose(frame):
    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    image_rgb.flags.writeable = False
    with pose_lock:
        results = pose.process(image_rgb)
    height, width, _ = frame.shape
    return results, extract_keypoints(results, width, height)


def feedback_summary(feedback):
    if not feedback:
        return "No form feedback available."
    first = feedback[0]
    return first.get("warning") or first.get("correction") or "Form check needs attention."


def feedback_cue(feedback):
    if not feedback:
        return "Keep moving under control."
    return feedback[0].get("correction") or feedback_summary(feedback)


def enrich_errors(errors):
    enriched = []
    for error in errors or []:
        code = error.get("code", "form_check")
        details = FEEDBACK_DATABASE.get(code, {})
        enriched.append(
            {
                **error,
                "message": details.get("warning", code),
                "landmarks": error.get("landmarks", []),
            }
        )
    return enriched


def stabilize_form_result(session: RealtimeSession, exercise: str, camera_view: str, result):
    key = f"{exercise}_{camera_view}"
    stabilizer = session.stabilizers.setdefault(key, FeedbackStabilizer())
    raw_feedback = result.get("feedback") or []
    primary_feedback = raw_feedback[0] if raw_feedback else None
    stable_feedback = stabilizer.update(primary_feedback)
    if stable_feedback is None and not result.get("errors"):
        stable_feedback = primary_feedback
    if stable_feedback is not None:
        result["feedback"] = [stable_feedback]
    return result


def analyze_form_frame(frame, keypoints, session: RealtimeSession, exercise: str, camera_view: str):
    form_checker = get_or_create_form_checker(exercise, camera_view)
    if form_checker is None:
        return None, {"success": False, "error": "Invalid exercise"}

    if keypoints is None:
        result = form_checker.check(None, None)
    else:
        result = form_checker.check(keypoints, calculate_body_angles(keypoints))

    result = stabilize_form_result(session, exercise, camera_view, result)
    feedback = result.get("feedback", [])
    errors = enrich_errors(result.get("errors", []))
    
    rep_result = {
        "rep_count": 0,
        "phase": "no_pose" if keypoints is None else "unknown",
        "label": "no_pose" if keypoints is None else "unknown",
        "confidence": 0.0,
        "enabled": False,
    }
    if keypoints is not None and session.rep_counter is not None:
        try:
            rep_result = session.rep_counter.update(keypoints, exercise)
        except Exception as e:
            logger.error("Error updating rep counter: %s", e)

    return {
        "success": True,
        "score": result.get("score", 0),
        "errors": errors,
        "feedback": feedback,
        "summary": feedback_summary(feedback),
        "cue": feedback_cue(feedback),
        "severity": "OK" if not errors else errors[0].get("severity", "medium").upper(),
        "metrics": result.get("metrics", {}),
        "keypoints_count": len(keypoints) if keypoints else 0,
        "realtime": True,
        "frame_index": session.frame_count,
        "rep_count": rep_result.get("rep_count", 0),
        "phase": rep_result.get("phase", "unknown"),
        "rep_phase": rep_result.get("phase", "unknown"),
        "rep_label": rep_result.get("label", "unknown"),
        "rep_confidence": rep_result.get("confidence", 0.0),
        "rep_counter_enabled": rep_result.get("enabled", False),
    }, None


def posture_from_imbalances(imbalances):
    if not imbalances:
        return "Tu the can bang", 8, "OK"
    risk_score = min(100, 20 + len(imbalances) * 20)
    severity = "HIGH" if risk_score >= 60 else "LOW"
    return "; ".join(imbalances), risk_score, severity


def analyze_body_frame(frame, keypoints, session: RealtimeSession):
    if keypoints is None:
        return {
            "success": True,
            "body_type": "Unknown",
            "body_description": "No person detected",
            "imbalances": ["No person detected"],
            "metrics": {},
            "recommendations": ["Step fully into the camera frame."],
            "posture": {"summary": "No person detected", "riskScore": 0},
            "imbalance": {"summary": "No pose landmarks available.", "severity": "UNKNOWN"},
            "estimate": {"bodyFatPercent": None, "leanMassKg": None, "confidence": 0.0, "waistShoulderRatio": None},
            "recommendation": {"focus": "Center your body in frame", "weeklySessions": 3},
            "fallback": False,
            "realtime": True,
            "frame_index": session.frame_count,
        }

    imbalances = body_analyzer.imbalance_detector.detect_imbalance(keypoints)
    posture_summary, risk_score, imbalance_severity = posture_from_imbalances(imbalances)

    now = time.time()
    should_refresh_shape = (
        session.last_body_report is None
        or now - session.last_body_report_at >= BODY_SHAPE_REFRESH_SECONDS
    )
    if should_refresh_shape:
        with model_lock:
            report = body_analyzer.generate_report(frame=frame, keypoints=keypoints)
        if report and report.get("status") == "success":
            session.last_body_report = report
            session.last_body_report_at = now

    report = session.last_body_report or {
        "body_type": "Analysis pending",
        "general_description": "Body shape model is warming up",
        "metrics": {},
        "recommendations": ["Keep the whole body visible in frame."],
    }

    body_type = report.get("body_type", "Unknown")
    body_description = report.get("general_description", "")
    metrics = report.get("metrics", {}) or {}
    recommendations = report.get("recommendations", []) or []
    focus = recommendations[0] if recommendations else "Continue current routine"
    waist_shoulder_ratio = metrics.get("fat_ratio")
    confidence = 0.85 if waist_shoulder_ratio is not None else 0.35

    return {
        "success": True,
        "body_type": body_type,
        "body_description": body_description,
        "imbalances": imbalances,
        "metrics": metrics,
        "recommendations": recommendations,
        "posture": {
            "summary": f"{body_type} - {body_description}" if body_description else body_type,
            "riskScore": risk_score,
        },
        "imbalance": {
            "summary": posture_summary,
            "severity": imbalance_severity,
        },
        "estimate": {
            "bodyFatPercent": None,
            "leanMassKg": None,
            "confidence": confidence,
            "waistShoulderRatio": waist_shoulder_ratio,
        },
        "recommendation": {"focus": focus, "weeklySessions": 3},
        "fallback": False,
        "realtime": True,
        "frame_index": session.frame_count,
        "body_shape_refreshed": should_refresh_shape,
    }


def request_session_id(data):
    return (
        data.get("session_id")
        or data.get("sessionId")
        or request.headers.get("X-AI-Session-Id")
        or request.remote_addr
        or "default"
    )


def prepare_frame_request():
    data = request.get_json(silent=True) or {}
    if "frame" not in data:
        return None, None, (jsonify({"success": False, "error": "Missing frame data"}), 400)

    frame = decode_frame(data["frame"])
    if frame is None:
        return None, None, (jsonify({"success": False, "error": "Invalid frame data"}), 400)

    session = get_session(request_session_id(data))
    session.frame_count += 1
    return data, (frame, session), None


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "v-fit-ai-server", "realtime": True}), 200


@app.route("/api/ai/form-check", methods=["POST"])
def form_check():
    data, prepared, error = prepare_frame_request()
    if error:
        return error

    frame, session = prepared
    exercise = data.get("exercise", "squat")
    camera_view = data.get("camera_view", data.get("cameraView", "side"))
    _, keypoints = detect_pose(frame)
    response, problem = analyze_form_frame(frame, keypoints, session, exercise, camera_view)
    if problem:
        return jsonify(problem), 400
    return jsonify(response), 200


@app.route("/api/ai/body-analysis", methods=["POST"])
def body_analysis():
    data, prepared, error = prepare_frame_request()
    if error:
        return error

    frame, session = prepared
    _, keypoints = detect_pose(frame)
    return jsonify(analyze_body_frame(frame, keypoints, session)), 200


@app.route("/api/ai/realtime-analysis", methods=["POST"])
def realtime_analysis():
    data, prepared, error = prepare_frame_request()
    if error:
        return error

    frame, session = prepared
    exercise = data.get("exercise", "squat")
    camera_view = data.get("camera_view", data.get("cameraView", "side"))
    modes = data.get("modes") or ["form", "body"]

    _, keypoints = detect_pose(frame)
    response = {
        "success": True,
        "session_id": session.session_id,
        "frame_index": session.frame_count,
        "keypoints_count": len(keypoints) if keypoints else 0,
    }

    if "form" in modes:
        form_response, problem = analyze_form_frame(frame, keypoints, session, exercise, camera_view)
        if problem:
            return jsonify(problem), 400
        response["form"] = form_response

    if "body" in modes:
        response["body"] = analyze_body_frame(frame, keypoints, session)

    return jsonify(response), 200


@app.route("/api/ai/realtime/reset", methods=["POST"])
def reset_realtime_session():
    data = request.get_json(silent=True) or {}
    session_id = request_session_id(data)
    with sessions_lock:
        sessions.pop(session_id, None)
    return jsonify({"success": True, "session_id": session_id}), 200


@app.route("/api/ai/exercises", methods=["GET"])
def get_exercises():
    try:
        from form_check.exercise_registry import EXERCISES

        return jsonify({"success": True, "exercises": EXERCISES}), 200
    except Exception as exc:
        logger.error("Error fetching exercises: %s", exc)
        return jsonify({"success": False, "error": str(exc)}), 500


@app.route("/api/ai/camera-views", methods=["GET"])
def get_camera_views():
    return jsonify({"success": True, "views": ["front", "side", "rear"]}), 200


if __name__ == "__main__":
    logger.info("Starting V-FIT AI API Server...")
    logger.info("Available endpoints:")
    logger.info("  GET  /health")
    logger.info("  GET  /api/ai/exercises")
    logger.info("  GET  /api/ai/camera-views")
    logger.info("  POST /api/ai/form-check")
    logger.info("  POST /api/ai/body-analysis")
    logger.info("  POST /api/ai/realtime-analysis")
    logger.info("  POST /api/ai/realtime/reset")
    
    # ==================== PRODUCTION-READY SERVER STARTUP ====================
    logger.info(f"Starting server on {config.HOST}:{config.PORT}")
    logger.info(f"Environment: {ENVIRONMENT}")
    logger.info(f"Debug mode: {config.DEBUG}")
    
    # For production, use gunicorn instead:
    # gunicorn --workers 4 --worker-class sync --bind 0.0.0.0:5000 api_server:app
    app.run(host=config.HOST, port=config.PORT, debug=config.DEBUG, threaded=True)
