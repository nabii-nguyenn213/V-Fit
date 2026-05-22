package com.vfit.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.api.ErrorResponse;
import com.vfit.common.exception.ErrorCode;
import com.vfit.security.model.CustomUserDetails;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Slf4j
@Component
@RequiredArgsConstructor
public class AiRateLimitFilter extends OncePerRequestFilter {
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    @Value("${app.rate-limit.ai.max-requests:60}")
    private long maxRequests;

    @Value("${app.rate-limit.ai.window-seconds:60}")
    private long windowSeconds;

    @Value("${app.rate-limit.ai.fail-open:true}")
    private boolean failOpenWhenRedisUnavailable;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if (!isAiEndpoint(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        RateLimitDecision decision = checkLimit(request);
        if (decision.allowed()) {
            filterChain.doFilter(request, response);
            return;
        }

        response.setStatus(decision.errorCode().getStatus().value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        ErrorResponse error = ErrorResponse.builder()
                .code(decision.errorCode().getCode())
                .message(decision.message())
                .path(request.getRequestURI())
                .details(List.of())
                .timestamp(Instant.now())
                .build();
        objectMapper.writeValue(response.getOutputStream(), error);
    }

    private boolean isAiEndpoint(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.startsWith("/api/ai/") || path.startsWith("/ws/ai/");
    }

    private RateLimitDecision checkLimit(HttpServletRequest request) {
        String key = "rate-limit:ai:" + clientKey(request);
        try {
            Long count = redisTemplate.opsForValue().increment(key);
            if (count != null && count == 1L) {
                redisTemplate.expire(key, Duration.ofSeconds(windowSeconds));
            }
            boolean allowed = count == null || count <= maxRequests;
            if (allowed) {
                return RateLimitDecision.allow();
            }
            return RateLimitDecision.deny(
                    ErrorCode.RATE_LIMITED,
                    "Too many AI requests. Please try again later.");
        } catch (RedisConnectionFailureException ex) {
            if (failOpenWhenRedisUnavailable) {
                log.warn("Redis unavailable for AI rate limiting, allowing request: {}", ex.getMessage());
                return RateLimitDecision.allow();
            }
            log.error("Redis unavailable for AI rate limiting, blocking request: {}", ex.getMessage());
            return RateLimitDecision.deny(
                    ErrorCode.SERVICE_UNAVAILABLE,
                    "AI protection service is temporarily unavailable. Please try again later.");
        }
    }

    private String clientKey(HttpServletRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof CustomUserDetails details) {
            return "user:" + details.getId();
        }
        String token = request.getParameter("token");
        if (token != null && !token.isBlank()) {
            return "token:" + Integer.toHexString(token.hashCode());
        }
        return "ip:" + request.getRemoteAddr();
    }

    private record RateLimitDecision(boolean allowed, ErrorCode errorCode, String message) {
        private static RateLimitDecision allow() {
            return new RateLimitDecision(true, null, null);
        }

        private static RateLimitDecision deny(ErrorCode errorCode, String message) {
            return new RateLimitDecision(false, errorCode, message);
        }
    }
}
