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
import com.vfit.modules.payment.dto.PaymentQuoteResponseDto;
import com.vfit.modules.payment.entity.PaymentOrder;
import com.vfit.modules.payment.entity.PaymentOrderStatus;
import com.vfit.modules.payment.exception.VoucherValidationException;
import com.vfit.modules.payment.repository.PaymentOrderRepository;
import com.vfit.modules.payment.service.PaymentService;
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

    @Override
    public PaymentQuoteResponseDto applyVoucher(String userId, CheckoutRequestDto request) {
        return withPaymentLock(userId, () -> {
            PaymentOrder order = getOrCreateDraftOrder(userId);
            applyVoucherToOrder(order, normalizeVoucherCode(request.getVoucherCode()));
            return toQuote(paymentOrderRepository.save(order));
        });
    }

    @Override
    public CheckoutResponseDto checkout(String userId, CheckoutRequestDto request) {
        return withPaymentLock(userId, () -> {
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
