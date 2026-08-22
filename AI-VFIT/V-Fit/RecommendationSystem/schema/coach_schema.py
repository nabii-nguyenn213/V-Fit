from pydantic import BaseModel


class CoachRequest(BaseModel):
    question: str
    age: int
    gender: str
    weight: float
    height: float
    goal: str
    activity_level: str


class CoachResponse(BaseModel):
    answer: str