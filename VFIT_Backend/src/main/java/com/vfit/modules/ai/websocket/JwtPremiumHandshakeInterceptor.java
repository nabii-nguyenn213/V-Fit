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
        String token = resolveToken(request);
        if (!StringUtils.hasText(token)) {
            response.setStatusCode(HttpStatus.UNAUTHORIZED);
            return false;
        }
        try {
            jwtTokenProvider.validate(token);
            UserDetails userDetails = userDetailsService.loadUserByUsername(jwtTokenProvider.getEmail(token));
            if (!(userDetails instanceof CustomUserDetails details)
                    || details.getOnboardingStatus() != OnboardingStatus.COMPLETED) {
                response.setStatusCode(HttpStatus.FORBIDDEN);
                return false;
            }
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(details, null, details.getAuthorities());
            if (!featureGate.isPremium(authentication)) {
                response.setStatusCode(HttpStatus.FORBIDDEN);
                return false;
            }
            String exerciseId = queryParam(request.getURI(), "exerciseId");
            if (!StringUtils.hasText(exerciseId)) {
                response.setStatusCode(HttpStatus.BAD_REQUEST);
                return false;
            }
            attributes.put("userId", jwtTokenProvider.getUserId(token));
            attributes.put("exerciseId", exerciseId);
            return true;
        } catch (RuntimeException ex) {
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
