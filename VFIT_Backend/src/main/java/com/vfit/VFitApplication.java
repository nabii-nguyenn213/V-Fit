package com.vfit;

import com.vfit.infrastructure.config.AppProperties;
import com.vfit.security.jwt.JwtProperties;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.data.mongodb.config.EnableMongoAuditing;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableAsync
@EnableCaching
@EnableMongoAuditing
@EnableScheduling
@SpringBootApplication
@EnableConfigurationProperties({AppProperties.class, JwtProperties.class})
public class VFitApplication {

    public static void main(String[] args) {
        SpringApplication.run(VFitApplication.class, args);
    }
}
