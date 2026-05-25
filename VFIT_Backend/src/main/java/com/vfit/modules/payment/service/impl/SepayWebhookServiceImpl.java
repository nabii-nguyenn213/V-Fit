package com.vfit.modules.payment.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.modules.payment.dto.SepayWebhookPayload;
import com.vfit.modules.payment.enums.PaymentStatus;
import com.vfit.modules.payment.enums.PremiumPlan;
import com.vfit.modules.payment.service.HmacSha256Service;
import com.vfit.modules.payment.service.SepayWebhookService;
import com.vfit.modules.payment.service.VoucherService;
import com.vfit.modules.payment.websocket.PaymentWebSocketHandler;
import com.vfit.modules.subscription.document.PaymentTransaction;
import com.vfit.modules.subscription.document.Subscription;
import com.vfit.modules.subscription.repository.PaymentTransactionRepository;
import com.vfit.modules.subscription.repository.SubscriptionRepository;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class SepayWebhookServiceImpl implements SepayWebhookService {
    private static final Pattern PAYMENT_CODE_PATTERN = Pattern.compile("\\bVFIT[0-9A-Z]+\\b");

    private final HmacSha256Service hmacSha256Service;
    private final ObjectMapper objectMapper;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;
    private final VoucherService voucherService;
    private final PaymentWebSocketHandler paymentWebSocketHandler;

    @Override
    public void handleWebhook(String rawBody, String signature, String timestamp) {
        if (!hmacSha256Service.verify(rawBody, signature, timestamp)) {
            log.warn("[SEPAY] Rejected webhook with invalid signature");
            throw new AppException(ErrorCode.UNAUTHORIZED, "Invalid SePay signature");
        }

        SepayWebhookPayload payload = parsePayload(rawBody);
        String transactionId = requireTransactionId(payload);
        if (paymentTransactionRepository.findBySepayTransactionId(transactionId).isPresent()) {
            log.info("[SEPAY] Duplicate webhook ignored, transactionId={}", transactionId);
            return;
        }

        String paymentCode = extractPaymentCode(payload.content());
        if (paymentCode == null) {
            log.warn("[SEPAY] Suspicious webhook without V-FIT payment code, transactionId={}, content={}",
                    transactionId, payload.content());
            return;
        }

        PaymentTransaction payment = paymentTransactionRepository.findByPaymentCode(paymentCode)
                .orElseThrow(() -> {
                    log.warn("[SEPAY] Suspicious webhook with unknown paymentCode={}, transactionId={}",
                            paymentCode, transactionId);
                    return new AppException(ErrorCode.BAD_REQUEST, "Unknown payment code");
                });

        if (payment.getPaymentStatus() == PaymentStatus.PAID) {
            ensurePremiumUnlockedForPaidPayment(payment);
            log.info("[SEPAY] Payment already paid, paymentCode={}, transactionId={}", paymentCode, transactionId);
            return;
        }
        if (payment.getPaymentStatus() != PaymentStatus.PENDING && payment.getPaymentStatus() != PaymentStatus.EXPIRED) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Payment is not payable");
        }
        BigDecimal expectedAmount = payment.getFinalAmount() == null ? payment.getAmount() : payment.getFinalAmount();
        if (payload.amount() == null || payload.amount().compareTo(expectedAmount) != 0) {
            markManualReview(payment, rawBody, transactionId);
            log.warn("[SEPAY] Amount mismatch for paymentCode={}, expected={}, actual={}",
                    paymentCode, expectedAmount, payload.amount());
            throw new AppException(ErrorCode.BAD_REQUEST, "Payment amount mismatch");
        }
        if (payment.getExpiredAt() != null && payment.getExpiredAt().isBefore(Instant.now())) {
            log.warn("[SEPAY] Accepting late but valid paymentCode={} expiredAt={}", paymentCode, payment.getExpiredAt());
        }

        markPaidAndUnlockPremium(payment, transactionId, rawBody);
    }

    private SepayWebhookPayload parsePayload(String rawBody) {
        try {
            return objectMapper.readValue(rawBody, SepayWebhookPayload.class);
        } catch (Exception ex) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Malformed SePay webhook payload");
        }
    }

    private String requireTransactionId(SepayWebhookPayload payload) {
        if (payload.transactionId() == null || payload.transactionId().isBlank()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Missing SePay transaction id");
        }
        return payload.transactionId().trim();
    }

    private String extractPaymentCode(String content) {
        if (content == null) {
            return null;
        }
        Matcher matcher = PAYMENT_CODE_PATTERN.matcher(content.toUpperCase());
        return matcher.find() ? matcher.group() : null;
    }

    private void markPaidAndUnlockPremium(PaymentTransaction payment, String transactionId, String rawBody) {
        Instant now = Instant.now();
        PremiumPlan plan = payment.getPlan() == null ? PremiumPlan.MONTHLY : payment.getPlan();
        if (payment.getVoucherCode() != null
                && !payment.getVoucherCode().isBlank()
                && !voucherService.markUsed(payment.getUserId(), payment.getVoucherCode(), payment.getId())) {
            markManualReview(payment, rawBody, transactionId);
            log.warn("[SEPAY] Voucher redeem failed for paid transfer, paymentId={}, voucherCode={}",
                    payment.getId(), payment.getVoucherCode());
            throw new AppException(ErrorCode.BAD_REQUEST, "Voucher is no longer payable");
        }
        Instant premiumUntil = calculatePremiumUntil(payment.getUserId(), plan, now);

        payment.setPaymentStatus(PaymentStatus.PAID);
        payment.setStatus(PaymentStatus.PAID.name());
        payment.setPaidAt(now);
        payment.setSepayTransactionId(transactionId);
        payment.setSepayRawPayload(rawBody);

        try {
            paymentTransactionRepository.save(payment);
            subscriptionRepository.save(Subscription.builder()
                    .userId(payment.getUserId())
                    .planCode(plan.planCode())
                    .status(SubscriptionStatus.ACTIVE)
                    .startedAt(now)
                    .expiresAt(premiumUntil)
                    .build());
            updateUserSubscription(payment.getUserId(), plan.planCode(), premiumUntil);
            paymentWebSocketHandler.publishPaymentPaid(payment.getUserId(), payment.getId(), now);
            log.info("[SEPAY] Payment marked PAID and premium unlocked, paymentId={}, userId={}",
                    payment.getId(), payment.getUserId());
        } catch (DuplicateKeyException ex) {
            log.info("[SEPAY] Duplicate webhook raced and was ignored, transactionId={}", transactionId);
        }
    }

    private Instant calculatePremiumUntil(String userId, PremiumPlan plan, Instant now) {
        Instant currentPremiumUntil = userRepository.findById(userId)
                .map(User::getSubscription)
                .map(User.SubscriptionSnapshot::getPremiumUntil)
                .orElse(null);
        Instant base = currentPremiumUntil != null && currentPremiumUntil.isAfter(now) ? currentPremiumUntil : now;
        return base.plus(plan.duration());
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

    private void ensurePremiumUnlockedForPaidPayment(PaymentTransaction payment) {
        PremiumPlan plan = payment.getPlan() == null ? PremiumPlan.MONTHLY : payment.getPlan();
        Instant paidAt = payment.getPaidAt() == null ? Instant.now() : payment.getPaidAt();
        Instant minimumPremiumUntil = paidAt.plus(plan.duration());
        Instant currentPremiumUntil = userRepository.findById(payment.getUserId())
                .map(User::getSubscription)
                .map(User.SubscriptionSnapshot::getPremiumUntil)
                .orElse(null);
        if (currentPremiumUntil == null || currentPremiumUntil.isBefore(minimumPremiumUntil)) {
            updateUserSubscription(payment.getUserId(), plan.planCode(), minimumPremiumUntil);
        }
    }

    private void markManualReview(PaymentTransaction payment, String rawBody, String transactionId) {
        payment.setPaymentStatus(PaymentStatus.MANUAL_REVIEW);
        payment.setStatus(PaymentStatus.MANUAL_REVIEW.name());
        payment.setSepayTransactionId(transactionId);
        payment.setSepayRawPayload(rawBody);
        paymentTransactionRepository.save(payment);
    }
}
