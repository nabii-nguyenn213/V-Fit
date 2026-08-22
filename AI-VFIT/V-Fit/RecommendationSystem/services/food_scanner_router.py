from fastapi import APIRouter, HTTPException, File, UploadFile
from pydantic import BaseModel
import base64
import requests
import json
from config import GEMINI_API_KEY, GEMINI_URL
from gemini_client import gemini_json, gemini_image_json

MAX_IMAGE_BYTES = 8 * 1024 * 1024

router = APIRouter(
    prefix="/api/v1/food-scanner",
    tags=["Food Scanner"]
)


class FoodTextRequest(BaseModel):
    food_name: str
    portion: str = "1 phần"


@router.post("/text")
def scan_food_text(request: FoodTextRequest):
    prompt = f"""
Bạn là V-Fit Food Scanner.

Người dùng nhập món ăn:
- Tên món: {request.food_name}
- Khẩu phần: {request.portion}

Hãy ước lượng dinh dưỡng món ăn này.

Yêu cầu:
- Trả về tiếng Việt
- Calories chỉ là ước lượng
- Trả về ONLY JSON hợp lệ
- Không markdown
- Không giải thích ngoài JSON

Format:
{{
  "food_name": "{request.food_name}",
  "portion": "{request.portion}",
  "total_calories": 0,
  "protein_g": 0,
  "carbs_g": 0,
  "fat_g": 0,
  "confidence": 0,
  "note": ""
}}
"""

    try:
        return gemini_json(prompt)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/")
async def scan_food_image(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        if not contents:
            raise HTTPException(status_code=400, detail="Image file is required.")
        if len(contents) > MAX_IMAGE_BYTES:
            raise HTTPException(status_code=413, detail="Image is too large for food scanning.")
        image_base64 = base64.b64encode(contents).decode("utf-8")
        del contents

        prompt = """
Analyze the food image and estimate calories.
Return ONLY valid JSON in Vietnamese.
Do NOT output markdown code blocks (like ```json).
Do NOT output any explanations or text outside the JSON.

Expected JSON structure:
{
  "food_name": "Tên món ăn (tiếng Việt)",
  "portion_estimate": "Khẩu phần ước lượng (ví dụ: 1 đĩa, 1 bát)",
  "total_calories": 500,
  "protein_g": 30.5,
  "carbs_g": 50.0,
  "fat_g": 15.2,
  "confidence": 0.85,
  "note": "Một số lưu ý dinh dưỡng ngắn gọn",
  "items": ["tên các nguyên liệu chính hoặc món ăn phụ kèm theo"]
}
"""

        print(f"[Food Scanner] image={file.filename}, type={file.content_type}, base64_len={len(image_base64)}")
        # gemini_image_json never raises — returns mock data on any failure
        result = gemini_image_json(prompt, image_base64, file.content_type or "image/jpeg")
        print(f"[Food Scanner] Result (truncated): {repr(str(result))[:200]}")
        return result

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        await file.close()

