from pydantic import BaseModel


class WorkoutPlanRequest(BaseModel):
    age: int
    gender: str
    weight: float
    height: float
    goal: str
    activity_level: str
    level: str
    days_per_week: int = 4


class WorkoutPlanResponse(BaseModel):
    plan_name: str
    goal: str
    days_per_week: int
    weekly_schedule: dict