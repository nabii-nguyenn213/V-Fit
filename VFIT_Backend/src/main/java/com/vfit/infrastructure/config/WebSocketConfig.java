package com.vfit.infrastructure.config;

import com.vfit.modules.ai.websocket.FormCheckWebSocketHandler;
import com.vfit.modules.ai.websocket.BodyAnalysisWebSocketHandler;
import com.vfit.modules.ai.websocket.JwtPremiumHandshakeInterceptor;
import com.vfit.modules.payment.websocket.PaymentHandshakeInterceptor;
import com.vfit.modules.payment.websocket.PaymentWebSocketHandler;
import jakarta.servlet.ServletContext;
import jakarta.websocket.server.ServerContainer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.boot.web.servlet.ServletContextInitializer;
import org.springframework.util.unit.DataSize;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.standard.ServletServerContainerFactoryBean;

@Slf4j
@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {
    private final FormCheckWebSocketHandler formCheckWebSocketHandler;
    private final BodyAnalysisWebSocketHandler bodyAnalysisWebSocketHandler;
    private final JwtPremiumHandshakeInterceptor jwtPremiumHandshakeInterceptor;
    private final PaymentWebSocketHandler paymentWebSocketHandler;
    private final PaymentHandshakeInterceptor paymentHandshakeInterceptor;
    private final AppProperties appProperties;

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
        AppProperties.WebSocket websocket = appProperties.getWebsocket();
        ServletServerContainerFactoryBean container = new ServletServerContainerFactoryBean();
        container.setMaxTextMessageBufferSize(toIntBytes(websocket.getMaxTextMessageBufferSize()));
        container.setMaxBinaryMessageBufferSize(toIntBytes(websocket.getMaxBinaryMessageBufferSize()));
        container.setAsyncSendTimeout(websocket.getAsyncSendTimeoutMs());
        container.setMaxSessionIdleTimeout(websocket.getMaxSessionIdleTimeoutMs());
        return container;
    }

    @Bean
    public ServletContextInitializer webSocketContainerInitializer() {
        return this::configureNativeWebSocketContainer;
    }

    private void configureNativeWebSocketContainer(ServletContext servletContext) {
        Object container = servletContext.getAttribute("jakarta.websocket.server.ServerContainer");
        if (!(container instanceof ServerContainer serverContainer)) {
            log.debug("Jakarta WebSocket ServerContainer not available; session-level limits will still be applied.");
            return;
        }

        AppProperties.WebSocket websocket = appProperties.getWebsocket();
        serverContainer.setDefaultMaxTextMessageBufferSize(toIntBytes(websocket.getMaxTextMessageBufferSize()));
        serverContainer.setDefaultMaxBinaryMessageBufferSize(toIntBytes(websocket.getMaxBinaryMessageBufferSize()));
        serverContainer.setAsyncSendTimeout(websocket.getAsyncSendTimeoutMs());
        serverContainer.setDefaultMaxSessionIdleTimeout(websocket.getMaxSessionIdleTimeoutMs());
    }

    private int toIntBytes(DataSize dataSize) {
        return Math.toIntExact(dataSize.toBytes());
    }
}
