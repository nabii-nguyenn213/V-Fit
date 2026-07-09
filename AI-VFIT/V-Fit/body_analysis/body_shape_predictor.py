# file: body_analysis/body_shape_predictor.py
import numpy as np
import os
from dotenv import load_dotenv
from ultralytics import YOLO

load_dotenv()

class BodyShapePredictor:
    def __init__(self, model_path=None):
        if model_path is None:
            model_path = os.getenv("MODEL_PATH_BODY_DETECT", "best.pt")
        
        # Verify model path exists
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found: {model_path}")
        
        # Load mô hình YOLOv8-seg của bạn
        self.model = YOLO(model_path)

    def predict(self, frame, shoulder_width_px):
        """
        frame: Ảnh từ camera
        shoulder_width_px: Bề ngang khung vai (pixel) lấy từ MediaPipe
        """
        # Chạy YOLO Segmentation
        results = self.model(frame, verbose=False)
        
        if not results or not results[0].masks:
            return {
                "body_shape": "Chưa xác định", 
                "description": "Không tìm thấy mặt nạ cơ thể"
            }

        # Lấy mask (mặt nạ trắng đen) của YOLO
        mask = results[0].masks.data[0].cpu().numpy()
        
        # Lấy kích thước của mask (bị thu nhỏ) và kích thước ảnh gốc
        mask_h, mask_w = mask.shape
        frame_h, frame_w = frame.shape[:2]
        
        # 1. Đo độ dày vùng bụng trên Mask
        waist_y = int(mask_h * 0.60)
        waist_slice = mask[waist_y, :]
        waist_thickness_px = np.sum(waist_slice > 0.1)
        
        # 2. XỬ LÝ NGẦM: Đồng bộ hệ quy chiếu mà không đổi tham số
        if not shoulder_width_px or shoulder_width_px <= 0:
            adjusted_shoulder = mask_w * 0.25 # Ước lượng tạm
        else:
            # Tự động tính tỷ lệ thu nhỏ giữa YOLO mask và ảnh gốc điện thoại
            scale_factor = mask_w / frame_w 
            # Bóp nhỏ số đo vai lại cho cùng hệ quy chiếu với bụng
            adjusted_shoulder = shoulder_width_px * scale_factor

        # 3. Tính tỷ lệ Vàng (Đã được đồng bộ hoàn hảo)
        fat_ratio = waist_thickness_px / adjusted_shoulder
        
        # 4. Phân loại Béo/Gầy
        if fat_ratio < 0.75:
            shape = "Gầy (Thiếu cơ/mỡ)"
            desc = f"Eo/Vai: {fat_ratio:.2f}. Cần tăng cân, tập Hypertrophy."
        elif 0.75 <= fat_ratio <= 0.85:
            shape = "Cân đối (Dáng chữ V)"
            desc = f"Eo/Vai: {fat_ratio:.2f}. Thể hình đẹp, tỷ lệ chuẩn."
        else:
            shape = "Béo (Thừa mỡ)"
            desc = f"Eo/Vai: {fat_ratio:.2f}. Bụng to hơn vai, cần giảm mỡ."
            
        return {
            "body_shape": shape,
            "description": desc,
            "fat_ratio": float(fat_ratio)
        }