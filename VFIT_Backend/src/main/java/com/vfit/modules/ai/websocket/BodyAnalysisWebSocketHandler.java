package com.vfit.modules.ai.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import java.nio.ByteBuffer;
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
public class BodyAnalysisWebSocketHandler extends BinaryWebSocketHandler {
    private final AiClient aiClient;
    private final ObjectMapper objectMapper;
    private final AiWebSocketFrameRateLimiter frameRateLimiter;
    private final AppProperties appProperties;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        configureSessionLimits(session);
        super.afterConnectionEstablished(session);
    }

    @Override
    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) throws Exception {
        String userId = session.getAttributes().get("userId").toString();
        byte[] bytes = payloadBytes(message);
        int maxFrameBytes = toIntBytes(appProperties.getWebsocket().getAiMaxFrameSize());
        if (bytes.length > maxFrameBytes) {
            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(AiBodyAnalysisResult.safeFallback())));
            session.close(new CloseStatus(1009, "AI frame too large"));
            return;
        }

        if (!frameRateLimiter.allow(userId)) {
            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(AiBodyAnalysisResult.safeFallback())));
            session.close(CloseStatus.POLICY_VIOLATION.withReason("AI rate limit exceeded"));
            return;
        }

        AiBodyAnalysisResult result = aiClient.analyzeBody(
                userId,
                "realtime-frame",
                Map.of("frameBytes", bytes));
        session.sendMessage(new TextMessage(objectMapper.writeValueAsString(result)));
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
}
