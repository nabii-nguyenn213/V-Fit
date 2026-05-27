from fastapi import APIRouter, HTTPException
from schema.coach_schema import CoachRequest
from gemini_client import gemini_text

router = APIRouter(
    prefix="/api/v1/coach",
    tags=["AI Coach"]
)


@router.post("/")
def ask_coach(request: CoachRequest):
    prompt = f"""
Bạn là V-Fit AI Coach.

Trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu, thực tế.

Thông tin người dùng:
- Tuổi: {request.age}
- Giới tính: {request.gender}
- Cân nặng: {request.weight}kg
- Chiều cao: {request.height}cm
- Mục tiêu: {request.goal}
- Mức vận động: {request.activity_level}

Câu hỏi:
{request.question}

Lưu ý:
- Không đưa lời khuyên y tế nguy hiểm
- Nếu câu hỏi liên quan bệnh lý, khuyên hỏi chuyên gia
- Ưu tiên fitness, dinh dưỡng, thói quen tập luyện
"""

    try:
        answer = gemini_text(prompt)
        return {
            "answer": answer
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))