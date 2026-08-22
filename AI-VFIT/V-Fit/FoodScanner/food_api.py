"""
Food Scanning API Endpoints
For image upload and food calorie estimation
"""

import os
import logging
from io import BytesIO
from base64 import b64decode
from datetime import datetime

import cv2
import numpy as np
from flask import request, jsonify
from flask_cors import cross_origin

from api_server import app
from settings import config
from FoodScanner.gemini_service import scan_food
from FoodScanner.camera import start_camera

logger = logging.getLogger(__name__)

# Upload folder configuration
UPLOAD_FOLDER = config.UPLOAD_FOLDER
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'gif', 'webp'}

os.makedirs(UPLOAD_FOLDER, exist_ok=True)


def allowed_file(filename: str) -> bool:
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


class FoodScanRequest:
    """Represents a food scan request"""
    def __init__(self, image_data, source='upload'):
        self.image_data = image_data
        self.source = source  # 'upload', 'base64', 'camera'
        self.timestamp = datetime.now()
        self.filename = None

    def get_cv2_image(self):
        """Convert image data to OpenCV format"""
        if isinstance(self.image_data, np.ndarray):
            return self.image_data
        
        if isinstance(self.image_data, bytes):
            image = cv2.imdecode(np.frombuffer(self.image_data, np.uint8), cv2.IMREAD_COLOR)
            return image
        
        return None


@app.route('/api/ai/food-scan', methods=['POST'])
@cross_origin()
def food_scan_upload():
    """
    Scan food from uploaded image
    
    Request:
        - File upload: multipart/form-data with 'image' field
        - Base64: JSON with 'image_base64' field
        - Camera: JSON with 'image_base64' field and 'source': 'camera'
    
    Response:
        {
            "success": true,
            "food_name": "Cơm gà",
            "calories": 450,
            "protein_g": 35,
            "carbs_g": 45,
            "fat_g": 15,
            "confidence": 0.85,
            "portion_size": "1 tô",
            "serving_size_g": 300,
            "timestamp": "2026-06-15T10:30:00"
        }
    """
    try:
        scan_request = None
        filename = None

        # Case 1: File upload
        if 'image' in request.files:
            file = request.files['image']
            
            if file.filename == '':
                return jsonify({'error': 'Không chọn tệp'}), 400
            
            if not allowed_file(file.filename):
                return jsonify({'error': 'Loại tệp không được hỗ trợ'}), 400
            
            # Save file
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"food_{timestamp}_{file.filename}"
            filepath = os.path.join(UPLOAD_FOLDER, filename)
            file.save(filepath)
            
            # Read as numpy array
            image_data = cv2.imread(filepath)
            scan_request = FoodScanRequest(image_data, 'upload')
            scan_request.filename = filename
            
        # Case 2: Base64 from JSON
        elif 'image_base64' in request.json:
            image_base64 = request.json.get('image_base64')
            source = request.json.get('source', 'mobile')
            
            try:
                image_bytes = b64decode(image_base64)
                image_data = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
                scan_request = FoodScanRequest(image_data, source)
            except Exception as e:
                logger.error(f"Base64 decode error: {e}")
                return jsonify({'error': 'Định dạng base64 không hợp lệ'}), 400
        
        else:
            return jsonify({'error': 'Cần phải cung cấp hình ảnh'}), 400

        if scan_request is None or scan_request.get_cv2_image() is None:
            return jsonify({'error': 'Không thể xử lý hình ảnh'}), 400

        # Scan food
        logger.info(f"Scanning food from {scan_request.source}")
        result = scan_food(scan_request.get_cv2_image())
        
        # Add metadata
        result['timestamp'] = scan_request.timestamp.isoformat()
        result['source'] = scan_request.source
        if filename:
            result['filename'] = filename
        
        logger.info(f"Food scan result: {result}")
        
        return jsonify({
            'success': True,
            'data': result
        }), 200

    except Exception as e:
        logger.error(f"Food scan error: {e}", exc_info=True)
        return jsonify({
            'error': f'Lỗi khi quét thức ăn: {str(e)}'
        }), 500


@app.route('/api/ai/food-scan/batch', methods=['POST'])
@cross_origin()
def food_scan_batch():
    """
    Batch scan multiple food images
    
    Request:
        {
            "images": [
                {"image_base64": "...", "description": "optional"},
                ...
            ]
        }
    
    Response:
        {
            "success": true,
            "total": 3,
            "results": [
                {food scan result},
                ...
            ],
            "failed": 0
        }
    """
    try:
        data = request.json or {}
        images = data.get('images', [])
        
        if not images or len(images) == 0:
            return jsonify({'error': 'Cần ít nhất 1 hình ảnh'}), 400
        
        if len(images) > 10:
            return jsonify({'error': 'Tối đa 10 hình ảnh mỗi lần'}), 400
        
        results = []
        failed_count = 0
        
        for idx, img_data in enumerate(images):
            try:
                image_base64 = img_data.get('image_base64')
                if not image_base64:
                    failed_count += 1
                    continue
                
                image_bytes = b64decode(image_base64)
                image = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
                
                result = scan_food(image)
                result['index'] = idx
                results.append(result)
            
            except Exception as e:
                logger.warning(f"Batch scan image {idx} failed: {e}")
                failed_count += 1
                continue
        
        return jsonify({
            'success': True,
            'total': len(images),
            'successful': len(results),
            'failed': failed_count,
            'results': results
        }), 200

    except Exception as e:
        logger.error(f"Batch food scan error: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@app.route('/api/ai/food-database', methods=['GET'])
@cross_origin()
def get_food_database():
    """
    Get food calorie database for offline use
    
    Response:
        {
            "success": true,
            "data": {
                "rice": {"calories": 150, "units": {...}},
                ...
            }
        }
    """
    try:
        food_db = {
            "rice": {
                "calories_per_100g": 150,
                "units": {
                    "bowl": 2,
                    "cup": 1.5,
                    "spoon": 0.2,
                    "piece": 1
                }
            },
            "chicken": {
                "calories_per_100g": 165,
                "units": {
                    "piece": 1.5,
                    "serving": 1,
                    "spoon": 0.3
                }
            },
            "fish": {
                "calories_per_100g": 120,
                "units": {
                    "piece": 1.2,
                    "serving": 1,
                    "fillet": 1.5
                }
            },
            "vegetables": {
                "calories_per_100g": 30,
                "units": {
                    "cup": 1,
                    "piece": 0.5,
                    "spoon": 0.1
                }
            },
            "bread": {
                "calories_per_100g": 265,
                "units": {
                    "slice": 1,
                    "piece": 1,
                    "bowl": 2
                }
            }
        }
        
        return jsonify({
            'success': True,
            'data': food_db,
            'updated_at': datetime.now().isoformat()
        }), 200

    except Exception as e:
        logger.error(f"Food database error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/ai/nutrition-estimate', methods=['POST'])
@cross_origin()
def estimate_nutrition():
    """
    Get detailed nutrition estimate for scanned food
    
    Request:
        {
            "food_name": "Cơm gà",
            "portion_size": "1 tô",
            "weight_g": 300
        }
    
    Response:
        {
            "success": true,
            "data": {
                "food_name": "Cơm gà",
                "calories": 450,
                "protein_g": 35,
                "carbs_g": 45,
                "fat_g": 15,
                "fiber_g": 2,
                "sodium_mg": 800,
                "cost_estimate": 25000
            }
        }
    """
    try:
        data = request.json or {}
        food_name = data.get('food_name', '')
        portion_size = data.get('portion_size', '')
        weight_g = data.get('weight_g', 100)
        
        if not food_name:
            return jsonify({'error': 'Cần tên thức ăn'}), 400
        
        # Call Gemini API for detailed nutrition info
        nutrition_result = scan_food(None, food_name=food_name, portion_size=portion_size)
        nutrition_result['weight_g'] = weight_g
        
        return jsonify({
            'success': True,
            'data': nutrition_result
        }), 200

    except Exception as e:
        logger.error(f"Nutrition estimate error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/ai/food-scan/history', methods=['GET'])
@cross_origin()
def get_scan_history():
    """
    Get food scan history (requires auth)
    
    Query params:
        - limit: max results (default 20)
        - offset: pagination (default 0)
        - date: filter by date (YYYY-MM-DD)
    
    Response:
        {
            "success": true,
            "data": [
                {scan results},
                ...
            ],
            "total": 45
        }
    """
    try:
        # TODO: Implement with database (PostgreSQL)
        # Query from database:
        # SELECT * FROM food_scans WHERE user_id = ? ORDER BY created_at DESC
        
        limit = request.args.get('limit', 20, type=int)
        offset = request.args.get('offset', 0, type=int)
        
        # Placeholder response
        return jsonify({
            'success': True,
            'data': [],
            'total': 0,
            'note': 'Database integration needed'
        }), 200

    except Exception as e:
        logger.error(f"History fetch error: {e}")
        return jsonify({'error': str(e)}), 500


# Health check for food scanner
@app.route('/api/ai/food-scan/health', methods=['GET'])
@cross_origin()
def food_scan_health():
    """Health check for food scanning service"""
    try:
        return jsonify({
            'status': 'healthy',
            'service': 'food_scanner',
            'upload_folder': UPLOAD_FOLDER,
            'max_upload_size': config.MAX_UPLOAD_SIZE,
            'allowed_extensions': list(ALLOWED_EXTENSIONS)
        }), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500


if __name__ == '__main__':
    print("Food scanning API endpoints loaded")
    print(f"Upload folder: {UPLOAD_FOLDER}")
    print(f"Max upload size: {config.MAX_UPLOAD_SIZE} bytes")
