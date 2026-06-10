# Research: Real-time Body Scan Onboarding Flow

## Persistence Layer Protocol Decision

### Decision
Use a standard REST POST endpoint (`/api/v1/users/onboarding/realtime`) to persist the final real-time body analysis result, rather than saving it directly through the WebSocket handler or keeping a persistent connection open.

### Rationale
- **State Management**: WebSockets in V-FIT are designed for low-latency streaming frame-by-frame. Doing complex DB operations, updating user status, and triggering downstream events inside the WebSocket connection can lead to connection blocking and leaks.
- **Error Handling**: Standard REST APIs have robust exception handling filters, return structured HTTP error codes, and are easier to retry if the initial request fails due to temporary network issues.
- **Security & Authorization**: REST controllers enforce clear JWT auth filters and are guarded correctly by spring security.

### Alternatives Considered
- **Direct Save via WebSocket**: Let the WebSocket handler call the repository and save to MongoDB directly once a valid frame is detected.
  - *Why rejected*: Unnecessary coupling of the streaming server with persistence logic. If the DB save fails, communicating the error back to the client and retrying over WebSocket is complex and non-standard.
- **Manual Screenshot Upload**: Rely on capturing a frame locally and uploading it.
  - *Why rejected*: The user specifically requested a real-time experience where the system automatically detects body posture and completes without manual capture steps.
