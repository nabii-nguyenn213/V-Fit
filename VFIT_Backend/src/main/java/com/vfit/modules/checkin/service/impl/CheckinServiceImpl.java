package com.vfit.modules.checkin.service.impl;

import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.common.util.DateTimeUtil;
import com.vfit.modules.checkin.dto.response.CheckinResponse;
import com.vfit.modules.checkin.dto.response.CheckinStatusResponse;
import com.vfit.modules.checkin.dto.response.VoucherResponse;
import com.vfit.modules.checkin.entity.CheckinLog;
import com.vfit.modules.checkin.entity.UserVoucher;
import com.vfit.modules.checkin.entity.UserVoucherStatus;
import com.vfit.modules.checkin.exception.DuplicateCheckinException;
import com.vfit.modules.checkin.repository.CheckinLogRepository;
import com.vfit.modules.checkin.repository.UserVoucherRepository;
import com.vfit.modules.checkin.service.CheckinService;
import com.vfit.modules.user.repository.UserRepository;
import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

@Service
@Slf4j
@RequiredArgsConstructor
public class CheckinServiceImpl implements CheckinService {
    private static final Duration CHECKIN_LOCK_TTL = Duration.ofSeconds(8);
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final CheckinLogRepository checkinLogRepository;
    private final UserVoucherRepository userVoucherRepository;
    private final UserRepository userRepository;
    private final StringRedisTemplate redisTemplate;

    @Override
    public CheckinResponse checkin(String userId) {
        if (!userRepository.existsById(userId)) {
            throw new AppException(ErrorCode.RESOURCE_NOT_FOUND, "User not found");
        }

        LocalDate today = DateTimeUtil.todayVietnam();
        String checkinDate = DateTimeUtil.checkinDateVietnam(today);
        String monthKey = DateTimeUtil.currentVietnamMonthKey(today);
        String lockKey = "vfit:checkin:" + userId + ":" + checkinDate;
        boolean locked = acquireLock(lockKey);

        try {
            CheckinLog log = CheckinLog.builder()
                    .userId(userId)
                    .checkinDate(checkinDate)
                    .monthKey(monthKey)
                    .build();
            checkinLogRepository.save(log);

            long monthCount = checkinLogRepository.countByUserIdAndMonthKey(userId, monthKey);
            List<VoucherResponse> awarded = awardMilestoneVouchers(userId, monthKey, monthCount);

            return CheckinResponse.builder()
                    .checkinDate(checkinDate)
                    .monthKey(monthKey)
                    .monthCheckinCount(monthCount)
                    .awardedVouchers(awarded)
                    .build();
        } catch (DuplicateKeyException ex) {
            throw new DuplicateCheckinException("Bạn đã điểm danh hôm nay rồi.");
        } finally {
            if (locked) {
                releaseLock(lockKey);
            }
        }
    }

    @Override
    public CheckinStatusResponse getCheckinStatus(String userId) {
        if (!userRepository.existsById(userId)) {
            throw new AppException(ErrorCode.RESOURCE_NOT_FOUND, "User not found");
        }

        LocalDate today = DateTimeUtil.todayVietnam();
        String checkinDate = DateTimeUtil.checkinDateVietnam(today);
        String monthKey = DateTimeUtil.currentVietnamMonthKey(today);

        boolean checkedToday = checkinLogRepository.existsByUserIdAndCheckinDate(userId, checkinDate);
        long monthCount = checkinLogRepository.countByUserIdAndMonthKey(userId, monthKey);

        return CheckinStatusResponse.builder()
                .checkedToday(checkedToday)
                .monthCheckinCount(monthCount)
                .build();
    }

    private boolean acquireLock(String lockKey) {
        try {
            Boolean locked = redisTemplate.opsForValue().setIfAbsent(lockKey, "1", CHECKIN_LOCK_TTL);
            if (Boolean.FALSE.equals(locked)) {
                throw new DuplicateCheckinException("Điểm danh đang được xử lý, vui lòng không bấm liên tục.");
            }
            return Boolean.TRUE.equals(locked);
        } catch (DataAccessException ex) {
            log.warn("Redis unavailable for check-in lock, using Mongo unique index fallback: {}", ex.getMessage());
            return false;
        }
    }

    private void releaseLock(String lockKey) {
        try {
            redisTemplate.delete(lockKey);
        } catch (DataAccessException ex) {
            log.warn("Redis unavailable while releasing check-in lock: {}", ex.getMessage());
        }
    }

    private List<VoucherResponse> awardMilestoneVouchers(String userId, String monthKey, long monthCount) {
        List<VoucherResponse> awarded = new ArrayList<>();
        tryAward(userId, monthKey, monthCount, 15, BigDecimal.valueOf(10_000), Duration.ofDays(15))
                .ifPresent(awarded::add);
        tryAward(userId, monthKey, monthCount, 30, BigDecimal.valueOf(30_000), Duration.ofDays(30))
                .ifPresent(awarded::add);
        return awarded;
    }

    private java.util.Optional<VoucherResponse> tryAward(
            String userId,
            String monthKey,
            long monthCount,
            int milestone,
            BigDecimal amount,
            Duration ttl) {
        if (monthCount < milestone ||
                userVoucherRepository.existsByUserIdAndMonthKeyAndRewardMilestone(userId, monthKey, milestone)) {
            return java.util.Optional.empty();
        }

        Instant issuedAt = Instant.now();
        UserVoucher voucher = UserVoucher.builder()
                .userId(userId)
                .code(generateVoucherCode())
                .amount(amount)
                .status(UserVoucherStatus.AVAILABLE)
                .issuedAt(issuedAt)
                .expiredAt(issuedAt.plus(ttl))
                .monthKey(monthKey)
                .rewardMilestone(milestone)
                .build();
        try {
            return java.util.Optional.of(VoucherResponse.from(userVoucherRepository.save(voucher)));
        } catch (DuplicateKeyException ex) {
            return java.util.Optional.empty();
        }
    }

    private String generateVoucherCode() {
        byte[] random = new byte[8];
        SECURE_RANDOM.nextBytes(random);
        return "VFIT-" + HexFormat.of().formatHex(random).toUpperCase();
    }
}
