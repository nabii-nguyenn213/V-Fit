# Research: Documentation Consolidation & Config Verification

## Decision: Consolidate scattered docs into a single root README.md
- **Decision**: Consolidate `CLAUDE.md`, `FEATURES.md`, `REALTIME_AI_INTEGRATION.md`, and `docs/AI_AGENT_GUIDE.md` into the root `README.md`.
- **Rationale**: Reduces workspace noise, simplifies developers' onboarding path, and prevents document fragmentation.
- **Alternatives considered**: Retaining `docs/AI_AGENT_GUIDE.md` separately, but having all information in a single `README.md` is more aligned with the user's "clean code/clean docs" request.

## Decision: Maintain separate ports for AI modules (5000 vs 8000)
- **Decision**: Document and maintain port 8000 for the RecommendationSystem (FastAPI) and port 5000 for the Real-time AI engine (Flask api_server.py).
- **Rationale**: These are two distinct code architectures (FastAPI vs Flask/OpenCV) servicing different client modules (direct Flutter REST query vs Spring Boot proxying WebSocket frames).
- **Alternatives considered**: Merging the two python codebases. However, since they rely on different libraries (FastAPI/Gemini Web2API vs Flask/MediaPipe/OpenCV), keeping them separate prevents dependency bloat and is safer for local deployment.
