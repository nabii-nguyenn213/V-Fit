# Research Notes: AI Backend Connection and Integration

## Findings & Technical Choices

### 1. gemini-web2api Authentication & Integration
- **Decision**: Leverage zero-auth mode locally for `gemini-web2api` running on port 8081. The RecommendationSystem connects to it at `http://localhost:8081/v1/chat/completions`.
- **Rationale**: Simplifies development and does not expose API keys in local development environment. For production, OpenAI-style Bearer auth key will be defined in `config.json`.
- **Alternatives Considered**: Direct Google API calls. Rejected because `gemini-web2api` simulates the web interface for free unlimited queries, which is optimal for development.

### 2. Flutter Dynamic Base URL Resolution
- **Decision**: Define `aiBaseUrl` and `aiBaseUrlCandidates` in `Environment` similar to `apiBaseUrl`.
  - Android emulator -> `http://10.0.2.2:8000`
  - Web/Desktop/Simulator -> `http://localhost:8000`
  - Custom override using `String.fromEnvironment('AI_BASE_URL')` for physical devices/production.
- **Rationale**: Standardizes API configuration across environments without modifying code.
- **Alternatives Considered**: Hardcoded IPs. Rejected because it breaks when switching between emulator and physical devices.

### 3. Prompt Governance
- **Decision**: Move the AI Coach prompt template from FastAPI router (`coach_router.py`) to the file `skills/conversation/coach_prompt.md`. RecommendationSystem will read this file at startup.
- **Rationale**: Adheres to V-FIT Constitution Principle II. Prompts are treated as versioned assets.
- **Alternatives Considered**: Hardcoded python strings. Rejected as it violates prompt governance guidelines.

### 4. VIP Access Gate
- **Decision**: Check `user.isVipActive` inside the GoRouter redirect or inside the page view of `AICoachPage`. If the user is not VIP, show a beautiful upgrade banner instead of the chat interface.
- **Rationale**: Protects AI resources and encourages user conversion.
