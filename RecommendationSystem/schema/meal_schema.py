from pydantic import BaseModel

class MealPlanRequest(BaseModel):
    age: int
    gender: str
    weight: float
    height: float
    goal: str
    activity_level: str
    meals_per_day: int = 3
