package com.vfit.security.jwt;

import static org.assertj.core.api.Assertions.assertThat;

import com.vfit.common.enums.RoleName;
import com.vfit.modules.user.document.User;
import com.vfit.security.model.CustomUserDetails;
import org.junit.jupiter.api.Test;

class JwtTokenProviderTest {

    @Test
    void createAccessTokenContainsUserIdentityClaims() {
        JwtProperties properties = new JwtProperties();
        properties.setSecret("1234567890123456789012345678901212345678901234567890123456789012");
        properties.setAccessTokenExpirationMs(900000);
        properties.setRefreshTokenExpirationMs(604800000);
        JwtTokenProvider provider = new JwtTokenProvider(properties);
        User user = User.builder()
                .id("user-1")
                .email("member@vfit.com")
                .passwordHash("hash")
                .role(RoleName.USER)
                .active(true)
                .build();

        String token = provider.createAccessToken(new CustomUserDetails(user));

        assertThat(provider.validate(token)).isTrue();
        assertThat(provider.getUserId(token)).isEqualTo("user-1");
        assertThat(provider.getEmail(token)).isEqualTo("member@vfit.com");
        assertThat(provider.getRole(token)).isEqualTo(RoleName.USER);
    }
}
