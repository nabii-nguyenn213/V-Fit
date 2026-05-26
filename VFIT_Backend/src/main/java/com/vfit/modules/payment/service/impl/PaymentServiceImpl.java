package com.vfit.modules.payment.service.impl;

import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.modules.checkin.entity.UserVoucher;
import com.vfit.modules.checkin.entity.UserVoucherStatus;
import com.vfit.modules.checkin.repository.UserVoucherAtomicRepository;
import com.vfit.modules.checkin.repository.UserVoucherRepository;
import com.vfit.modules.payment.dto.CheckoutRequestDto;
import com.vfit.modules.payment.dto.CheckoutResponseDto;
import com.vfit.modules.payment.dto.CreatePaymentRequest;
import com.vfit.modules.payment.dto.PaymentResponse;
import com.vfit.modules.payment.dto.PaymentStatusResponse;
import com.vfit.modules.payment.dto.PaymentQuoteResponseDto;
import com.vfit.modules.payment.dto.VipStatusResponse;
import com.vfit.modules.payment.config.PaymentProperties;
import com.vfit.modules.payment.entity.PaymentOrder;
import com.vfit.modules.payment.entity.PaymentOrderStatus;
import com.vfit.modules.payment.enums.PaymentStatus;
import com.vfit.modules.payment.enums.PremiumPlan;
import com.vfit.modules.payment.exception.VoucherValidationException;
import com.vfit.modules.payment.repository.PaymentOrderRepository;
import com.vfit.modules.payment.service.PaymentService;
import com.vfit.modules.payment.service.VietQrService;
import com.vfit.modules.payment.service.VoucherService;
import com.vfit.modules.subscription.SubscriptionPlanCatalog;
import com.vfit.modules.subscription.document.PaymentTransaction;
import com.vfit.modules.subscription.document.Subscription;
import com.vfit.modules.subscription.repository.PaymentTransactionRepository;
import com.vfit.modules.subscription.repository.SubscriptionRepository;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.concurrent.ThreadLocalRandom;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

@Service
@Slf4j
@RequiredArgsConstructor
public class PaymentServiceImpl implements PaymentService {
    private static final Duration PAYMENT_LOCK_TTL = Duration.ofSeconds(12);

    private final PaymentOrderRepository paymentOrderRepository;
    private final UserVoucherRepository userVoucherRepository;
    private final UserVoucherAtomicRepository userVoucherAtomicRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;
    private final StringRedisTemplate redisTemplate;
    private final VietQrService vietQrService;
    private final PaymentProperties paymentProperties;
    private final VoucherService voucherService;

    @Override
    public PaymentQuoteResponseDto applyVoucher(String userId, CheckoutRequestDto request) {
        return withPaymentLock(userId, () -> {
            assertVipCanRenew(userId, Instant.now());
            PaymentOrder order = getOrCreateDraftOrder(userId);
            applyVoucherToOrder(order, normalizeVoucherCode(request.getVoucherCode()));
            return toQuote(paymentOrderRepository.save(order));
        });
    }

    @Override
    public CheckoutResponseDto checkout(String userId, CheckoutRequestDto request) {
        return withPaymentLock(userId, () -> {
            assertVipCanRenew(userId, Instant.now());
            PaymentOrder order = getOrCreateDraftOrder(userId);
            String requestedVoucherCode = normalizeVoucherCode(request.getVoucherCode());
            if (requestedVoucherCode != null) {
                if (order.getVoucherCode() == null) {
                    applyVoucherToOrder(order, requestedVoucherCode);
                } else if (!order.getVoucherCode().equals(requestedVoucherCode)) {
                    throw new VoucherValidationException("Đơn hàng này đã có một voucher khác. Không được cộng dồn voucher.");
                }
            }

            Instant now = Instant.now();
            if (order.getVoucherCode() != null) {
                UserVoucher redeemed = userVoucherAtomicRepository
                        .redeemAvailableVoucher(userId, order.getVoucherCode(), now, order.getId())
                        .orElseThrow(() -> new VoucherValidationException("Voucher không còn khả dụng hoặc đã hết hạn."));
                order.setVoucherCode(redeemed.getCode());
                order.setDiscountAmount(redeemed.getAmount());
                order.setFinalAmount(calculateFinalAmount(order.getOriginalAmount(), redeemed.getAmount()));
            }

            order.setStatus(PaymentOrderStatus.CHECKED_OUT);
            PaymentOrder checkedOutOrder = paymentOrderRepository.save(order);

            PaymentTransaction transaction = paymentTransactionRepository.save(PaymentTransaction.builder()
                    .userId(userId)
                    .amount(checkedOutOrder.getFinalAmount())
                    .currency(SubscriptionPlanCatalog.CURRENCY)
                    .providerRef("VFIT-MOCK-" + checkedOutOrder.getId())
                    .status("SUCCESS")
                    .build());

            SubscriptionPlanCatalog.Plan plan = SubscriptionPlanCatalog.VIP_MONTHLY;
            Instant premiumUntil = now.plus(Duration.ofDays(plan.durationDays()));
            subscriptionRepository.save(Subscription.builder()
                    .userId(userId)
                    .planCode(plan.code())
                    .status(SubscriptionStatus.ACTIVE)
                    .startedAt(now)
                    .expiresAt(premiumUntil)
                    .build());
            updateUserSubscription(userId, plan.code(), premiumUntil);

            return CheckoutResponseDto.builder()
                    .orderId(checkedOutOrder.getId())
                    .transactionId(transaction.getId())
                    .planCode(checkedOutOrder.getPlanCode())
                    .originalAmount(checkedOutOrder.getOriginalAmount())
                    .discountAmount(checkedOutOrder.getDiscountAmount())
                    .finalAmount(checkedOutOrder.getFinalAmount())
                    .voucherCode(checkedOutOrder.getVoucherCode())
                    .status(transaction.getStatus())
                    .premiumUntil(premiumUntil)
                    .build();
        });
    }

    @Override
    public PaymentResponse createPremiumPayment(String userId, CreatePaymentRequest request) {
        return withPaymentLock(userId, () -> {
            validatePaymentConfig();
            Instant now = Instant.now();
            assertVipCanRenew(userId, now);
            Instant expiredAt = now.plus(Duration.ofMinutes(paymentProperties.getExpiryMinutes()));
            String paymentCode = generateUniquePaymentCode();
            PremiumPlan plan = request.plan();
            BigDecimal baseAmount = plan.basePrice();
            VoucherService.AppliedVoucher voucher = voucherService
                    .validateForPayment(userId, plan, request.voucherCode())
                    .orElse(null);
            BigDecimal discountAmount = voucher == null ? BigDecimal.ZERO : voucher.discountAmount();
            BigDecimal finalAmount = calculateFinalAmount(baseAmount, discountAmount);
            String qrUrl = vietQrService.buildQrUrl(finalAmount, paymentCode);

            PaymentTransaction transaction = paymentTransactionRepository.save(PaymentTransaction.builder()
                    .userId(userId)
                    .plan(plan)
                    .baseAmount(baseAmount)
                    .discountAmount(discountAmount)
                    .finalAmount(finalAmount)
                    .amount(finalAmount)
                    .currency(SubscriptionPlanCatalog.CURRENCY)
                    .paymentCode(paymentCode)
                    .voucherCode(voucher == null ? null : voucher.code())
                    .paymentStatus(PaymentStatus.PENDING)
                    .status(PaymentStatus.PENDING.name())
                    .vietQrUrl(qrUrl)
                    .expiredAt(expiredAt)
                    .build());

            return new PaymentResponse(
                    transaction.getId(),
                    transaction.getPlan(),
                    transaction.getBaseAmount(),
                    transaction.getDiscountAmount(),
                    transaction.getFinalAmount(),
                    paymentProperties.getBankCode(),
                    paymentProperties.getAccountNumber(),
                    paymentProperties.getAccountName(),
                    transaction.getPaymentCode(),
                    transaction.getVoucherCode(),
                    transaction.getVietQrUrl(),
                    transaction.getExpiredAt());
        });
    }

    @Override
    public PaymentStatusResponse getPaymentStatus(String userId, String paymentId) {
        PaymentTransaction transaction = paymentTransactionRepository.findByIdAndUserId(paymentId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Payment not found"));
        PaymentStatus status = resolvePaymentStatus(transaction);
        Instant premiumUntil = userRepository.findById(userId)
                .map(User::getSubscription)
                .map(User.SubscriptionSnapshot::getPremiumUntil)
                .orElse(null);
        boolean premiumUnlocked = status == PaymentStatus.PAID
                && premiumUntil != null
                && premiumUntil.isAfter(Instant.now());
        return new PaymentStatusResponse(
                transaction.getId(),
                status,
                premiumUnlocked,
                premiumUntil);
    }

    @Override
    public VipStatusResponse getVipStatus(String userId) {
        return toVipStatus(userId, Instant.now());
    }

    private PaymentOrder getOrCreateDraftOrder(String userId) {
        return paymentOrderRepository
                .findFirstByUserIdAndStatusOrderByCreatedAtDesc(userId, PaymentOrderStatus.DRAFT)
                .orElseGet(() -> {
                    SubscriptionPlanCatalog.Plan plan = SubscriptionPlanCatalog.VIP_MONTHLY;
                    return paymentOrderRepository.save(PaymentOrder.builder()
                            .userId(userId)
                            .planCode(plan.code())
                            .originalAmount(plan.price())
                            .discountAmount(BigDecimal.ZERO)
                            .finalAmount(plan.price())
                            .status(PaymentOrderStatus.DRAFT)
                            .build());
                });
    }

    private void applyVoucherToOrder(PaymentOrder order, String voucherCode) {
        if (voucherCode == null) {
            throw new VoucherValidationException("Vui lòng nhập mã voucher.");
        }
        if (order.getVoucherCode() != null) {
            if (order.getVoucherCode().equals(voucherCode)) {
                return;
            }
            throw new VoucherValidationException("Mỗi đơn hàng chỉ được áp dụng một voucher. Không được cộng dồn voucher.");
        }

        UserVoucher voucher = userVoucherRepository
                .findByUserIdAndCodeAndStatusAndExpiredAtAfter(
                        order.getUserId(),
                        voucherCode,
                        UserVoucherStatus.AVAILABLE,
                        Instant.now())
                .orElseThrow(() -> new VoucherValidationException("Voucher không hợp lệ, đã dùng hoặc đã hết hạn."));

        BigDecimal discountAmount = voucher.getAmount().min(order.getOriginalAmount());
        order.setVoucherCode(voucher.getCode());
        order.setDiscountAmount(discountAmount);
        order.setFinalAmount(calculateFinalAmount(order.getOriginalAmount(), discountAmount));
    }

    private BigDecimal calculateFinalAmount(BigDecimal originalAmount, BigDecimal discountAmount) {
        BigDecimal finalAmount = originalAmount.subtract(discountAmount);
        return finalAmount.signum() < 0 ? BigDecimal.ZERO : finalAmount;
    }

    private PaymentQuoteResponseDto toQuote(PaymentOrder order) {
        return PaymentQuoteResponseDto.builder()
                .orderId(order.getId())
                .planCode(order.getPlanCode())
                .originalAmount(order.getOriginalAmount())
                .discountAmount(order.getDiscountAmount())
                .finalAmount(order.getFinalAmount())
                .voucherCode(order.getVoucherCode())
                .build();
    }

    private String normalizeVoucherCode(String voucherCode) {
        if (voucherCode == null || voucherCode.isBlank()) {
            return null;
        }
        return voucherCode.trim().toUpperCase(Locale.ROOT);
    }

    private void updateUserSubscription(String userId, String planCode, Instant premiumUntil) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "User not found"));
        user.setSubscription(User.SubscriptionSnapshot.builder()
                .status(SubscriptionStatus.ACTIVE)
                .planCode(planCode)
                .premiumUntil(premiumUntil)
                .build());
        userRepository.save(user);
    }

    private void assertVipCanRenew(String userId, Instant now) {
        VipStatusResponse status = toVipStatus(userId, now);
        if (status.isVip() && !status.canRenew()) {
            throw new AppException(ErrorCode.CONFLICT, "VIP package is already active.");
        }
    }

    private VipStatusResponse toVipStatus(String userId, Instant now) {
        User.SubscriptionSnapshot subscription = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "User not found"))
                .getSubscription();
        Subscription persistedSubscription = subscriptionRepository
                .findFirstByUserIdOrderByExpiresAtDesc(userId)
                .orElse(null);
        Instant expiredAt = resolvePremiumUntil(subscription, persistedSubscription);
        String planCode = resolvePlanCode(subscription, persistedSubscription);
        SubscriptionStatus status = resolveStatus(subscription, persistedSubscription);
        boolean hasVipPlan = isVipPlan(planCode);
        boolean isVip = status == SubscriptionStatus.ACTIVE
                && hasVipPlan
                && (expiredAt == null || expiredAt.isAfter(now));
        Duration remaining = expiredAt == null || !expiredAt.isAfter(now)
                ? Duration.ZERO
                : Duration.between(now, expiredAt);
        boolean canRenew = !isVip || (expiredAt != null && remaining.compareTo(Duration.ofDays(3)) < 0);
        return new VipStatusResponse(
                isVip,
                normalizeVipType(planCode),
                expiredAt,
                remaining.toDays(),
                canRenew);
    }

    private Instant resolvePremiumUntil(User.SubscriptionSnapshot snapshot, Subscription persistedSubscription) {
        if (snapshot != null && snapshot.getPremiumUntil() != null) {
            return snapshot.getPremiumUntil();
        }
        return persistedSubscription == null ? null : persistedSubscription.getExpiresAt();
    }

    private String resolvePlanCode(User.SubscriptionSnapshot snapshot, Subscription persistedSubscription) {
        if (snapshot != null && snapshot.getPlanCode() != null && !snapshot.getPlanCode().isBlank()) {
            return snapshot.getPlanCode();
        }
        return persistedSubscription == null ? null : persistedSubscription.getPlanCode();
    }

    private SubscriptionStatus resolveStatus(User.SubscriptionSnapshot snapshot, Subscription persistedSubscription) {
        if (snapshot != null && snapshot.getStatus() != null) {
            return snapshot.getStatus();
        }
        return persistedSubscription == null ? null : persistedSubscription.getStatus();
    }

    private String normalizeVipType(String planCode) {
        if (planCode == null || planCode.isBlank()) {
            return null;
        }
        return switch (planCode.toUpperCase(Locale.ROOT)) {
            case "VIP_MONTHLY", "MONTHLY" -> "MONTHLY";
            case "VIP_YEARLY", "YEARLY" -> "YEARLY";
            default -> planCode;
        };
    }

    private boolean isVipPlan(String planCode) {
        if (planCode == null || planCode.isBlank()) {
            return false;
        }
        return switch (planCode.toUpperCase(Locale.ROOT)) {
            case "VIP_MONTHLY", "VIP_YEARLY", "MONTHLY", "YEARLY" -> true;
            default -> false;
        };
    }

    private String generateUniquePaymentCode() {
        for (int attempt = 0; attempt < 5; attempt++) {
            String candidate = "VFIT" + java.time.format.DateTimeFormatter.ofPattern("yyyyMMddHHmmss")
                    .withZone(java.time.ZoneOffset.UTC)
                    .format(Instant.now())
                    + ThreadLocalRandom.current().nextInt(100, 999);
            if (paymentTransactionRepository.findByPaymentCode(candidate).isEmpty()) {
                return candidate;
            }
        }
        throw new AppException(ErrorCode.CONFLICT, "Could not generate unique payment code");
    }

    private void validatePaymentConfig() {
        if (paymentProperties.getBankCode().isBlank()
                || paymentProperties.getAccountNumber().isBlank()
                || paymentProperties.getAccountName().isBlank()) {
            throw new AppException(ErrorCode.SERVICE_UNAVAILABLE, "Payment bank account is not configured");
        }
    }

    private PaymentStatus resolvePaymentStatus(PaymentTransaction transaction) {
        if (transaction.getPaymentStatus() != null) {
            return transaction.getPaymentStatus();
        }
        if (transaction.getStatus() == null) {
            return null;
        }
        try {
            return PaymentStatus.valueOf(transaction.getStatus());
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }

    private <T> T withPaymentLock(String userId, LockedOperation<T> operation) {
        String lockKey = "vfit:payment:voucher:" + userId;
        boolean locked = acquireLock(lockKey);
        try {
            return operation.run();
        } finally {
            if (locked) {
                releaseLock(lockKey);
            }
        }
    }

    private boolean acquireLock(String lockKey) {
        try {
            Boolean locked = redisTemplate.opsForValue().setIfAbsent(lockKey, "1", PAYMENT_LOCK_TTL);
            if (Boolean.FALSE.equals(locked)) {
                throw new VoucherValidationException("Giao dịch đang được xử lý, vui lòng không bấm liên tục.");
            }
            return Boolean.TRUE.equals(locked);
        } catch (DataAccessException ex) {
            log.warn("Redis unavailable for payment lock, using Mongo atomic fallback: {}", ex.getMessage());
            return false;
        }
    }

    private void releaseLock(String lockKey) {
        try {
            redisTemplate.delete(lockKey);
        } catch (DataAccessException ex) {
            log.warn("Redis unavailable while releasing payment lock: {}", ex.getMessage());
        }
    }

    @FunctionalInterface
    private interface LockedOperation<T> {
        T run();
    }
}
