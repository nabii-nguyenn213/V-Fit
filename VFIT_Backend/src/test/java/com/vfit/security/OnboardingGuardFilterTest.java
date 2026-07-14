package com.vfit.security;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.enums.RoleName;
import com.vfit.modules.user.document.User;
import com.vfit.security.model.CustomUserDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

class OnboardingGuardFilterTest {
    private final OnboardingGuardFilter filter = new OnboardingGuardFilter(new ObjectMapper());

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void allowsPendingUserToSetupPasswordBeforeOnboarding() throws Exception {
        authenticatePendingUser();
        MockHttpServletRequest request = new MockHttpServletRequest("PUT", "/api/users/password/setup");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertThat(chain.getRequest()).isSameAs(request);
        assertThat(response.getStatus()).isEqualTo(200);
    }

    @Test
    void blocksPendingUserFromUpdatingProfileBeforeOnboarding() throws Exception {
        authenticatePendingUser();
        MockHttpServletRequest request = new MockHttpServletRequest("PUT", "/api/users/me");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertThat(chain.getRequest()).isNull();
        assertThat(response.getStatus()).isEqualTo(403);
        assertThat(response.getContentAsString())
                .contains("Onboarding must be completed before using this feature");
    }

    private void authenticatePendingUser() {
        User user = User.builder()
                .id("user-1")
                .email("social.user@vfit.local")
                .passwordHash(User.SOCIAL_PASSWORD_SETUP_REQUIRED)
                .role(RoleName.USER)
                .active(true)
                .onboardingStatus(OnboardingStatus.PENDING)
                .build();
        CustomUserDetails details = new CustomUserDetails(user);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(details, null, details.getAuthorities()));
    }
}
