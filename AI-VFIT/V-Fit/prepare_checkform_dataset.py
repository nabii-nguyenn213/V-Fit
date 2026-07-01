#!/usr/bin/env python3
"""
Prepare AI check-form dataset from raw exercise videos.

Expected project structure:
  data/raw_videos/raw/*.MOV
  data/raw_videos/squat_down/
  data/raw_videos/squat_up/
  data/raw_videos/pushup_down/
  data/raw_videos/pushup_up/
  data/raw_videos/other/

Main workflows:
  1) Make annotation CSV template:
     python prepare_checkform_dataset.py --root . --make-template

  2) Cut/sort using a reviewed CSV:
     python prepare_checkform_dataset.py --root . --from-csv data/annotations/video_segments.csv

  3) Auto estimate segments using MediaPipe pose, write CSV only:
     python prepare_checkform_dataset.py --root . --auto-segment --dry-run

  4) Auto estimate and cut directly:
     python prepare_checkform_dataset.py --root . --auto-segment

  5) Auto sort each whole video into one class:
     python prepare_checkform_dataset.py --root . --auto-sort

CSV columns:
  filename,label,start,end,notes

Labels:
  squat_down, squat_up, pushup_down, pushup_up, other

Time format:
  seconds, e.g. 1.25
  or HH:MM:SS, e.g. 00:00:01.25
  empty start = 0
  empty end = full video
"""

from __future__ import annotations

import argparse
import csv
import math
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional

import cv2
import numpy as np

VALID_LABELS = {"squat_down", "squat_up", "pushup_down", "pushup_up", "other"}
VIDEO_EXTS = {".mov", ".mp4", ".avi", ".mkv", ".m4v"}


@dataclass
class Segment:
    filename: str
    label: str
    start: float
    end: Optional[float]
    notes: str = ""


def parse_time(value: str | float | int | None) -> Optional[float]:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    value = str(value).strip()
    if value == "":
        return None
    if ":" not in value:
        return float(value)
    parts = value.split(":")
    if len(parts) == 3:
        h, m, s = parts
        return int(h) * 3600 + int(m) * 60 + float(s)
    if len(parts) == 2:
        m, s = parts
        return int(m) * 60 + float(s)
    raise ValueError(f"Invalid time format: {value}")


def fmt_time(t: Optional[float]) -> str:
    if t is None:
        return ""
    return f"{float(t):.3f}".rstrip("0").rstrip(".")


def project_paths(root: Path) -> dict[str, Path]:
    data = root / "data"
    raw_videos = data / "raw_videos"
    raw = raw_videos / "raw"
    annotations = data / "annotations"
    return {
        "data": data,
        "raw_videos": raw_videos,
        "raw": raw,
        "annotations": annotations,
        "template_csv": annotations / "video_segments.csv",
        "auto_csv": annotations / "auto_segments.csv",
    }


def ensure_dirs(root: Path) -> None:
    paths = project_paths(root)
    paths["raw"].mkdir(parents=True, exist_ok=True)
    paths["annotations"].mkdir(parents=True, exist_ok=True)
    for label in VALID_LABELS:
        (paths["raw_videos"] / label).mkdir(parents=True, exist_ok=True)


def list_videos(raw_dir: Path) -> list[Path]:
    if not raw_dir.exists():
        return []
    return sorted([p for p in raw_dir.iterdir() if p.is_file() and p.suffix.lower() in VIDEO_EXTS])


def video_duration(video_path: Path) -> float:
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        return 0.0
    fps = cap.get(cv2.CAP_PROP_FPS) or 0
    frames = cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0
    cap.release()
    if fps <= 0:
        return 0.0
    return float(frames / fps)


def make_template(root: Path) -> Path:
    ensure_dirs(root)
    paths = project_paths(root)
    videos = list_videos(paths["raw"])
    out_csv = paths["template_csv"]
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["filename", "label", "start", "end", "notes"])
        writer.writeheader()
        for p in videos:
            writer.writerow({
                "filename": p.name,
                "label": "",
                "start": "",
                "end": "",
                "notes": "fill label; split into more rows if video has multiple phases",
            })
    return out_csv


def read_segments(csv_path: Path) -> list[Segment]:
    rows: list[Segment] = []
    with csv_path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        required = {"filename", "label", "start", "end"}
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise ValueError(f"CSV missing columns: {sorted(missing)}")
        for i, row in enumerate(reader, start=2):
            filename = (row.get("filename") or "").strip()
            label = (row.get("label") or "").strip()
            notes = (row.get("notes") or "").strip()
            if not filename:
                continue
            if not label:
                print(f"[skip line {i}] no label for {filename}")
                continue
            if label not in VALID_LABELS:
                raise ValueError(f"Line {i}: invalid label {label!r}. Valid: {sorted(VALID_LABELS)}")
            start = parse_time(row.get("start"))
            end = parse_time(row.get("end"))
            rows.append(Segment(filename=filename, label=label, start=start or 0.0, end=end, notes=notes))
    return rows


def run_ffmpeg_cut(src: Path, dst: Path, start: float = 0.0, end: Optional[float] = None, reencode: bool = False) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)

    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    if start and start > 0:
        cmd += ["-ss", fmt_time(start)]
    cmd += ["-i", str(src)]
    if end is not None and end > start:
        duration = end - start
        cmd += ["-t", fmt_time(duration)]

    if reencode:
        # More compatible output; slower but handles odd .MOV metadata better.
        cmd += ["-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-c:a", "aac"]
    else:
        # Fast copy; may cut only at keyframes.
        cmd += ["-c", "copy"]

    cmd += [str(dst)]

    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError:
        if not reencode:
            print(f"[warn] stream-copy failed, retrying with reencode: {src.name}")
            run_ffmpeg_cut(src, dst, start=start, end=end, reencode=True)
        else:
            raise


def unique_output_path(base_dir: Path, stem: str, label: str, idx: int, ext: str = ".mp4") -> Path:
    candidate = base_dir / label / f"{stem}_{label}_{idx:02d}{ext}"
    n = idx
    while candidate.exists():
        n += 1
        candidate = base_dir / label / f"{stem}_{label}_{n:02d}{ext}"
    return candidate


def cut_from_csv(root: Path, csv_path: Path, reencode: bool = False) -> None:
    ensure_dirs(root)
    paths = project_paths(root)
    segments = read_segments(csv_path)
    if not segments:
        print("No valid labeled rows found.")
        return

    counters: dict[tuple[str, str], int] = {}
    ok = 0
    failed = 0

    for seg in segments:
        src = paths["raw"] / seg.filename
        if not src.exists():
            print(f"[missing] {src}")
            failed += 1
            continue

        key = (src.stem, seg.label)
        counters[key] = counters.get(key, 0) + 1
        out = unique_output_path(paths["raw_videos"], src.stem, seg.label, counters[key])

        try:
            if seg.label == "other":
                # Keep other videos as-is unless the user provided a segment range.
                if (seg.start or 0) == 0 and seg.end is None:
                    shutil.copy2(src, out.with_suffix(src.suffix))
                else:
                    run_ffmpeg_cut(src, out, seg.start, seg.end, reencode=reencode)
            else:
                run_ffmpeg_cut(src, out, seg.start, seg.end, reencode=reencode)
            print(f"[ok] {seg.filename} -> {seg.label}/{out.name}")
            ok += 1
        except Exception as e:
            print(f"[fail] {seg.filename}: {e}")
            failed += 1

    print(f"\nDone. OK={ok}, failed={failed}")


# ---------- MediaPipe auto tools ----------

def import_mediapipe():
    try:
        import mediapipe as mp  # type: ignore
        return mp
    except Exception as e:
        print("MediaPipe is required for --auto-sort / --auto-segment.")
        print("Install with:")
        print("  pip install mediapipe opencv-python numpy")
        raise e


def lm_xy(landmarks, idx: int) -> np.ndarray:
    lm = landmarks[idx]
    return np.array([lm.x, lm.y], dtype=np.float32)


def lm_vis(landmarks, idx: int) -> float:
    return float(landmarks[idx].visibility)


def angle_deg(a: np.ndarray, b: np.ndarray, c: np.ndarray) -> float:
    ba = a - b
    bc = c - b
    denom = float(np.linalg.norm(ba) * np.linalg.norm(bc))
    if denom < 1e-8:
        return float("nan")
    cos = float(np.dot(ba, bc) / denom)
    cos = max(-1.0, min(1.0, cos))
    return float(math.degrees(math.acos(cos)))


def moving_average(x: np.ndarray, win: int = 7) -> np.ndarray:
    if len(x) < win:
        return x.copy()
    pad = win // 2
    xp = np.pad(x, (pad, pad), mode="edge")
    kernel = np.ones(win) / win
    return np.convolve(xp, kernel, mode="valid")


def fill_nans(x: np.ndarray) -> np.ndarray:
    x = x.astype(float)
    good = np.isfinite(x)
    if good.sum() == 0:
        return x
    idx = np.arange(len(x))
    x[~good] = np.interp(idx[~good], idx[good], x[good])
    return x


def extract_pose_signal(video_path: Path, sample_every: int = 2):
    mp = import_mediapipe()
    pose_cls = mp.solutions.pose.Pose

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open video: {video_path}")

    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    times: list[float] = []
    squat_angles: list[float] = []
    pushup_angles: list[float] = []
    vertical_scores: list[float] = []
    valid_count = 0
    frame_idx = 0

    with pose_cls(
        static_image_mode=False,
        model_complexity=1,
        enable_segmentation=False,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    ) as pose:
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            if frame_idx % sample_every != 0:
                frame_idx += 1
                continue

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            res = pose.process(rgb)
            t = frame_idx / fps
            times.append(t)

            if not res.pose_landmarks:
                squat_angles.append(float("nan"))
                pushup_angles.append(float("nan"))
                vertical_scores.append(float("nan"))
                frame_idx += 1
                continue

            lms = res.pose_landmarks.landmark
            valid_count += 1

            # Indices: shoulder 11/12, elbow 13/14, wrist 15/16,
            # hip 23/24, knee 25/26, ankle 27/28.
            left_knee = angle_deg(lm_xy(lms, 23), lm_xy(lms, 25), lm_xy(lms, 27))
            right_knee = angle_deg(lm_xy(lms, 24), lm_xy(lms, 26), lm_xy(lms, 28))
            left_elbow = angle_deg(lm_xy(lms, 11), lm_xy(lms, 13), lm_xy(lms, 15))
            right_elbow = angle_deg(lm_xy(lms, 12), lm_xy(lms, 14), lm_xy(lms, 16))

            # Average visible side(s).
            knee_vals = []
            if min(lm_vis(lms, 23), lm_vis(lms, 25), lm_vis(lms, 27)) > 0.4:
                knee_vals.append(left_knee)
            if min(lm_vis(lms, 24), lm_vis(lms, 26), lm_vis(lms, 28)) > 0.4:
                knee_vals.append(right_knee)
            elbow_vals = []
            if min(lm_vis(lms, 11), lm_vis(lms, 13), lm_vis(lms, 15)) > 0.4:
                elbow_vals.append(left_elbow)
            if min(lm_vis(lms, 12), lm_vis(lms, 14), lm_vis(lms, 16)) > 0.4:
                elbow_vals.append(right_elbow)

            squat_angles.append(float(np.nanmean(knee_vals)) if knee_vals else float("nan"))
            pushup_angles.append(float(np.nanmean(elbow_vals)) if elbow_vals else float("nan"))

            shoulder_mid = (lm_xy(lms, 11) + lm_xy(lms, 12)) / 2
            hip_mid = (lm_xy(lms, 23) + lm_xy(lms, 24)) / 2
            v = shoulder_mid - hip_mid
            vertical = abs(float(v[1])) / (abs(float(v[0])) + abs(float(v[1])) + 1e-6)
            vertical_scores.append(vertical)
            frame_idx += 1

    cap.release()

    times_np = np.array(times, dtype=float)
    if len(times_np) == 0:
        raise RuntimeError(f"No frames read: {video_path}")

    detection_ratio = valid_count / max(1, len(times_np))
    vertical_median = float(np.nanmedian(np.array(vertical_scores, dtype=float)))
    exercise = "squat" if vertical_median >= 0.55 else "pushup"

    if exercise == "squat":
        signal = fill_nans(np.array(squat_angles, dtype=float))
    else:
        signal = fill_nans(np.array(pushup_angles, dtype=float))

    if not np.isfinite(signal).any():
        raise RuntimeError(f"No usable pose angle signal: {video_path}")
    signal = moving_average(signal, win=7)

    return times_np[: len(signal)], signal, exercise, detection_ratio, vertical_median


def infer_whole_video_label(video_path: Path, threshold_deg: float = 10.0) -> tuple[str, str, float]:
    times, signal, exercise, detection_ratio, vertical_median = extract_pose_signal(video_path)
    n = len(signal)
    k = max(3, int(0.15 * n))
    start_med = float(np.nanmedian(signal[:k]))
    end_med = float(np.nanmedian(signal[-k:]))
    delta = end_med - start_med

    if detection_ratio < 0.45:
        return "other", f"low pose detection {detection_ratio:.2f}", 0.0
    if abs(delta) < threshold_deg:
        return "other", f"unclear angle delta {delta:.1f}", delta

    phase = "up" if delta > 0 else "down"
    label = f"{exercise}_{phase}"
    return label, f"exercise={exercise}, delta={delta:.1f}, vertical={vertical_median:.2f}", delta


def auto_sort(root: Path, reencode: bool = False) -> None:
    ensure_dirs(root)
    paths = project_paths(root)
    videos = list_videos(paths["raw"])
    if not videos:
        print(f"No videos found in {paths['raw']}")
        return

    summary = []
    for i, src in enumerate(videos, start=1):
        print(f"\n[{i}/{len(videos)}] {src.name}")
        try:
            label, notes, _ = infer_whole_video_label(src)
        except Exception as e:
            label, notes = "other", f"auto failed: {e}"
        dst = unique_output_path(paths["raw_videos"], src.stem, label, 1)
        try:
            run_ffmpeg_cut(src, dst, 0.0, None, reencode=reencode)
            print(f"  -> {label}/{dst.name} ({notes})")
        except Exception as e:
            print(f"  [fail] {e}")
        summary.append({"filename": src.name, "label": label, "start": "", "end": "", "notes": notes})

    out_csv = paths["annotations"] / "auto_sort_summary.csv"
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["filename", "label", "start", "end", "notes"])
        writer.writeheader()
        writer.writerows(summary)
    print(f"\nSaved summary: {out_csv}")


def auto_segments_for_video(video_path: Path, threshold_deg: float = 12.0, min_duration: float = 0.35) -> tuple[list[Segment], str]:
    times, signal, exercise, detection_ratio, vertical_median = extract_pose_signal(video_path)
    if detection_ratio < 0.45:
        return [Segment(video_path.name, "other", 0.0, None, f"low pose detection {detection_ratio:.2f}")], "low_pose"

    # derivative sign; smooth small noise.
    d = np.diff(signal)
    eps = 0.6
    signs = np.zeros_like(d)
    signs[d > eps] = 1
    signs[d < -eps] = -1

    # Fill zeros with nearest previous non-zero sign, then next sign.
    for i in range(1, len(signs)):
        if signs[i] == 0:
            signs[i] = signs[i - 1]
    for i in range(len(signs) - 2, -1, -1):
        if signs[i] == 0:
            signs[i] = signs[i + 1]

    segments: list[Segment] = []
    start_idx = 0
    current = signs[0] if len(signs) else 0

    def add_run(a: int, b: int, sign: float):
        if sign == 0:
            return
        start_t = float(times[a])
        end_t = float(times[min(b + 1, len(times) - 1)])
        if end_t - start_t < min_duration:
            return
        delta = float(signal[min(b + 1, len(signal) - 1)] - signal[a])
        if abs(delta) < threshold_deg:
            return
        phase = "up" if delta > 0 else "down"
        label = f"{exercise}_{phase}"
        notes = f"auto_segment exercise={exercise}, delta={delta:.1f}, detection={detection_ratio:.2f}, vertical={vertical_median:.2f}"
        segments.append(Segment(video_path.name, label, start_t, end_t, notes))

    for i in range(1, len(signs)):
        if signs[i] != current:
            add_run(start_idx, i, current)
            start_idx = i
            current = signs[i]
    if len(signs):
        add_run(start_idx, len(signs) - 1, current)

    if not segments:
        # Fallback: whole-video label.
        label, notes, _ = infer_whole_video_label(video_path)
        segments = [Segment(video_path.name, label, 0.0, None, "fallback whole video; " + notes)]

    return segments, "ok"


def write_segments_csv(segments: Iterable[Segment], out_csv: Path) -> None:
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["filename", "label", "start", "end", "notes"])
        writer.writeheader()
        for s in segments:
            writer.writerow({
                "filename": s.filename,
                "label": s.label,
                "start": fmt_time(s.start),
                "end": fmt_time(s.end),
                "notes": s.notes,
            })


def auto_segment(root: Path, dry_run: bool = False, reencode: bool = False) -> None:
    ensure_dirs(root)
    paths = project_paths(root)
    videos = list_videos(paths["raw"])
    if not videos:
        print(f"No videos found in {paths['raw']}")
        return

    all_segments: list[Segment] = []
    for i, src in enumerate(videos, start=1):
        print(f"\n[{i}/{len(videos)}] analyzing {src.name}")
        try:
            segs, status = auto_segments_for_video(src)
            print(f"  found {len(segs)} segment(s), status={status}")
            for s in segs:
                print(f"   - {s.label}: {fmt_time(s.start)} -> {fmt_time(s.end)}")
            all_segments.extend(segs)
        except Exception as e:
            print(f"  [auto failed] {e}")
            all_segments.append(Segment(src.name, "other", 0.0, None, f"auto failed: {e}"))

    write_segments_csv(all_segments, paths["auto_csv"])
    print(f"\nAuto CSV saved to: {paths['auto_csv']}")

    if dry_run:
        print("Dry-run only. Review/edit the CSV, then run:")
        print(f"  python {Path(__file__).name} --root {root} --from-csv {paths['auto_csv']}")
        return

    print("\nCutting/sorting from auto CSV...")
    cut_from_csv(root, paths["auto_csv"], reencode=reencode)


def main():
    parser = argparse.ArgumentParser(description="Cut and organize AI check-form raw videos.")
    parser.add_argument("--root", type=Path, default=Path("."), help="Project root containing data/raw_videos/raw")
    parser.add_argument("--make-template", action="store_true", help="Create data/annotations/video_segments.csv")
    parser.add_argument("--from-csv", type=Path, help="Cut/sort using annotation CSV")
    parser.add_argument("--auto-sort", action="store_true", help="Infer one label for each whole video and sort")
    parser.add_argument("--auto-segment", action="store_true", help="Infer movement segments and cut/sort")
    parser.add_argument("--dry-run", action="store_true", help="For auto-segment: only write CSV, do not cut")
    parser.add_argument("--reencode", action="store_true", help="Re-encode videos instead of stream-copy; slower but more reliable cuts")
    args = parser.parse_args()

    root = args.root.resolve()
    ensure_dirs(root)

    if args.make_template:
        out = make_template(root)
        print(f"Template created: {out}")
        return

    if args.from_csv:
        cut_from_csv(root, args.from_csv.resolve(), reencode=args.reencode)
        return

    if args.auto_sort:
        auto_sort(root, reencode=args.reencode)
        return

    if args.auto_segment:
        auto_segment(root, dry_run=args.dry_run, reencode=args.reencode)
        return

    parser.print_help()


if __name__ == "__main__":
    main()
