# Real-Time AI Form Checking & Body Analysis Integration

## Giải Pháp

Thay vì chụp ảnh tĩnh, app giờ **stream video realtime** qua WebSocket đến backend. Backend nhận frame liên tục, gửi đến Python AI service xử lý, trả feedback realtime.

## Architecture

```
App (Flutter)
   ↓ (WebSocket stream video)
Backend (Spring Boot WebSocket)
   ↓ (HTTP POST frame)
Python Flask API (AI-VFIT)
   ↓ (MediaPipe + Form Check/Body Analysis)
Result (JSON feedback)
   ↑ (HTTP Response)
Backend (cách rate-limit, cache)
   ↑ (WebSocket send feedback)
App (Display realtime feedback)
```

## Components

### 1. Python Flask API (`api_server.py`)

**Location:** `AI-VFIT/V-Fit/api_server.py`

**Endpoints:**
- `GET /health` - Health check
- `GET /api/ai/exercises` - List available exercises
- `GET /api/ai/camera-views` - List camera views
- `POST /api/ai/form-check` - Realtime form analysis
- `POST /api/ai/body-analysis` - Body shape analysis

**Nhận video frame dạng base64, trả JSON feedback:**

```json
{
  "success": true,
  "score": 85,
  "errors": [
    {
      "code": "KNEE_ALIGNMENT",
      "severity": "WARN",
      "message": "Keep knees aligned with toes",
      "landmarks": ["left_knee", "right_knee"]
    }
  ],
  "feedback": "Form is good, maintain this posture",
  "metrics": {...}
}
```

### 2. Spring Backend WebSocket (`FormCheckWebSocketHandler.java`)

**Location:** `VFIT_Backend/src/main/java/com/vfit/modules/ai/websocket/`

**Already Implemented:**
- Nhận binary video frames qua WebSocket
- Rate limiting per user (configurable)
- Call Python API
- Send feedback back realtime

**Update:** Giờ gọi Python API thực tế (trước là mock data)

### 3. Docker Orchestration

**Updated:** `docker-compose.yml` thêm `vfit-ai-api` service

**Services:**
- `mongodb` - Database
- `redis` - Caching & rate limiting
- `vfit-ai-api` - Python Flask AI (port 5000)
- `vfit-backend` - Spring Backend (port 8080)

## Setup Instructions

### Local Development

1. **Tạo Python API server:**
   ```bash
   cd AI-VFIT/V-Fit
   pip install -r requirements.txt
   python api_server.py
   # Server runs on http://localhost:5000
   ```

2. **Update Backend config** (`VFIT_Backend/.env`):
   ```env
   AI_CLIENT_MODE=http
   AI_BASE_URL=http://localhost:5000
   AI_RATE_LIMIT_MAX_REQUESTS=30
   AI_RATE_LIMIT_WINDOW_SECONDS=60
   ```

3. **Run Spring Backend:**
   ```bash
   cd VFIT_Backend
   mvn spring-boot:run
   ```

4. **Flutter App connects WebSocket:**
   ```dart
   // In Flutter app
   final wsUrl = 'ws://localhost:8080/api/ai/form-check';
   final webSocket = await WebSocket.connect(wsUrl);
   
   // Send video frames
   final frameBytes = await captureFrame(); // from camera
   final frameBase64 = base64Encode(frameBytes);
   webSocket.add(jsonEncode({
     "frame": frameBase64,
     "exercise": "squat",
     "cameraView": "side"
   }));
   
   // Receive feedback
   webSocket.listen((response) {
     final feedback = jsonDecode(response);
     // Update UI with feedback
   });
   ```

### Docker Deployment

1. **Build & run with Docker Compose:**
   ```bash
   cd VFIT_Backend
   docker-compose up -d --build
   ```

   This will:
   - Build Python API image from `AI-VFIT/V-Fit/Dockerfile`
   - Start all services (MongoDB, Redis, AI API, Backend)
   - Backend connects to AI API at `http://vfit-ai-api:5000`

2. **Check services:**
   ```bash
   docker-compose logs -f
   
   # Test Python API
   curl http://localhost:5000/health
   
   # Test Backend
   curl http://localhost:8080/api/health
   ```

## WebSocket Flow

### Connection Handshake
```
App → Backend: ws://backend:8080/api/ai/form-check?token=jwt_token&exerciseId=xxx
Backend: Validate JWT token & extract userId
Backend ↔ App: WebSocket connection established
```

### Realtime Stream Loop
```
App → Backend: Binary message with video frame
Backend:
  1. Validate frame (check rate limit)
  2. Extract metadata (userId, exerciseId)
  3. POST frame to Python API
  4. Receive feedback
  5. Cache result (Redis)
Backend → App: JSON feedback

(Repeat for each frame)
```

### Rate Limiting

**Configuration:**
```env
AI_RATE_LIMIT_MAX_REQUESTS=30      # Frames per window
AI_RATE_LIMIT_WINDOW_SECONDS=60    # Time window
AI_RATE_LIMIT_FAIL_OPEN=false      # Reject if limit exceeded
```

**Behavior:**
- Shared rate limit per user (all exercises)
- If exceeded: reject frame + close WebSocket with `POLICY_VIOLATION` status
- App can reconnect after wait period

## Performance Tuning

### Python API Optimization

1. **Model Loading** (one-time, in `__init__`):
   - MediaPipe Pose model cached
   - BodyAnalyzer cached

2. **Frame Processing**:
   - Configurable model complexity (default: 2 for balance speed/accuracy)
   - Consider lower complexity for mobile devices

3. **Scaling**:
   - Each frame ~100-200ms processing time
   - Recommended: 10 FPS (100-200ms between frames)
   - Use `AiWebSocketFrameRateLimiter` to enforce

### Backend Optimization

1. **Circuit Breaker**:
   - If AI API fails repeatedly → fast-fail to app
   - Prevents cascading failures

2. **Caching** (Redis):
   - Cache exercise metadata
   - Cache body analyzer models if possible

3. **Thread Pool**:
   - Configure async processing if needed

## Testing

### Test Python API

```bash
# Health check
curl http://localhost:5000/health

# Get exercises
curl http://localhost:5000/api/ai/exercises

# Test form check (with base64 frame)
curl -X POST http://localhost:5000/api/ai/form-check \
  -H "Content-Type: application/json" \
  -d '{
    "frame": "base64_encoded_image_data_here",
    "exercise": "squat",
    "camera_view": "side"
  }'
```

### Test WebSocket Connection

```bash
# Install wscat
npm install -g wscat

# Connect to WebSocket
wscat -c ws://localhost:8080/api/ai/form-check \
  --subprotocol formcheck

# Send test frame (example)
{"frame":"base64data","exercise":"squat","cameraView":"side"}
```

## Troubleshooting

### Python API Not Starting
```bash
# Check dependencies
pip install -r requirements.txt

# Test imports
python -c "import mediapipe; print(mediapipe.__version__)"

# Run with debug
FLASK_ENV=development python api_server.py
```

### Backend Can't Reach Python API
```bash
# In docker-compose context
docker exec vfit-backend curl http://vfit-ai-api:5000/health

# Locally
curl http://localhost:5000/health
```

### WebSocket Connection Fails
```bash
# Check logs
docker-compose logs vfit-backend

# Verify WebSocket config in Backend
# Look for FormCheckWebSocketHandler bean initialization
```

### Rate Limiting Too Strict
```
Edit .env:
AI_RATE_LIMIT_MAX_REQUESTS=60
AI_RATE_LIMIT_WINDOW_SECONDS=60
```

## Flutter App Updates Required

The app needs to be updated to:

1. **Stream video frames** instead of single photo
2. **Open WebSocket connection** to `/api/ai/form-check`
3. **Send frames periodically** (e.g., 10 FPS)
4. **Display feedback realtime** as it arrives
5. **Handle connection loss** gracefully

Example integration:

```dart
class FormCheckWebSocketService {
  WebSocket? _webSocket;
  
  Future<void> connect(String exerciseId) async {
    final token = await authRepository.getAccessToken();
    _webSocket = await WebSocket.connect(
      'ws://10.0.2.2:8080/api/ai/form-check?exerciseId=$exerciseId',
      headers: {'Authorization': 'Bearer $token'},
    );
    
    _webSocket!.listen(
      (message) {
        final feedback = jsonDecode(message);
        // Update UI
      },
      onError: (error) => print('WebSocket error: $error'),
      onDone: () => print('WebSocket closed'),
    );
  }
  
  Future<void> sendFrame(Uint8List frameBytes) async {
    if (_webSocket != null) {
      final frameBase64 = base64Encode(frameBytes);
      _webSocket!.add(jsonEncode({
        'frame': frameBase64,
        'exercise': 'squat',
        'cameraView': 'side',
      }));
    }
  }
  
  void close() {
    _webSocket?.close();
  }
}
```

## Next Steps

1. ✅ Python API created
2. ✅ Backend integration (HttpAiClient updated)
3. ✅ Docker setup configured
4. ⏳ Flutter app update needed
5. ⏳ Test WebSocket stream with real device/emulator

**Status:** Ready for testing! 🚀
