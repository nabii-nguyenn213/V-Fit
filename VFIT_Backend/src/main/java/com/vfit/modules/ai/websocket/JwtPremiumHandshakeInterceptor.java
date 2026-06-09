package com.vfit.modules.ai.websocket;

import com.vfit.common.enums.OnboardingStatus;
import com.vfit.security.FeatureGate;
import com.vfit.security.jwt.JwtTokenProvider;
import com.vfit.security.model.CustomUserDetails;
import com.vfit.security.service.CustomUserDetailsService;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtPremiumHandshakeInterceptor implements HandshakeInterceptor {
    private final JwtTokenProvider jwtTokenProvider;
    private final CustomUserDetailsService userDetailsService;
    private final FeatureGate featureGate;

    @Override
    public boolean beforeHandshake(
            ServerHttpRequest request,
            ServerHttpResponse response,
            WebSocketHandler wsHandler,
            Map<String, Object> attributes) {
        log.info("WebSocket handshake initiated from URI: {}", request.getURI());
        String token = resolveToken(request);
        if (!StringUtils.hasText(token)) {
            log.warn("WebSocket handshake rejected: Token is empty or missing.");
            response.setStatusCode(HttpStatus.UNAUTHORIZED);
            return false;
        }
        try {
            jwtTokenProvider.validate(token);
            String email = jwtTokenProvider.getEmail(token);
            log.info("Token validated successfully for email: {}", email);
            
            UserDetails userDetails = userDetailsService.loadUserByUsername(email);
            if (!(userDetails instanceof CustomUserDetails details)
                    || details.getOnboardingStatus() != OnboardingStatus.COMPLETED) {
                log.warn("WebSocket handshake rejected: User details invalid or onboarding not completed (status: {}).",
                        (userDetails instanceof CustomUserDetails d) ? d.getOnboardingStatus() : "null");
                response.setStatusCode(HttpStatus.FORBIDDEN);
                return false;
            }
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(details, null, details.getAuthorities());
            if (!featureGate.isPremium(authentication)) {
                log.warn("WebSocket handshake rejected: User {} is not premium.", details.getId());
                response.setStatusCode(HttpStatus.FORBIDDEN);
                return false;
            }
            String path = request.getURI().getPath();
            String exerciseId = queryParam(request.getURI(), "exerciseId");
            if (path.endsWith("/form-check") && !StringUtils.hasText(exerciseId)) {
                log.warn("WebSocket handshake rejected: exerciseId is required for /form-check path.");
                response.setStatusCode(HttpStatus.BAD_REQUEST);
                return false;
            }
            String cameraView = queryParam(request.getURI(), "cameraView");
            attributes.put("userId", jwtTokenProvider.getUserId(token));
            attributes.put("exerciseId", StringUtils.hasText(exerciseId) ? exerciseId : "general");
            attributes.put("cameraView", StringUtils.hasText(cameraView) ? cameraView : "side");
            log.info("WebSocket handshake approved successfully for user: {}, exerciseId: {}, cameraView: {}",
                    jwtTokenProvider.getUserId(token), exerciseId, cameraView);
            return true;
        } catch (RuntimeException ex) {
            log.error("WebSocket handshake failed with exception: {}", ex.getMessage(), ex);
            response.setStatusCode(HttpStatus.UNAUTHORIZED);
            return false;
        }
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response, WebSocketHandler wsHandler, Exception exception) {
    }

    private String resolveToken(ServerHttpRequest request) {
        String header = request.getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (StringUtils.hasText(header) && header.startsWith("Bearer ")) {
            return header.substring("Bearer ".length());
        }
        URI uri = request.getURI();
        return queryParam(uri, "token");
    }

    private String queryParam(URI uri, String name) {
        String query = uri.getQuery();
        if (!StringUtils.hasText(query)) {
            return null;
        }
        for (String part : query.split("&")) {
            String[] pair = part.split("=", 2);
            if (pair.length == 2 && name.equals(pair[0])) {
                return URLDecoder.decode(pair[1], StandardCharsets.UTF_8);
            }
        }
        return null;
    }
}
