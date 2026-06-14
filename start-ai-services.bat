@echo off
title V-Fit AI Services Runner

set PYTHONUTF8=1
set PYTHONIOENCODING=utf-8

echo ===================================================
echo Cleaning up previous instances of AI services...
echo ===================================================
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8082" ^| findstr "LISTENING"') do taskkill /F /PID %%a 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8000" ^| findstr "LISTENING"') do taskkill /F /PID %%a 2>nul

echo ===================================================
echo [1/2] Starting Gemini Web2API on port 8082...
echo ===================================================
cd /d "d:\EXE_PRM\gemini-web2api"
start "Gemini Web2API" cmd /k "set PYTHONUTF8=1&& set PYTHONIOENCODING=utf-8&& python gemini_web2api.py"

echo Waiting 3 seconds for Web2API to spin up...
timeout /t 3 /nobreak > nul

echo ===================================================
echo [2/2] Starting Recommendation System on port 8000...
echo ===================================================
cd /d "d:\EXE_PRM\AI-VFIT\V-Fit\RecommendationSystem"
start "Recommendation System" cmd /k "set PYTHONUTF8=1&& set PYTHONIOENCODING=utf-8&& .venv\Scripts\python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload"

echo ===================================================
echo V-Fit AI Services have been launched!
echo Web2API: http://127.0.0.1:8082
echo Recommendation: http://127.0.0.1:8000
echo ===================================================
pause
