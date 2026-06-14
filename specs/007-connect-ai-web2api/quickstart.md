# Quickstart: AI Backend Connection

## Step 1: Start gemini-web2api
Run from the root of `gemini-web2api`:
```bash
python gemini_web2api.py
```
This runs the completion proxy on port `8081`.

## Step 2: Start RecommendationSystem
Run from the root of `AI-VFIT/V-Fit/RecommendationSystem`:
```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```
This runs the FastAPI gateway on port `8000`.

## Step 3: Launch Flutter App
Launch the Flutter app targeting the local backends:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=AI_BASE_URL=http://10.0.2.2:8000
```
