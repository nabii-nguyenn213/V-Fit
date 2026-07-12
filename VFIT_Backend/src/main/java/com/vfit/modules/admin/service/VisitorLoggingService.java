package com.vfit.modules.admin.service;

import com.vfit.modules.admin.document.VisitorLog;
import com.vfit.modules.admin.repository.VisitorLogRepository;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.regex.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

@Service
@RequiredArgsConstructor
public class VisitorLoggingService {

    private final VisitorLogRepository visitorLogRepository;
    private final StringRedisTemplate redisTemplate;

    private static final Pattern BOT_PATTERN = Pattern.compile(
        "(bot|crawl|spider|slurp|lighthouse|ping|monitor|headless)",
        Pattern.CASE_INSENSITIVE
    );

    @Async("visitorLogExecutor")
    public void logVisit(String ip, String userAgent) {
        if (userAgent == null || BOT_PATTERN.matcher(userAgent).find()) {
            return; // Bỏ qua bot
        }

        // 1. Rate Limit IP: Tối đa 20 request/phút từ mỗi IP
        String rateLimitKey = "ratelimit:visit:" + ip;
        Long count = redisTemplate.opsForValue().increment(rateLimitKey);
        if (count != null && count == 1L) {
            redisTemplate.expire(rateLimitKey, Duration.ofMinutes(1));
        }
        if (count != null && count > 20) {
            return; // Quá tần suất, bỏ qua
        }

        // 2. Deduplicate 60s dựa trên IP + UA MD5
        String rawString = ip + "|" + userAgent;
        String dedupKey = "visit:" + DigestUtils.md5DigestAsHex(rawString.getBytes(StandardCharsets.UTF_8));
        Boolean isNewVisit = redisTemplate.opsForValue()
            .setIfAbsent(dedupKey, "1", Duration.ofSeconds(60));

        if (!Boolean.TRUE.equals(isNewVisit)) {
            return;
        }

        VisitorLog log = new VisitorLog();
        log.setIp(ip);
        log.setOs(parseOS(userAgent));
        log.setBrowser(parseBrowser(userAgent));
        log.setAction("Xem trang chủ");
        log.setCreatedAt(Instant.now());
        visitorLogRepository.save(log);
    }

    private String parseOS(String ua) {
        if (ua == null) return "Unknown OS";
        String lowerUa = ua.toLowerCase();
        if (lowerUa.contains("iphone") || lowerUa.contains("ipad") || lowerUa.contains("ipod")) return "iOS";
        if (lowerUa.contains("android")) return "Android";
        if (lowerUa.contains("windows")) return "Windows";
        if (lowerUa.contains("macintosh") || lowerUa.contains("mac os")) return "macOS";
        if (lowerUa.contains("linux")) return "Linux";
        return "Unknown OS";
    }

    private String parseBrowser(String ua) {
        if (ua == null) return "Unknown Browser";
        String lowerUa = ua.toLowerCase();
        if (lowerUa.contains("edge") || lowerUa.contains("edg")) return "Edge";
        if (lowerUa.contains("chrome") && lowerUa.contains("safari") && !lowerUa.contains("edge") && !lowerUa.contains("edg")) {
            if (lowerUa.contains("mobile")) {
                return "Chrome (Mobile)";
            }
            return "Chrome (Desktop)";
        }
        if (lowerUa.contains("safari") && !lowerUa.contains("chrome")) {
            if (lowerUa.contains("mobile")) {
                return "Safari (Mobile)";
            }
            return "Safari (Desktop)";
        }
        if (lowerUa.contains("firefox")) return "Firefox";
        if (lowerUa.contains("opera") || lowerUa.contains("opr")) return "Opera";
        return "Unknown Browser";
    }
}
