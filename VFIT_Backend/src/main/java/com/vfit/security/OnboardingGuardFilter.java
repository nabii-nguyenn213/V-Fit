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
    protected boolean shouldNotFilter(HttpServletRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication == null
                || !(authentication.getPrincipal() instanceof CustomUserDetails);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails details = (CustomUserDetails) authentication.getPrincipal();
        if (details.getOnboardingStatus() == OnboardingStatus.PENDING
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

        // 1. Allow onboarding endpoints
        if (path.startsWith("/api/v1/users/onboarding")) {
            return true;
        }
        if (path.equals("/api/v1/users/onboarding-metrics") && "PUT".equalsIgnoreCase(method)) {
            return true;
        }

        // 2. Allow fetching current user profile info
        if (path.equals("/api/users/me") && "GET".equalsIgnoreCase(method)) {
            return true;
        }

        // 3. Allow session endpoints to sign out / cancel onboarding
        if (path.startsWith("/api/users/sessions")) {
            return true;
        }

        // 4. Allow public/auth endpoints
        if (path.startsWith("/api/auth/") || path.startsWith("/api/v1/auth/")) {
            return true;
        }

        return false;
    }
}
