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
@Document(collection = "password_reset_tokens")
public class PasswordResetToken {
    @Id
    private String id;
    @Indexed(unique = true)
    private String token;
    @Indexed
    private String userId;
    private Instant expiresAt;
    private Instant usedAt;
    @CreatedDate
    private Instant createdAt;

    public boolean isUsable() {
        return usedAt == null && expiresAt != null && expiresAt.isAfter(Instant.now());
    }
}
