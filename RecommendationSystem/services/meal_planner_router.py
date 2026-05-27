from fastapi import APIRouter, HTTPException
from schema.meal_schema import MealPlanRequest
from gemini_client import gemini_json

router = APIRouter(
    prefix="/api/v1/meal-planner",
    tags=["Meal Planner"]
)


@router.post("/")
def create_meal_plan(request: MealPlanRequest):
    prompt = f"""
Bạn là V-Fit Nutrition Planner.

Hãy tạo kế hoạch dinh dưỡng cá nhân hóa bằng tiếng Việt.

Thông tin người dùng:
- Tuổi: {request.age}
- Giới tính: {request.gender}
- Cân nặng: {request.weight}kg
- Chiều cao: {request.height}cm
- Mục tiêu: {request.goal}
- Mức vận động: {request.activity_level}
- Số bữa/ngày: {request.meals_per_day}

Yêu cầu:
- Tính calories/ngày hợp lý
- Tính protein, carb, fat
- Gợi ý bữa sáng, trưa, tối, ăn nhẹ nếu cần
- Không khuyên ăn quá ít calories
- Trả về ONLY JSON hợp lệ

Format:
{{
  "daily_calories": 0,
  "protein_g": 0,
  "carbs_g": 0,
  "fat_g": 0,
  "meal_plan": {{
    "breakfast": [],
    "lunch": [],
    "dinner": [],
    "snack": []
  }},
  "note": ""
}}
"""

    try:
        return gemini_json(prompt)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))