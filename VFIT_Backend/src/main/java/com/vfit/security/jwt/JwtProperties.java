package com.vfit.security.jwt;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "jwt")
public class JwtProperties {
    @NotBlank
    private String secret;

    @Positive
    private long accessTokenExpirationMs = 900000; // default 15 mins

    @Positive
    private long refreshTokenExpirationMs = 604800000; // default 7 days

    public void setAccessTokenExpirationMs(long accessTokenExpirationMs) {
        if (accessTokenExpirationMs <= 0) {
            this.accessTokenExpirationMs = 900000;
        } else {
            this.accessTokenExpirationMs = accessTokenExpirationMs;
        }
    }

    public void setRefreshTokenExpirationMs(long refreshTokenExpirationMs) {
        if (refreshTokenExpirationMs <= 0) {
            this.refreshTokenExpirationMs = 604800000;
        } else {
            this.refreshTokenExpirationMs = refreshTokenExpirationMs;
        }
    }
}
