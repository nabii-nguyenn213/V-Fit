from fastapi import APIRouter, UploadFile, File, HTTPException
from gemini_client import gemini_image_json

router = APIRouter(
    prefix="/api/v1/food-scanner",
    tags=["Food Scanner"]
)


@router.post("/")
async def scan_food(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="File phải là ảnh"
        )

    image_bytes = await file.read()

    prompt = """
Bạn là V-Fit Food Scanner.

Hãy phân tích ảnh món ăn và ước lượng dinh dưỡng.

Yêu cầu:
- Nhận diện món ăn
- Ước lượng khẩu phần
- Ước lượng calories, protein, carb, fat
- Nếu không chắc chắn, confidence thấp
- Trả về ONLY JSON hợp lệ

Format:
{
  "food_name": "",
  "items": [],
  "portion_estimate": "",
  "total_calories": 0,
  "protein_g": 0,
  "carbs_g": 0,
  "fat_g": 0,
  "confidence": 0,
  "note": ""
}
"""

    try:
        return gemini_image_json(image_bytes, prompt)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))