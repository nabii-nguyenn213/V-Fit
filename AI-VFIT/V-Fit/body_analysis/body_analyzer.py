# file: body_analysis/body_analyzer.py
import math
import os
from dotenv import load_dotenv
from body_analysis.body_shape_predictor import BodyShapePredictor
from body_analysis.imbalance_detector import ImbalanceDetector

load_dotenv()

class BodyAnalyzer:
    def __init__(self):
        # Get model path from environment variable or use default
        model_path = os.getenv("MODEL_PATH_BODY_DETECT", "best.pt")
        
        # Khởi tạo mô hình AI nhìn dáng (YOLO)
        self.shape_predictor = BodyShapePredictor(model_path=model_path)
        self.imbalance_detector = ImbalanceDetector()
        # self.imbalance_detector = ImbalanceDetector() # GIỮ NGUYÊN NẾU CÓ
        
    def generate_report(self, frame, keypoints):
        try:
            # 1. Tính bề ngang vai thực tế bằng Pixel từ khung xương MediaPipe
            shoulder_width_px = 0
            if keypoints and 'left_shoulder' in keypoints and 'right_shoulder' in keypoints:
                ls = keypoints['left_shoulder']
                rs = keypoints['right_shoulder']
                # Định lý Pytago tính khoảng cách 2 điểm
                shoulder_width_px = math.sqrt((ls['x'] - rs['x'])**2 + (ls['y'] - rs['y'])**2)
            
            # 2. Quăng ảnh camera và độ rộng vai cho YOLO phán xử
            shape_report = self.shape_predictor.predict(frame, shoulder_width_px)
            
            # 3. Gom kết quả lỗi vẹo (nếu có)
            # imbalances = self.imbalance_detector.detect_imbalance(keypoints) if keypoints else []

            return {
                "status": "success",
                "body_type": shape_report["body_shape"],
                "general_description": shape_report["description"],
                "metrics": {
                    "fat_ratio": shape_report.get("fat_ratio"),
                    "shoulder_width_px": shoulder_width_px,
                },
                "recommendations": self._recommendations(shape_report["body_shape"]),
                # "imbalance_issues": imbalances # GIỮ NGUYÊN NẾU CÓ
            }
        except Exception as e:
            print(f"Lỗi BodyAnalyzer: {e}")
            return {"status": "error"}

    def _recommendations(self, body_shape):
        if "GAY" in body_shape:
            return ["Tap trung hypertrophy, tang calories va protein."]
        if "BEO" in body_shape:
            return ["Tap trung giam mo, cardio vua phai va tap suc manh."]
        if "CAN DOI" in body_shape:
            return ["Duy tri lich tap hien tai va tang dan do kho."]
        return ["Tiep tuc duy tri van dong deu va quet lai khi anh ro hon."]
