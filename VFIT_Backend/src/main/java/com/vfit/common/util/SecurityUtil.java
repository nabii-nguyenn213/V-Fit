package com.vfit.common.util;

import com.vfit.security.model.CustomUserDetails;
import java.util.Optional;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public final class SecurityUtil {
    private SecurityUtil() {
    }

    public static Optional<String> currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof CustomUserDetails details)) {
            return Optional.empty();
        }
        return Optional.of(details.getId());
    }

    public static String requireCurrentUserId() {
        return currentUserId().orElseThrow(() -> new IllegalStateException("No authenticated user in security context"));
    }
}
