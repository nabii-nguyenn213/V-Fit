class ImbalanceDetector:
    def __init__(self):
        # Tỷ lệ chuẩn (giả định) giữa các phần cơ thể so với bề ngang thân người
        self.ideal_proportions = {
            "arms": 0.25,
            "legs": 0.45
        }

    def detect_muscle_imbalance(self, body_measurements):
        """
        body_measurements: Dict chứa độ dày (pixel) từ Segmentation Mask.
        """
        lacking_muscles = []
        excess_areas = []
        messages = []

        torso = body_measurements.get('torso_thickness', 1)
        arms = body_measurements.get('arms_thickness', 0)
        legs = body_measurements.get('legs_thickness', 0)
        waist = body_measurements.get('waist_thickness', 0)

        # 1. Kiểm tra thiếu cơ tay
        if (arms / torso) < self.ideal_proportions["arms"] * 0.8:
            lacking_muscles.append("Cơ tay/Vai")
            messages.append("Phần thân trên (tay/vai) của bạn đang hơi mỏng so với tổng thể.")

        # 2. Kiểm tra thiếu cơ chân (Chicken legs)
        if (legs / torso) < self.ideal_proportions["legs"] * 0.8:
            lacking_muscles.append("Cơ đùi/Chân")
            messages.append("Phần thân dưới nhỏ hơn tiêu chuẩn. Bạn đang bị mất cân bằng trên-dưới (Chicken legs).")

        # 3. Kiểm tra thừa mỡ bụng
        if waist > torso * 0.9: 
            excess_areas.append("Bụng/Eo")
            messages.append("Vòng 2 của bạn đang khá lớn, có dấu hiệu tích tụ mỡ thừa.")

        return {
            "lacking_muscles": lacking_muscles,
            "excess_areas": excess_areas,
            "details": messages
        }