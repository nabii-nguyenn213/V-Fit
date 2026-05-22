package com.vfit.infrastructure.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class RedisStartupVerifier implements ApplicationRunner {
    private final StringRedisTemplate redisTemplate;

    @Value("${app.redis.required:false}")
    private boolean redisRequired;

    @Override
    public void run(ApplicationArguments args) {
        try {
            redisTemplate.hasKey("vfit:startup:redis-probe");
            log.info("Redis connectivity check passed");
        } catch (RedisConnectionFailureException ex) {
            if (redisRequired) {
                throw new IllegalStateException("Redis is required for this environment but is unavailable", ex);
            }
            log.info("Redis is unavailable, continuing with Mongo-backed fallback for local development");
        }
    }
}
