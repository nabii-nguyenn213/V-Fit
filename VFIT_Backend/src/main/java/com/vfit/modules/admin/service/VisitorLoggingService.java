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

    private static final Map<String, String[]> DISTRICT_MAP = Map.ofEntries(
        Map.entry("Hà Nội", new String[]{
            "Thạch Thất (Hòa Lạc), Hà Nội",
            "Quận Cầu Giấy, Hà Nội",
            "Quận Thanh Xuân, Hà Nội",
            "Quận Nam Từ Liêm, Hà Nội",
            "Quận Đống Đa, Hà Nội",
            "Quận Ba Đình, Hà Nội",
            "Quận Tây Hồ, Hà Nội",
            "Huyện Đông Anh, Hà Nội",
            "Thị xã Sơn Tây, Hà Nội",
            "Huyện Gia Lâm, Hà Nội"
        }),
        Map.entry("Hồ Chí Minh", new String[]{
            "Quận 1, Hồ Chí Minh",
            "Quận 3, Hồ Chí Minh",
            "Quận Bình Thạnh, Hồ Chí Minh",
            "Thành phố Thủ Đức, Hồ Chí Minh",
            "Huyện Củ Chi, Hồ Chí Minh",
            "Quận Tân Bình, Hồ Chí Minh",
            "Quận Gò Vấp, Hồ Chí Minh",
            "Huyện Hóc Môn, Hồ Chí Minh"
        }),
        Map.entry("Đà Nẵng", new String[]{
            "Quận Hải Châu, Đà Nẵng",
            "Quận Ngũ Hành Sơn, Đà Nẵng",
            "Quận Liên Chiểu, Đà Nẵng",
            "Quận Sơn Trà, Đà Nẵng",
            "Quận Cẩm Lệ, Đà Nẵng"
        }),
        Map.entry("Ninh Bình", new String[]{
            "Huyện Gia Viễn, Ninh Bình",
            "TP. Ninh Bình, Ninh Bình",
            "Khu du lịch Tràng An, Ninh Bình",
            "Huyện Nho Quan, Ninh Bình",
            "Huyện Kim Sơn, Ninh Bình",
            "TP. Tam Điệp, Ninh Bình"
        }),
        Map.entry("Nam Định", new String[]{
            "TP. Nam Định, Nam Định",
            "Huyện Mỹ Lộc, Nam Định",
            "Huyện Giao Thủy, Nam Định",
            "Huyện Hải Hậu, Nam Định",
            "Huyện Ý Yên, Nam Định",
            "Huyện Vụ Bản, Nam Định"
        }),
        Map.entry("Thanh Hóa", new String[]{
            "TP. Thanh Hóa, Thanh Hóa",
            "Thị xã Sầm Sơn, Thanh Hóa",
            "Thị xã Bỉm Sơn, Thanh Hóa",
            "Huyện Tĩnh Gia, Thanh Hóa",
            "Huyện Thọ Xuân, Thanh Hóa"
        }),
        Map.entry("Quảng Ninh", new String[]{
            "TP. Hạ Long, Quảng Ninh",
            "TP. Móng Cái, Quảng Ninh",
            "TP. Cẩm Phả, Quảng Ninh",
            "TP. Uông Bí, Quảng Ninh",
            "Huyện Vân Đồn, Quảng Ninh"
        }),
        Map.entry("Khánh Hòa", new String[]{
            "TP. Nha Trang, Khánh Hòa",
            "TP. Cam Ranh, Khánh Hòa",
            "Huyện Diên Khánh, Khánh Hòa",
            "Huyện Vạn Ninh, Khánh Hòa"
        }),
        Map.entry("Lâm Đồng", new String[]{
            "TP. Đà Lạt, Lâm Đồng",
            "TP. Bảo Lộc, Lâm Đồng",
            "Huyện Đức Trọng, Lâm Đồng",
            "Huyện Lạc Dương, Lâm Đồng"
        }),
        Map.entry("Đồng Nai", new String[]{
            "TP. Biên Hòa, Đồng Nai",
            "TP. Long Khánh, Đồng Nai",
            "Huyện Nhơn Trạch, Đồng Nai",
            "Huyện Trảng Bom, Đồng Nai"
        }),
        Map.entry("Bình Dương", new String[]{
            "TP. Thủ Dầu Một, Bình Dương",
            "TP. Dĩ An, Bình Dương",
            "TP. Thuận An, Bình Dương",
            "Huyện Bến Cát, Bình Dương"
        }),
        Map.entry("Bà Rịa - Vũng Tàu", new String[]{
            "TP. Vũng Tàu, Bà Rịa - Vũng Tàu",
            "TP. Bà Rịa, Bà Rịa - Vũng Tàu",
            "Thị xã Phú Mỹ, Bà Rịa - Vũng Tàu",
            "Huyện Côn Đảo, Bà Rịa - Vũng Tàu"
        }),
        Map.entry("Cần Thơ", new String[]{
            "Quận Ninh Kiều, Cần Thơ",
            "Quận Cái Răng, Cần Thơ",
            "Quận Bình Thủy, Cần Thơ",
            "Quận Ô Môn, Cần Thơ"
        }),
        Map.entry("Kiên Giang", new String[]{
            "TP. Rạch Giá, Kiên Giang",
            "TP. Phú Quốc, Kiên Giang",
            "TP. Hà Tiên, Kiên Giang"
        })
    );

    private static final String[] FALLBACK_LOCATIONS = {
        "Thạch Thất (Hòa Lạc), Hà Nội",
        "Quận Cầu Giấy, Hà Nội",
        "Quận Thanh Xuân, Hà Nội",
        "Quận 1, Hồ Chí Minh",
        "Quận Bình Thạnh, Hồ Chí Minh",
        "Thành phố Thủ Đức, Hồ Chí Minh",
        "Quận Hải Châu, Đà Nẵng",
        "Quận Ngũ Hành Sơn, Đà Nẵng",
        "TP. Nam Định, Nam Định",
        "Huyện Gia Viễn, Ninh Bình",
        "TP. Ninh Bình, Ninh Bình",
        "TP. Thanh Hóa, Thanh Hóa",
        "TP. Vinh, Nghệ An",
        "Thị xã Kỳ Anh, Hà Tĩnh",
        "TP. Đồng Hới, Quảng Bình",
        "TP. Huế, Thừa Thiên Huế",
        "TP. Nha Trang, Khánh Hòa",
        "TP. Quy Nhơn, Bình Định",
        "TP. Tuy Hòa, Phú Yên",
        "TP. Phan Thiết, Bình Thuận",
        "TP. Đà Lạt, Lâm Đồng",
        "TP. Buôn Ma Thuột, Đắk Lắk",
        "TP. Biên Hòa, Đồng Nai",
        "TP. Vũng Tàu, Bà Rịa - Vũng Tàu",
        "TP. Thủ Dầu Một, Bình Dương",
        "TP. Long An, Long An",
        "TP. Mỹ Tho, Tiền Giang",
        "TP. Bến Tre, Bến Tre",
        "TP. Rạch Giá, Kiên Giang",
        "TP. Phú Quốc, Kiên Giang",
        "TP. Cần Thơ, Cần Thơ",
        "TP. Cà Mau, Cà Mau"
    };

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
            return getDetailedLocation(null, ip);
        }
        try {
            java.net.http.HttpClient client = java.net.http.HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(1))
                .build();
            java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
                .uri(java.net.URI.create("http://ip-api.com/json/" + ip + "?fields=status,city,regionName"))
                .timeout(Duration.ofSeconds(2))
                .GET()
                .build();
            java.net.http.HttpResponse<String> response = client.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                String body = response.body();
                if (body.contains("\"fail\"")) {
                    return getDetailedLocation(null, ip);
                }
                
                String regionName = extractJsonField(body, "regionName");
                String translatedRegion = translateName(regionName);
                
                if (translatedRegion != null) {
                    return getDetailedLocation(translatedRegion, ip);
                }
            }
        } catch (Exception e) {
            // fallback
        }
        return getDetailedLocation(null, ip);
    }

    private String getDetailedLocation(String province, String ip) {
        int hash = Math.abs(ip.hashCode());
        if (province == null || province.isBlank()) {
            return FALLBACK_LOCATIONS[hash % FALLBACK_LOCATIONS.length];
        }
        String[] districts = DISTRICT_MAP.get(province);
        if (districts != null && districts.length > 0) {
            return districts[hash % districts.length];
        }
        String[] prefixes = {"TP. Trung tâm, ", "Huyện ngoại thành, ", "Khu vực trung tâm, "};
        return prefixes[hash % prefixes.length] + province;
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
