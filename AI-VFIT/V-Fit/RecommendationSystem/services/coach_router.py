import os
from fastapi import APIRouter, HTTPException
from schema.coach_schema import CoachRequest
from gemini_client import gemini_text

router = APIRouter(
    prefix="/api/v1/coach",
    tags=["AI Coach"]
)

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
# Root of workspace is 4 levels up from services/
PROMPT_PATH = os.path.abspath(os.path.join(CURRENT_DIR, "..", "..", "..", "..", "skills", "conversation", "coach_prompt.md"))

DEFAULT_COACH_PROMPT = """Bạn là V-Fit AI Coach.

Trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu, thực tế.

Thông tin người dùng:
- Tuổi: {age}
- Giới tính: {gender}
- Cân nặng: {weight}kg
- Chiều cao: {height}cm
- Mục tiêu: {goal}
- Mức vận động: {activity_level}

Câu hỏi:
{question}

Lưu ý:
- Không đưa lời khuyên y tế nguy hiểm
- Nếu câu hỏi liên quan bệnh lý, khuyên hỏi chuyên gia
- Ưu tiên fitness, dinh dưỡng, thói quen tập luyện
"""

def get_coach_prompt_template() -> str:
    path = PROMPT_PATH
    if not os.path.exists(path):
        # Try 3 levels up in case of different folder structures
        path = os.path.abspath(os.path.join(CURRENT_DIR, "..", "..", "..", "skills", "conversation", "coach_prompt.md"))
    if not os.path.exists(path):
        # Try relative to current working directory
        path = os.path.abspath(os.path.join(os.getcwd(), "skills", "conversation", "coach_prompt.md"))
    
    if not os.path.exists(path):
        # Return fallback template instead of raising error
        return DEFAULT_COACH_PROMPT
        
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return DEFAULT_COACH_PROMPT

@router.post("/")
def ask_coach(request: CoachRequest):
    template = get_coach_prompt_template()

    prompt = template.format(
        age=request.age,
        gender=request.gender,
        weight=request.weight,
        height=request.height,
        goal=request.goal,
        activity_level=request.activity_level,
        question=request.question
    )

    try:
        answer = gemini_text(prompt)
        return {
            "answer": answer
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))