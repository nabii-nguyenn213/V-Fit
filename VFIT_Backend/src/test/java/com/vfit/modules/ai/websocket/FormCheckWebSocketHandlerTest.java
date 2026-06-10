package com.vfit.modules.ai.websocket;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.infrastructure.external.ai.AiClient;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.util.unit.DataSize;
import org.springframework.web.socket.BinaryMessage;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

@ExtendWith(MockitoExtension.class)
class FormCheckWebSocketHandlerTest {
    @Mock
    private AiClient aiClient;

    @Mock
    private AiWebSocketFrameRateLimiter frameRateLimiter;

    @Mock
    private WebSocketSession session;

    private AppProperties appProperties;
    private FormCheckWebSocketHandler handler;

    @BeforeEach
    void setUp() {
        appProperties = new AppProperties();
        handler = new FormCheckWebSocketHandler(
                aiClient,
                new ObjectMapper(),
                frameRateLimiter,
                appProperties);
    }

    @Test
    void afterConnectionEstablishedAppliesConfiguredSessionLimits() throws Exception {
        appProperties.getWebsocket().setMaxTextMessageBufferSize(DataSize.ofKilobytes(64));
        appProperties.getWebsocket().setMaxBinaryMessageBufferSize(DataSize.ofMegabytes(10));

        handler.afterConnectionEstablished(session);

        verify(session).setTextMessageSizeLimit(64 * 1024);
        verify(session).setBinaryMessageSizeLimit(10 * 1024 * 1024);
    }

    @Test
    void frameLargerThanConfiguredLimitReturnsFeedbackAndDoesNotCallAi() throws Exception {
        appProperties.getWebsocket().setAiMaxFrameSize(DataSize.ofKilobytes(1));
        when(session.getId()).thenReturn("session-1");
        when(session.getAttributes()).thenReturn(Map.of(
                "userId", "user-1",
                "exerciseId", "squat",
                "cameraView", "side"));

        handler.handleBinaryMessage(session, new BinaryMessage(new byte[1025]));

        ArgumentCaptor<TextMessage> feedback = ArgumentCaptor.forClass(TextMessage.class);
        verify(session).sendMessage(feedback.capture());
        assertThat(feedback.getValue().getPayload()).contains("FRAME_TOO_LARGE");
        verify(session).close(argThat(status -> status.getCode() == 1009));
        verifyNoInteractions(aiClient);
    }
}
