package com.vfit.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.api.ErrorResponse;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.exception.ErrorCode;
import com.vfit.security.model.CustomUserDetails;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Instant;
import java.util.List;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class OnboardingGuardFilter extends OncePerRequestFilter {
    private final ObjectMapper objectMapper;

    public OnboardingGuardFilter(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null
                && authentication.getPrincipal() instanceof CustomUserDetails details
                && details.getOnboardingStatus() == OnboardingStatus.PENDING
                && !isAllowedForPending(request)) {
            response.setStatus(ErrorCode.FORBIDDEN.getStatus().value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            ErrorResponse error = ErrorResponse.builder()
                    .code(ErrorCode.FORBIDDEN.getCode())
                    .message("Onboarding must be completed before using this feature")
                    .path(request.getRequestURI())
                    .details(List.of())
                    .timestamp(Instant.now())
                    .build();
            objectMapper.writeValue(response.getOutputStream(), error);
            return;
        }
        filterChain.doFilter(request, response);
    }

    private boolean isAllowedForPending(HttpServletRequest request) {
        String path = request.getRequestURI();
        String method = request.getMethod();
        return path.startsWith("/api/auth/")
                || path.startsWith("/api/v1/users/onboarding")
                || ("GET".equalsIgnoreCase(method) && path.equals("/api/users/me"))
                || path.equals("/api/app/config")
                || path.startsWith("/uploads/")
                || ("GET".equalsIgnoreCase(method)
                    && (path.startsWith("/api/exercises/")
                        || path.equals("/api/exercises")
                        || path.startsWith("/api/v1/exercises/")
                        || path.startsWith("/api/workouts/")
                        || path.equals("/api/workouts")));
    }
}
