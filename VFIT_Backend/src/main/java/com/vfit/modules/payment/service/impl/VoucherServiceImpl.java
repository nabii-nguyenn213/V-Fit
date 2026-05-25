package com.vfit.modules.payment.service.impl;

import com.vfit.modules.payment.entity.Voucher;
import com.vfit.modules.payment.enums.PremiumPlan;
import com.vfit.modules.payment.enums.VoucherStatus;
import com.vfit.modules.payment.enums.VoucherType;
import com.vfit.modules.payment.exception.VoucherValidationException;
import com.vfit.modules.payment.repository.VoucherRepository;
import com.vfit.modules.payment.service.VoucherService;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class VoucherServiceImpl implements VoucherService {
    private final VoucherRepository voucherRepository;
    private final MongoTemplate mongoTemplate;

    @Override
    public Voucher issueVoucher(String code, VoucherType type, String userId, boolean isPublic) {
        if (!isPublic && (userId == null || userId.isBlank())) {
            throw new VoucherValidationException("Voucher riêng cần userId.");
        }
        Instant now = Instant.now();
        return voucherRepository.save(Voucher.builder()
                .code(normalize(code))
                .type(type)
                .discountAmount(type.discountAmount())
                .applicablePlan(type.applicablePlan().orElse(null))
                .userId(isPublic ? null : userId)
                .isPublic(isPublic)
                .status(VoucherStatus.ACTIVE)
                .createdAt(now)
                .expiredAt(now.plus(1, ChronoUnit.MONTHS))
                .build());
    }

    @Override
    public Optional<AppliedVoucher> validateForPayment(String userId, PremiumPlan plan, String voucherCode) {
        String code = normalize(voucherCode);
        if (code == null) {
            return Optional.empty();
        }

        Voucher voucher = voucherRepository.findByCode(code)
                .orElseThrow(() -> new VoucherValidationException("Voucher không tồn tại."));
        Instant now = Instant.now();
        if (voucher.getStatus() != VoucherStatus.ACTIVE) {
            throw new VoucherValidationException("Voucher đã dùng hoặc không còn hoạt động.");
        }
        if (voucher.getExpiredAt() == null || !voucher.getExpiredAt().isAfter(now)) {
            throw new VoucherValidationException("Voucher đã hết hạn.");
        }
        if (!voucher.isPublic() && (voucher.getUserId() == null || !voucher.getUserId().equals(userId))) {
            throw new VoucherValidationException("Voucher không thuộc tài khoản này.");
        }
        PremiumPlan applicablePlan = resolveApplicablePlan(voucher);
        BigDecimal discountAmount = resolveDiscountAmount(voucher);
        if (applicablePlan == null || applicablePlan != plan) {
            throw new VoucherValidationException("Voucher không áp dụng cho gói đã chọn.");
        }
        if (discountAmount == null || discountAmount.signum() <= 0) {
            throw new VoucherValidationException("Voucher không hợp lệ.");
        }

        return Optional.of(new AppliedVoucher(voucher.getCode(), discountAmount, voucher));
    }

    @Override
    public boolean markUsed(String userId, String voucherCode, String paymentId) {
        String code = normalize(voucherCode);
        if (code == null) {
            return true;
        }

        Query query = Query.query(Criteria.where("code").is(code)
                .and("status").is(VoucherStatus.ACTIVE)
                .and("expiredAt").gt(Instant.now())
                .orOperator(
                        Criteria.where("is_public").is(true),
                        Criteria.where("userId").is(userId)));
        Update update = new Update()
                .set("status", VoucherStatus.USED)
                .set("usedAt", Instant.now())
                .set("usedByPaymentId", paymentId);
        Voucher used = mongoTemplate.findAndModify(
                query,
                update,
                FindAndModifyOptions.options().returnNew(true),
                Voucher.class);
        return used != null;
    }

    private String normalize(String voucherCode) {
        if (voucherCode == null || voucherCode.isBlank()) {
            return null;
        }
        return voucherCode.trim().toUpperCase(Locale.ROOT);
    }

    private PremiumPlan resolveApplicablePlan(Voucher voucher) {
        if (voucher.getType() != null) {
            return voucher.getType().applicablePlan().orElse(null);
        }
        return voucher.getApplicablePlan();
    }

    private BigDecimal resolveDiscountAmount(Voucher voucher) {
        if (voucher.getType() != null) {
            return voucher.getType().discountAmount();
        }
        return voucher.getDiscountAmount();
    }
}
