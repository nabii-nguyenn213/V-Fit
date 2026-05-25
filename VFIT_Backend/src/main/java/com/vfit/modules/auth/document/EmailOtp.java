package com.vfit.modules.auth.document;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "email_otps")
public class EmailOtp {
    @Id
    private String id;
    
    @Indexed(unique = true)
    private String email;
    
    private String otpHash;
    
    @Indexed(expireAfterSeconds = 0)
    private Instant expiresAt;
    
    private int attemptsLeft;
    
    private int resendCount;
    
    private Instant createdAt;

    public boolean isExpired() {
        return expiresAt != null && expiresAt.isBefore(Instant.now());
    }

    public boolean isAttemptLimitExceeded() {
        return attemptsLeft <= 0;
    }
}
