package com.vfit.infrastructure.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {
    private final AppProperties appProperties;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins(appProperties.getCors().getAllowedOrigins().toArray(String[]::new))
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(false)
                .maxAge(3600);
    }

    @Override
    public void addResourceHandlers(org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry registry) {
        String uploadPath = java.nio.file.Path.of(appProperties.getStorage().getUploadDir()).toAbsolutePath().normalize().toString();
        // Ensure trailing slash
        if (!uploadPath.endsWith("/") && !uploadPath.endsWith("\\")) {
            uploadPath += "/";
        }
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + uploadPath);

        // Resolve web path dynamically to support both local machine and VPS
        String webDir = System.getenv("WEB_DIR");
        if (webDir == null || webDir.isBlank()) {
            webDir = System.getProperty("app.web-dir", "web");
        }
        String webPath = java.nio.file.Path.of(webDir).toAbsolutePath().normalize().toString();
        if (!webPath.endsWith("/") && !webPath.endsWith("\\")) {
            webPath += "/";
        }

        registry.addResourceHandler("/**")
                .addResourceLocations("file:" + webPath)
                .resourceChain(true);
    }

    @Override
    public void addViewControllers(org.springframework.web.servlet.config.annotation.ViewControllerRegistry registry) {
        registry.addViewController("/").setViewName("forward:/index.html");
        registry.addViewController("/favicon.ico").setViewName("forward:/favicon.png");
    }
}
