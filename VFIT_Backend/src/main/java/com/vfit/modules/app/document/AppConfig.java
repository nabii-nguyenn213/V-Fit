package com.vfit.modules.app.document;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "app_configs")
public class AppConfig {
    @Id
    private String id;
    @Indexed(unique = true)
    private String configKey;
    private String appName;
    private String slogan;
    private String supportEmail;
    private String termsUrl;
    private String privacyUrl;
    private String latestVersion;
    private String minSupportedVersion;
    @Builder.Default
    private boolean maintenanceMode = false;
    private String maintenanceMessage;
    @CreatedDate
    private Instant createdAt;
    @LastModifiedDate
    private Instant updatedAt;
}
