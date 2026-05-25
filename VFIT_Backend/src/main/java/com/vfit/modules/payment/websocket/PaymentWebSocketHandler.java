package com.vfit.modules.payment.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Slf4j
@Component
@RequiredArgsConstructor
public class PaymentWebSocketHandler extends TextWebSocketHandler {
    private final ObjectMapper objectMapper;
    private final ConcurrentHashMap<String, Set<WebSocketSession>> sessionsByUserId = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        String userId = userId(session);
        sessionsByUserId.computeIfAbsent(userId, ignored -> ConcurrentHashMap.newKeySet()).add(session);
        log.info("[PAYMENT_WS] Connected userId={}, sessionId={}", userId, session.getId());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        removeSession(session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        log.warn("[PAYMENT_WS] Transport error sessionId={}, message={}", session.getId(), exception.getMessage());
        removeSession(session);
    }

    public void publishPaymentPaid(String userId, String paymentId, java.time.Instant paidAt) {
        publish(userId, PaymentWebSocketEvent.paid(paymentId, paidAt));
    }

    private void publish(String userId, PaymentWebSocketEvent event) {
        Set<WebSocketSession> sessions = sessionsByUserId.get(userId);
        if (sessions == null || sessions.isEmpty()) {
            log.info("[PAYMENT_WS] No active sessions for userId={}, paymentId={}", userId, event.paymentId());
            return;
        }
        try {
            TextMessage message = new TextMessage(objectMapper.writeValueAsString(event));
            sessions.removeIf(session -> !send(session, message));
            log.info("[PAYMENT_WS] Published event type={}, paymentId={}, userId={}, activeSessions={}",
                    event.type(), event.paymentId(), userId, sessions.size());
        } catch (IOException ex) {
            log.warn("[PAYMENT_WS] Cannot serialize event paymentId={}, message={}", event.paymentId(), ex.getMessage());
        }
    }

    private boolean send(WebSocketSession session, TextMessage message) {
        if (!session.isOpen()) {
            return false;
        }
        try {
            synchronized (session) {
                session.sendMessage(message);
            }
            return true;
        } catch (IOException ex) {
            log.warn("[PAYMENT_WS] Cannot send event sessionId={}, message={}", session.getId(), ex.getMessage());
            return false;
        }
    }

    private void removeSession(WebSocketSession session) {
        String userId = userId(session);
        Set<WebSocketSession> sessions = sessionsByUserId.get(userId);
        if (sessions != null) {
            sessions.remove(session);
            if (sessions.isEmpty()) {
                sessionsByUserId.remove(userId);
            }
        }
        log.info("[PAYMENT_WS] Disconnected userId={}, sessionId={}", userId, session.getId());
    }

    private String userId(WebSocketSession session) {
        Object userId = session.getAttributes().get("userId");
        return userId == null ? "" : userId.toString();
    }
}
