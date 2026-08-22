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

Hãy tạo kế hoạch dinh dưỡng cá nhân hóa cho từng ngày trong tuần (từ Thứ Hai đến Chủ Nhật) bằng tiếng Việt.

Thông tin người dùng:
- Tuổi: {request.age}
- Giới tính: {request.gender}
- Cân nặng: {request.weight}kg
- Chiều cao: {request.height}cm
- Mục tiêu: {request.goal}
- Mức vận động: {request.activity_level}
- Số bữa/ngày: {request.meals_per_day}

Yêu cầu:
- Tính calories/ngày hợp lý cho từng ngày trong tuần (có thể đa dạng món ăn giữa các ngày để tránh nhàm chán).
- Tính protein, carb, fat cho từng ngày.
- Gợi ý chi tiết bữa sáng, trưa, tối, ăn nhẹ tùy thuộc số bữa/ngày.
- Trả về ONLY JSON hợp lệ.

Format:
{{
  "weekly_plan": {{
    "monday": {{
      "daily_calories": 2500,
      "protein_g": 150,
      "carbs_g": 300,
      "fat_g": 70,
      "meal_plan": {{
        "breakfast": ["100g Yến mạch nấu chín", "2 quả Trứng gà"],
        "lunch": ["150g Ức gà áp chảo", "150g Cơm lứt"],
        "dinner": ["150g Cá hồi áp chảo", "Rau luộc"],
        "snack": ["30g Hạnh nhân"]
      }}
    }},
    "tuesday": {{
      "daily_calories": 2500,
      "protein_g": 150,
      "carbs_g": 300,
      "fat_g": 70,
      "meal_plan": {{
        "breakfast": [],
        "lunch": [],
        "dinner": [],
        "snack": []
      }}
    }},
    "wednesday": {{
      "daily_calories": 2500,
      "protein_g": 150,
      "carbs_g": 300,
      "fat_g": 70,
      "meal_plan": {{
        "breakfast": [],
        "lunch": [],
        "dinner": [],
        "snack": []
      }}
    }},
    "thursday": {{
      "daily_calories": 2500,
      "protein_g": 150,
      "carbs_g": 300,
      "fat_g": 70,
      "meal_plan": {{
        "breakfast": [],
        "lunch": [],
        "dinner": [],
        "snack": []
      }}
    }},
    "friday": {{
      "daily_calories": 2500,
      "protein_g": 150,
      "carbs_g": 300,
      "fat_g": 70,
      "meal_plan": {{
        "breakfast": [],
        "lunch": [],
        "dinner": [],
        "snack": []
      }}
    }},
    "saturday": {{
      "daily_calories": 2500,
      "protein_g": 150,
      "carbs_g": 300,
      "fat_g": 70,
      "meal_plan": {{
        "breakfast": [],
        "lunch": [],
        "dinner": [],
        "snack": []
      }}
    }},
    "sunday": {{
      "daily_calories": 2500,
      "protein_g": 150,
      "carbs_g": 300,
      "fat_g": 70,
      "meal_plan": {{
        "breakfast": [],
        "lunch": [],
        "dinner": [],
        "snack": []
      }}
    }}
  }},
  "note": "Lời khuyên dinh dưỡng tổng quan cho cả tuần."
}}
"""

    try:
        return gemini_json(prompt)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))