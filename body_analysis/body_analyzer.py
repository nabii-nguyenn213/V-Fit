from .posture_analyzer import PostureAnalyzer
from .imbalance_detector import ImbalanceDetector

class BodyAnalyzer:
    def __init__(self):
        # Khởi tạo 2 class theo đúng cấu trúc 3 file
        self.posture_analyzer = PostureAnalyzer()
        self.imbalance_detector = ImbalanceDetector()

    def generate_report(self, landmarks, body_measurements=None):
        """
        Hàm chính nhận dữ liệu từ Camera (main.py)
        """
        # 1. Chỉ chặn lại nếu không có khung xương (landmarks)
        if not landmarks:
            return {"status": "error", "message": "Không tìm thấy người trong camera."}

        # 2. Tạo dữ liệu giả lập tạm thời nếu chưa có Segmentation Mask
        if body_measurements is None:
            body_measurements = {
                'torso_thickness': 100,
                'arms_thickness': 20,   
                'legs_thickness': 45,
                'waist_thickness': 80,
                'body_fat_estimate': 30
            }

        # 3. Đánh giá béo/gầy/dáng người (Vẫn tính toán tốt dựa trên landmarks)
        shape_report = self.posture_analyzer.analyze_shape(landmarks, body_measurements)

        # 4. Phát hiện thừa mỡ, thiếu cơ
        imbalance_report = self.imbalance_detector.detect_muscle_imbalance(body_measurements)

        # 5. Tổng hợp Recommendation
        recommendations = []
        if "Cơ đùi/Chân" in imbalance_report["lacking_muscles"]:
            recommendations.append("Ưu tiên các bài Squat, Lunges, Leg Press.")
        if "Cơ tay/Vai" in imbalance_report["lacking_muscles"]:
            recommendations.append("Tăng cường Push-up, Pull-up, hoặc tập tạ tay.")
        if "Bụng/Eo" in imbalance_report["excess_areas"]:
            recommendations.append("Cần kết hợp Cardio (Chạy bộ, HIIT) và ăn thâm hụt Calo để giảm mỡ.")

        return {
            "status": "success",  # <-- Đảm bảo trả về success để main.py nhận diện
            "body_type": shape_report["body_type"],
            "general_description": shape_report["description"],
            "muscle_analysis": imbalance_report,
            "workout_recommendations": recommendations
        }
    
    
