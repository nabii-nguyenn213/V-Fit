package com.vfit.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.api.ErrorResponse;
import com.vfit.common.exception.ErrorCode;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Slf4j
@Component
@RequiredArgsConstructor
public class OtpRateLimitFilter extends OncePerRequestFilter {
    private final ObjectMapper objectMapper;
    private final Map<String, IpRequestTracker> ipTrackers = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String path = request.getRequestURI();

        // Target /api/v1/auth/verify-otp and /api/auth/verify-otp
        if (path.endsWith("/api/v1/auth/verify-otp") || path.endsWith("/api/auth/verify-otp")) {
            String ip = getClientIp(request);
            IpRequestTracker tracker = ipTrackers.computeIfAbsent(ip, k -> new IpRequestTracker());

            if (!tracker.allowRequest()) {
                log.warn("[SECURITY AUDIT] OTP verification rate limit exceeded for IP: {}", ip);
                response.setStatus(ErrorCode.RATE_LIMITED.getStatus().value());
                response.setContentType(MediaType.APPLICATION_JSON_VALUE);

                ErrorResponse error = ErrorResponse.builder()
                        .code(ErrorCode.RATE_LIMITED.getCode())
                        .message("Bạn đã gửi quá nhiều yêu cầu xác thực. Giới hạn là 5 lần/phút. Vui lòng thử lại sau.")
                        .path(path)
                        .details(List.of())
                        .timestamp(Instant.now())
                        .build();

                objectMapper.writeValue(response.getOutputStream(), error);
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private String getClientIp(HttpServletRequest request) {
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader == null || xfHeader.isBlank()) {
            return request.getRemoteAddr();
        }
        return xfHeader.split(",")[0].trim();
    }

    private static class IpRequestTracker {
        private final AtomicInteger requestCount = new AtomicInteger(0);
        private volatile long windowStart = System.currentTimeMillis();

        public synchronized boolean allowRequest() {
            long now = System.currentTimeMillis();
            if (now - windowStart > 60000) {
                requestCount.set(0);
                windowStart = now;
            }
            int count = requestCount.incrementAndGet();
            return count <= 5;
        }
    }
}
