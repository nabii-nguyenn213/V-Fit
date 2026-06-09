package com.vfit.infrastructure.config;

import com.vfit.modules.ai.websocket.FormCheckWebSocketHandler;
import com.vfit.modules.ai.websocket.BodyAnalysisWebSocketHandler;
import com.vfit.modules.ai.websocket.JwtPremiumHandshakeInterceptor;
import com.vfit.modules.payment.websocket.PaymentHandshakeInterceptor;
import com.vfit.modules.payment.websocket.PaymentWebSocketHandler;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.standard.ServletServerContainerFactoryBean;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {
    private final FormCheckWebSocketHandler formCheckWebSocketHandler;
    private final BodyAnalysisWebSocketHandler bodyAnalysisWebSocketHandler;
    private final JwtPremiumHandshakeInterceptor jwtPremiumHandshakeInterceptor;
    private final PaymentWebSocketHandler paymentWebSocketHandler;
    private final PaymentHandshakeInterceptor paymentHandshakeInterceptor;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(formCheckWebSocketHandler, "/ws/ai/form-check")
                .addInterceptors(jwtPremiumHandshakeInterceptor)
                .setAllowedOriginPatterns("*");
        registry.addHandler(bodyAnalysisWebSocketHandler, "/ws/ai/body-analysis")
                .addInterceptors(jwtPremiumHandshakeInterceptor)
                .setAllowedOriginPatterns("*");
        registry.addHandler(paymentWebSocketHandler, "/ws/payments")
                .addInterceptors(paymentHandshakeInterceptor)
                .setAllowedOriginPatterns("*");
    }

    @Bean
    public ServletServerContainerFactoryBean createWebSocketContainer() {
        ServletServerContainerFactoryBean container = new ServletServerContainerFactoryBean();
        container.setMaxTextMessageBufferSize(10 * 1024 * 1024); // 10MB
        container.setMaxBinaryMessageBufferSize(10 * 1024 * 1024); // 10MB
        return container;
    }
}
