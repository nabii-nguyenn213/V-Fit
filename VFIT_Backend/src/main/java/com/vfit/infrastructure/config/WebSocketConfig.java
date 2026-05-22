package com.vfit.infrastructure.config;

import com.vfit.modules.ai.websocket.FormCheckWebSocketHandler;
import com.vfit.modules.ai.websocket.JwtPremiumHandshakeInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {
    private final FormCheckWebSocketHandler formCheckWebSocketHandler;
    private final JwtPremiumHandshakeInterceptor jwtPremiumHandshakeInterceptor;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(formCheckWebSocketHandler, "/ws/ai/form-check")
                .addInterceptors(jwtPremiumHandshakeInterceptor)
                .setAllowedOriginPatterns("*");
    }
}
