package com.vfit.infrastructure.config;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.ArrayList;
import java.util.List;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "app")
public class AppProperties {
    @NotBlank
    private String name;
    @NotBlank
    private String baseUrl;
    @Valid
    private Storage storage = new Storage();
    @Valid
    private Swagger swagger = new Swagger();
    @Valid
    private Bootstrap bootstrap = new Bootstrap();
    @Valid
    private Cors cors = new Cors();
    @Valid
    private Ai ai = new Ai();

    @Getter
    @Setter
    public static class Storage {
        @NotBlank
        private String uploadDir;
    }

    @Getter
    @Setter
    public static class Swagger {
        @NotBlank
        private String title;
        @NotBlank
        private String version;
        @NotBlank
        private String description;
    }

    @Getter
    @Setter
    public static class Cors {
        private List<String> allowedOrigins = new ArrayList<>(List.of("http://localhost:3000", "http://localhost:5173"));
    }

    @Getter
    @Setter
    public static class Bootstrap {
        private boolean adminEnabled = true;
        private boolean publicConfigEnabled = true;
        private boolean sampleDataEnabled = true;
        @Valid
        private Admin admin = new Admin();
        @Valid
        private PublicConfig publicConfig = new PublicConfig();

        @Getter
        @Setter
        public static class Admin {
            private String email = "";
            private String password = "";
            private String fullName = "";
        }

        @Getter
        @Setter
        public static class PublicConfig {
            @NotBlank
            private String appName;
            private String slogan;
            private String supportEmail;
            private String termsUrl;
            private String privacyUrl;
            private String latestVersion;
            private String minSupportedVersion;
        }
    }

    @Getter
    @Setter
    public static class Ai {
        private String clientMode = "mock";
        private String baseUrl = "http://localhost:8000";
        private String foodScannerPath = "/api/v1/food-scanner/";
    }
}
