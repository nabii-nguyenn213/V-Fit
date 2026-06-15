@echo off
title V-Fit AI Services Runner

echo ===================================================
echo Cleaning up previous instances of AI services...
echo ===================================================
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8082" ^| findstr "LISTENING"') do taskkill /F /PID %%a 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8000" ^| findstr "LISTENING"') do taskkill /F /PID %%a 2>nul
timeout /t 2 /nobreak > nul

echo ===================================================
echo [1/2] Starting Gemini Web2API on port 8082...
echo ===================================================
cd /d "d:\EXE_PRM\gemini-web2api"
start "Gemini Web2API" cmd /k "chcp 65001 && set PYTHONUTF8=1&& set PYTHONIOENCODING=utf-8&& python gemini_web2api.py"

echo Waiting 5 seconds for Web2API to initialize...
timeout /t 5 /nobreak > nul

echo ===================================================
echo [2/2] Starting Recommendation System on port 8000...
echo ===================================================
cd /d "d:\EXE_PRM\AI-VFIT\V-Fit\RecommendationSystem"
start "Recommendation System" cmd /k "chcp 65001 && set PYTHONUTF8=1&& set PYTHONIOENCODING=utf-8&& .venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 8000"

echo ===================================================
echo V-Fit AI Services have been launched!
echo Web2API:         http://127.0.0.1:8082
echo Recommendation:  http://127.0.0.1:8000
echo LAN (Mobile):    http://192.168.1.93:8000
echo ===================================================
pause

