package com.vfit.modules.auth.document;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "user_sessions")
public class UserSession {
    @Id
    private String id;
    
    @Indexed
    private String userId;
    
    @Indexed(unique = true)
    private String refreshTokenHash;
    
    private String deviceId;
    
    private String userAgent;
    
    private String ipAddress;
    
    private Instant expiresAt;
    
    @Builder.Default
    private boolean isRevoked = false;
    
    private Instant revokedAt;
    
    private String revokedReason;
    
    @CreatedDate
    private Instant createdAt;

    public boolean isActive() {
        return !isRevoked && expiresAt != null && expiresAt.isAfter(Instant.now());
    }
}
