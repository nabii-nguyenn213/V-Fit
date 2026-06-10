package com.vfit.modules.ai.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.infrastructure.external.ai.dto.AiFormCheckFeedback;
import java.nio.ByteBuffer;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.BinaryMessage;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.BinaryWebSocketHandler;

@Slf4j
@Component
@RequiredArgsConstructor
public class FormCheckWebSocketHandler extends BinaryWebSocketHandler {
    private final AiClient aiClient;
    private final ObjectMapper objectMapper;
    private final AiWebSocketFrameRateLimiter frameRateLimiter;
    private final AppProperties appProperties;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        configureSessionLimits(session);
        log.info("[AI WS] Connection established. Session ID: {}, attributes: {}", session.getId(), session.getAttributes());
        super.afterConnectionEstablished(session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        log.info("[AI WS] Connection closed. Session ID: {}, Close status: {}", session.getId(), status);
        super.afterConnectionClosed(session, status);
    }

    @Override
    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) throws Exception {
        String userId = session.getAttributes().get("userId").toString();
        String exerciseId = session.getAttributes().get("exerciseId").toString();
        String cameraView = session.getAttributes().getOrDefault("cameraView", "side").toString();
        byte[] bytes = payloadBytes(message);
        log.info("[AI WS] Received binary frame. Session ID: {}, Size: {} bytes, user: {}, exercise: {}, view: {}",
                session.getId(), bytes.length, userId, exerciseId, cameraView);

        int maxFrameBytes = toIntBytes(appProperties.getWebsocket().getAiMaxFrameSize());
        if (bytes.length > maxFrameBytes) {
            log.warn("[AI WS] Frame too large for user: {}. Size: {} bytes, limit: {} bytes.",
                    userId, bytes.length, maxFrameBytes);
            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(frameTooLargeFeedback(maxFrameBytes))));
            session.close(new CloseStatus(1009, "AI frame too large"));
            return;
        }
        
        if (!frameRateLimiter.allow(userId)) {
            log.warn("[AI WS] Rate limit exceeded for user: {}. Closing session.", userId);
            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(rateLimitedFeedback())));
            session.close(CloseStatus.POLICY_VIOLATION.withReason("AI rate limit exceeded"));
            return;
        }
        
        try {
            AiFormCheckFeedback feedback = aiClient.analyzeForm(
                    userId,
                    "realtime-frame",
                    Map.of(
                            "exerciseId", exerciseId,
                            "exercise", normalizeExercise(exerciseId),
                            "cameraView", cameraView,
                            "sessionId", session.getId(),
                            "frameBytes", bytes));
            log.info("[AI WS] AI analysis response received: success={}, repCount={}, phase={}, confidence={}, feedback='{}'",
                    feedback != null,
                    feedback != null ? feedback.repCount() : "null",
                    feedback != null ? feedback.phase() : "null",
                    feedback != null ? feedback.repConfidence() : "null",
                    feedback != null ? feedback.summary() : "null");
            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(feedback)));
        } catch (Exception e) {
            log.error("[AI WS] Error calling AI analysis: {}", e.getMessage(), e);
            throw e;
        }
    }

    private byte[] payloadBytes(BinaryMessage message) {
        ByteBuffer payload = message.getPayload().asReadOnlyBuffer();
        byte[] bytes = new byte[payload.remaining()];
        payload.get(bytes);
        return bytes;
    }

    private void configureSessionLimits(WebSocketSession session) {
        session.setTextMessageSizeLimit(toIntBytes(appProperties.getWebsocket().getMaxTextMessageBufferSize()));
        session.setBinaryMessageSizeLimit(toIntBytes(appProperties.getWebsocket().getMaxBinaryMessageBufferSize()));
    }

    private int toIntBytes(org.springframework.util.unit.DataSize dataSize) {
        return Math.toIntExact(dataSize.toBytes());
    }

    private String normalizeExercise(String exerciseId) {
        if (exerciseId == null || exerciseId.isBlank() || "general".equalsIgnoreCase(exerciseId)) {
            return "squat";
        }
        String normalized = exerciseId.toLowerCase().replace("_", "-").trim();
        if (normalized.contains("push") || normalized.contains("chong-day")) {
            return "pushup";
        }
        if (normalized.contains("squat") || normalized.contains("ngoi-xom")) {
            return "squat";
        }
        return "squat";
    }

    private AiFormCheckFeedback rateLimitedFeedback() {
        return new AiFormCheckFeedback(
                0,
                "Bạn đang gửi quá nhiều khung hình. Hãy nghỉ vài giây rồi thử lại.",
                List.of(),
                List.of(),
                "Giữ máy ổn định và gửi lại sau ít giây.",
                "RATE_LIMITED",
                true,
                0,
                "rate_limited",
                "rate_limited",
                0.0,
                false);
    }

    private AiFormCheckFeedback frameTooLargeFeedback(int maxFrameBytes) {
        int maxFrameKb = maxFrameBytes / 1024;
        return new AiFormCheckFeedback(
                0,
                "Camera frame is too large for realtime AI analysis.",
                List.of(),
                List.of(),
                "Lower camera capture quality or retry with a clearer, steadier view. Max frame size: "
                        + maxFrameKb + "KB.",
                "FRAME_TOO_LARGE",
                true,
                0,
                "frame_too_large",
                "frame_too_large",
                0.0,
                false);
    }
}
