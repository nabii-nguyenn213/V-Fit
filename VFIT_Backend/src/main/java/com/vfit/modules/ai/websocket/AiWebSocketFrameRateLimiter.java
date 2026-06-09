package com.vfit.modules.ai.websocket;

import java.time.Duration;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class AiWebSocketFrameRateLimiter {
    private final StringRedisTemplate redisTemplate;

    @Value("${app.rate-limit.ai-ws.max-frames:${app.rate-limit.ai.max-requests:60}}")
    private long maxFrames;

    @Value("${app.rate-limit.ai-ws.window-seconds:${app.rate-limit.ai.window-seconds:60}}")
    private long windowSeconds;

    @Value("${app.rate-limit.ai.fail-open:true}")
    private boolean failOpenWhenRedisUnavailable;

    public boolean allow(String userId) {
        String key = "rate-limit:ai-ws-frame:user:" + userId;
        try {
            Long count = redisTemplate.opsForValue().increment(key);
            if (count != null && count == 1L) {
                redisTemplate.expire(key, Duration.ofSeconds(windowSeconds));
            }
            return count == null || count <= maxFrames;
        } catch (RedisConnectionFailureException ex) {
            if (failOpenWhenRedisUnavailable) {
                log.warn("Redis unavailable for AI WebSocket frame rate limiting, allowing frame: {}", ex.getMessage());
                return true;
            }
            log.error("Redis unavailable for AI WebSocket frame rate limiting, blocking frame: {}", ex.getMessage());
            return false;
        }
    }
}
