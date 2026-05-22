package com.vfit.modules.ai.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.infrastructure.external.ai.AiClient;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.BinaryMessage;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.BinaryWebSocketHandler;

@Component
@RequiredArgsConstructor
public class FormCheckWebSocketHandler extends BinaryWebSocketHandler {
    private final AiClient aiClient;
    private final ObjectMapper objectMapper;

    @Override
    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) throws Exception {
        String userId = session.getAttributes().get("userId").toString();
        String exerciseId = session.getAttributes().get("exerciseId").toString();
        Map<String, Object> feedback = aiClient.analyzeForm(
                userId,
                "realtime-frame",
                Map.of("exerciseId", exerciseId, "frameBytes", message.getPayloadLength()));
        session.sendMessage(new TextMessage(objectMapper.writeValueAsString(feedback)));
    }
}
