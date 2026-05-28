package com.vfit.modules.ai.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.infrastructure.external.ai.dto.AiFormCheckFeedback;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.BinaryMessage;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.BinaryWebSocketHandler;

@Component
@RequiredArgsConstructor
public class FormCheckWebSocketHandler extends BinaryWebSocketHandler {
    private final AiClient aiClient;
    private final ObjectMapper objectMapper;
    private final AiWebSocketFrameRateLimiter frameRateLimiter;

    @Override
    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) throws Exception {
        String userId = session.getAttributes().get("userId").toString();
        String exerciseId = session.getAttributes().get("exerciseId").toString();
        if (!frameRateLimiter.allow(userId)) {
            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(rateLimitedFeedback())));
            session.close(CloseStatus.POLICY_VIOLATION.withReason("AI rate limit exceeded"));
            return;
        }
        AiFormCheckFeedback feedback = aiClient.analyzeForm(
                userId,
                "realtime-frame",
                Map.of("exerciseId", exerciseId, "frameBytes", message.getPayloadLength()));
        session.sendMessage(new TextMessage(objectMapper.writeValueAsString(feedback)));
    }

    private AiFormCheckFeedback rateLimitedFeedback() {
        return new AiFormCheckFeedback(
                0,
                "Bạn đang gửi quá nhiều khung hình. Hãy nghỉ vài giây rồi thử lại.",
                List.of(),
                List.of(),
                "Giữ máy ổn định và gửi lại sau ít giây.",
                "RATE_LIMITED",
                true);
    }
}
