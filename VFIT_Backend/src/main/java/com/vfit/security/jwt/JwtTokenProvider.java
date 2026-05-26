package com.vfit.security.jwt;

import com.vfit.common.enums.RoleName;
import com.vfit.security.model.CustomUserDetails;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Component;

@Component
public class JwtTokenProvider {
    private static final Logger log = LoggerFactory.getLogger(JwtTokenProvider.class);
    private final JwtProperties properties;
    private final SecretKey key;

    public JwtTokenProvider(JwtProperties properties) {
        this.properties = properties;
        this.key = Keys.hmacShaKeyFor(properties.getSecret().getBytes(StandardCharsets.UTF_8));
    }

    public String createAccessToken(CustomUserDetails userDetails) {
        return createAccessToken(userDetails, null);
    }

    public String createAccessToken(CustomUserDetails userDetails, String sessionId) {
        Instant now = Instant.now();
        var builder = Jwts.builder()
                .subject(userDetails.getId())
                .claim("email", userDetails.getEmail())
                .claim("role", userDetails.getRole().name());
        if (sessionId != null) {
            builder.claim("sid", sessionId);
        }
        return builder
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusMillis(properties.getAccessTokenExpirationMs())))
                .signWith(key)
                .compact();
    }

    public boolean validate(String token) {
        parseClaims(token);
        return true;
    }

    /**
     * Parse and validate token in a single pass. Returns the Claims object
     * to avoid redundant HMAC verifications when multiple claims are needed.
     */
    public Claims parseAndValidate(String token) {
        return parseClaims(token);
    }

    public String getUserId(String token) {
        return parseClaims(token).getSubject();
    }

    public String getEmail(String token) {
        return parseClaims(token).get("email", String.class);
    }

    public RoleName getRole(String token) {
        return RoleName.valueOf(parseClaims(token).get("role", String.class));
    }

    public String getSessionId(String token) {
        return parseClaims(token).get("sid", String.class);
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
