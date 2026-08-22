from fastapi import APIRouter, HTTPException
from schema.workout_schema import WorkoutPlanRequest
from gemini_client import gemini_json

router = APIRouter(
    prefix="/api/v1/workout-planner",
    tags=["Workout Planner"]
)


@router.post("/")
def create_workout_plan(request: WorkoutPlanRequest):
    prompt = f"""
Bạn là V-Fit Workout Planner.

Hãy tạo lịch tập cá nhân hóa bằng tiếng Việt.

Thông tin người dùng:
- Tuổi: {request.age}
- Giới tính: {request.gender}
- Cân nặng: {request.weight}kg
- Chiều cao: {request.height}cm
- Mục tiêu: {request.goal}
- Mức vận động: {request.activity_level}
- Trình độ: {request.level}
- Số buổi/tuần: {request.days_per_week}

Yêu cầu:
- Có warm-up
- Có bài tập chính
- Có cool-down
- Phù hợp mục tiêu: giảm mỡ / tăng cơ / giữ cân
- Trả về ONLY JSON hợp lệ

Format:
{{
  "plan_name": "",
  "goal": "",
  "days_per_week": 0,
  "weekly_schedule": {{
    "day_1": {{
      "focus": "",
      "warm_up": [],
      "main_workout": [],
      "cool_down": []
    }}
  }},
  "note": ""
}}
"""

    try:
        return gemini_json(prompt)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))