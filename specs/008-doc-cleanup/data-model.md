# Data Model: Documentation & Configurations

## Entities

### Document File
- **Target File**: `README.md`
- **Source Files**: `CLAUDE.md`, `FEATURES.md`, `REALTIME_AI_INTEGRATION.md`, `docs/AI_AGENT_GUIDE.md`
- **Fields**:
  - Title/Headers
  - Commands & Scripts
  - Architecture Diagrams
  - Endpoints & Ports

### Configuration Mapping
- **App Gateway (`Environment.apiBaseUrl`)**: defaults to `http://localhost:8080` (Spring Boot).
- **AI Recommendation (`Environment.aiBaseUrl`)**: defaults to `http://localhost:8000` (FastAPI).
- **Real-time AI Server (`AI_BASE_URL`)**: defaults to `http://localhost:5000` (Flask).
- **Gemini Web2API Client (`GEMINI_API_URL`)**: defaults to `http://localhost:8081` (FastAPI).
