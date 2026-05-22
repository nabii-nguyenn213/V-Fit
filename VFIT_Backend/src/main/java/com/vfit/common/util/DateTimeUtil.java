package com.vfit.common.util;

import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

public final class DateTimeUtil {
    public static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter CHECKIN_DATE_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE;
    private static final DateTimeFormatter MONTH_KEY_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM");

    private DateTimeUtil() {
    }

    public static Instant now() {
        return Instant.now();
    }

    public static LocalDate todayUtc() {
        return LocalDate.now(ZoneOffset.UTC);
    }

    public static LocalDate todayVietnam() {
        return LocalDate.now(VIETNAM_ZONE);
    }

    public static String checkinDateVietnam(LocalDate date) {
        return CHECKIN_DATE_FORMATTER.format(date);
    }

    public static String currentVietnamMonthKey(LocalDate date) {
        return YearMonth.from(date).format(MONTH_KEY_FORMATTER);
    }
}
