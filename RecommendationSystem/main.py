from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from services.coach_router import router as coach_router
from services.food_scanner_router import router as food_scanner_router
from services.meal_planner_router import router as meal_planner_router
from services.workout_planner_router import router as workout_planner_router


app = FastAPI(
    title="V-Fit Recommendation Backend",
    description="Backend AI cho V-Fit: Coach, Food Scanner, Meal Planner, Workout Planner",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {
        "message": "V-Fit Recommendation Backend is running",
        "docs": "/docs"
    }


app.include_router(coach_router)
app.include_router(food_scanner_router)
app.include_router(meal_planner_router)
app.include_router(workout_planner_router)