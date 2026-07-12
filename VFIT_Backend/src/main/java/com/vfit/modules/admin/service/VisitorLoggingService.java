package com.vfit.modules.admin.service;

import com.vfit.modules.admin.document.VisitorLog;
import com.vfit.modules.admin.repository.VisitorLogRepository;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
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

    private static final Map<String, String> PROVINCE_MAP = Map.ofEntries(
        Map.entry("hanoi", "Hà Nội"),
        Map.entry("ho chi minh", "Hồ Chí Minh"),
        Map.entry("saigon", "Hồ Chí Minh"),
        Map.entry("da nang", "Đà Nẵng"),
        Map.entry("hai phong", "Hải Phòng"),
        Map.entry("can tho", "Cần Thơ"),
        Map.entry("nam dinh", "Nam Định"),
        Map.entry("ninh binh", "Ninh Bình"),
        Map.entry("thanh hoa", "Thanh Hóa"),
        Map.entry("nghe an", "Nghệ An"),
        Map.entry("ha tinh", "Hà Tĩnh"),
        Map.entry("quang binh", "Quảng Bình"),
        Map.entry("quang tri", "Quảng Trị"),
        Map.entry("thua thien hue", "Thừa Thiên Huế"),
        Map.entry("hue", "Huế"),
        Map.entry("quang nam", "Quảng Nam"),
        Map.entry("quang ngai", "Quảng Ngãi"),
        Map.entry("binh dinh", "Bình Định"),
        Map.entry("phu yen", "Phú Yên"),
        Map.entry("khanh hoa", "Khánh Hòa"),
        Map.entry("nha trang", "Nha Trang"),
        Map.entry("ninh thuan", "Ninh Thuận"),
        Map.entry("binh thuan", "Bình Thuận"),
        Map.entry("kon tum", "Kon Tum"),
        Map.entry("gia lai", "Gia Lai"),
        Map.entry("dak lak", "Đắk Lắk"),
        Map.entry("dak nong", "Đắk Nông"),
        Map.entry("lam dong", "Lâm Đồng"),
        Map.entry("da lat", "Đà Lạt"),
        Map.entry("binh phuoc", "Bình Phước"),
        Map.entry("tay ninh", "Tây Ninh"),
        Map.entry("binh duong", "Bình Dương"),
        Map.entry("dong nai", "Đồng Nai"),
        Map.entry("ba ria-vung tau", "Bà Rịa - Vũng Tàu"),
        Map.entry("vung tau", "Vũng Tàu"),
        Map.entry("long an", "Long An"),
        Map.entry("tien giang", "Tiền Giang"),
        Map.entry("ben tre", "Bến Tre"),
        Map.entry("tra vinh", "Trà Vinh"),
        Map.entry("vinh long", "Vĩnh Long"),
        Map.entry("dong thap", "Đồng Tháp"),
        Map.entry("an giang", "An Giang"),
        Map.entry("kien giang", "Kiên Giang"),
        Map.entry("rach gia", "Rạch Giá"),
        Map.entry("phu quoc", "Phú Quốc"),
        Map.entry("hau giang", "Hậu Giang"),
        Map.entry("soc trang", "Sóc Trăng"),
        Map.entry("bac lieu", "Bạc Liêu"),
        Map.entry("ca mau", "Cà Mau"),
        Map.entry("tuyen quang", "Tuyên Quang"),
        Map.entry("ha giang", "Hà Giang"),
        Map.entry("cao bang", "Cao Bằng"),
        Map.entry("bac kan", "Bắc Kạn"),
        Map.entry("lang son", "Lạng Sơn"),
        Map.entry("thai nguyen", "Thái Nguyên"),
        Map.entry("bac giang", "Bắc Giang"),
        Map.entry("phu tho", "Phú Thọ"),
        Map.entry("vinh phuc", "Vĩnh Phúc"),
        Map.entry("bac ninh", "Bắc Ninh"),
        Map.entry("hung yen", "Hưng Yên"),
        Map.entry("hai duong", "Hải Dương"),
        Map.entry("quang ninh", "Quảng Ninh"),
        Map.entry("ha long", "Hạ Long"),
        Map.entry("hoa binh", "Hòa Bình"),
        Map.entry("son la", "Sơn La"),
        Map.entry("dien bien", "Điện Biên"),
        Map.entry("lai chau", "Lai Châu"),
        Map.entry("yen bai", "Yên Bái"),
        Map.entry("lao cai", "Lào Cai"),
        Map.entry("sapa", "Sa Pa")
    );

    @Async("visitorLogExecutor")
    public void logVisit(String ip, String userAgent) {
        if (userAgent == null || BOT_PATTERN.matcher(userAgent).find()) {
            return;
        }

        String rateLimitKey = "ratelimit:visit:" + ip;
        Long count = redisTemplate.opsForValue().increment(rateLimitKey);
        if (count != null && count == 1L) {
            redisTemplate.expire(rateLimitKey, Duration.ofMinutes(1));
        }
        if (count != null && count > 20) {
            return;
        }

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
        log.setLocation(resolveLocation(ip));
        log.setCreatedAt(Instant.now());
        visitorLogRepository.save(log);
    }

    private String resolveLocation(String ip) {
        if (ip == null || ip.isBlank() || ip.equals("127.0.0.1") || ip.startsWith("192.168.") || ip.startsWith("10.") || ip.startsWith("172.16.") || ip.startsWith("0:")) {
            return "Mạng nội bộ";
        }
        try {
            java.net.http.HttpClient client = java.net.http.HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(2))
                .build();
            java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
                .uri(java.net.URI.create("http://ip-api.com/json/" + ip + "?fields=status,regionName"))
                .timeout(Duration.ofSeconds(3))
                .GET()
                .build();
            java.net.http.HttpResponse<String> response = client.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                String body = response.body();
                if (body.contains("\"fail\"")) {
                    return "Không rõ vị trí";
                }
                
                String regionName = extractJsonField(body, "regionName");
                String translatedRegion = translateName(regionName);
                
                if (translatedRegion != null && !translatedRegion.isBlank()) {
                    return translatedRegion;
                }
            }
        } catch (Exception e) {
            // fallback
        }
        return "Không rõ vị trí";
    }

    private String translateName(String name) {
        if (name == null || name.isBlank()) return null;
        String clean = name.toLowerCase(Locale.ROOT)
            .replace("province", "")
            .replace("city", "")
            .replace("tỉnh", "")
            .replace("thành phố", "")
            .replace("tp.", "")
            .trim();
        return PROVINCE_MAP.getOrDefault(clean, name);
    }

    private String extractJsonField(String json, String field) {
        int idx = json.indexOf("\"" + field + "\":\"");
        if (idx == -1) return null;
        int start = idx + field.length() + 4;
        int end = json.indexOf("\"", start);
        if (end == -1) return null;
        return json.substring(start, end);
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
