class PostureAnalyzer:
    def __init__(self):
        pass

    def _calculate_distance(self, p1, p2):
        import math
        return math.sqrt((p1['x'] - p2['x'])**2 + (p1['y'] - p2['y'])**2)

    def analyze_shape(self, landmarks, silhouette_data=None):
        """
        Phân tích form dáng tổng thể (Gầy, Béo, Vừa).
        """
        # Bề ngang vai và hông
        shoulder_width = self._calculate_distance(landmarks['left_shoulder'], landmarks['right_shoulder'])
        hip_width = self._calculate_distance(landmarks['left_hip'], landmarks['right_hip'])
        
        # --- SỬA LỖI LOGIC: ĐO CHIỀU DÀI LƯNG ĐỂ TÌM NGƯỜI GẦY ---
        # Tính chiều dài từ vai xuống hông
        torso_length = self._calculate_distance(landmarks['left_shoulder'], landmarks['left_hip'])
        
        # Tính độ dày/mỏng của khung xương ($frame\_thickness = \frac{shoulder\_width}{torso\_length}$)
        # Người gầy bề ngang sẽ rất hẹp so với chiều dài lưng
        frame_thickness = shoulder_width / torso_length if torso_length > 0 else 1.0

        # Tỷ lệ Vai/Hông để đoán dáng người cơ bản
        ratio = shoulder_width / hip_width if hip_width > 0 else 0

        result = {
            "shoulder_hip_ratio": round(ratio, 2),
            "body_type": "Chưa xác định",
            "description": ""
        }

        # Đánh giá dựa trên khung xương (Chuyển sang không dấu)
        if ratio > 1.3:
            result["body_type"] = "Dang chu V (Can doi/The thao)" 
        elif 0.95 <= ratio <= 1.3:
            result["body_type"] = "Dang chu nhat (Trung binh)"
        else:
            result["body_type"] = "Dang qua le (Hong to)"

        # Tích hợp dữ liệu mask (mỡ/cơ)
        if silhouette_data:
            fat_percentage = silhouette_data.get('body_fat_estimate', 15)
            
            # --- CẬP NHẬT LOGIC KIỂM TRA THÔNG MINH HƠN ---
            # 1. Nếu khung người mỏng (frame_thickness < 0.85) -> Bắt buộc là người gầy
            if frame_thickness < 0.85 or fat_percentage < 12:
                result["body_type"] += " - Dang thieu can (Gay)"
                result["description"] = "Khung xuong ban kha mong. Can an nhieu de tang can (Bulking)."
            
            # 2. Chỉ phán thừa cân nếu mỡ > 25% VÀ khung người không bị gầy
            elif fat_percentage > 25 and frame_thickness >= 0.85:
                result["body_type"] += " - Dang thua can"
                result["description"] = "Co the ban dang co ty le mo kha cao."
            
            # 3. Các trường hợp còn lại là khỏe mạnh
            else:
                result["description"] = "Ban co ty le mo/co o muc tuong doi khoe manh."

        return result