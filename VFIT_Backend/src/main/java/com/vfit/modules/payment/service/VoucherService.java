package com.vfit.modules.payment.service;

import com.vfit.modules.payment.entity.Voucher;
import com.vfit.modules.payment.enums.PremiumPlan;
import com.vfit.modules.payment.enums.VoucherType;
import java.math.BigDecimal;
import java.util.Optional;

public interface VoucherService {
    Voucher issueVoucher(String code, VoucherType type, String userId, boolean isPublic);

    Optional<AppliedVoucher> validateForPayment(String userId, PremiumPlan plan, String voucherCode);

    boolean markUsed(String userId, String voucherCode, String paymentId);

    record AppliedVoucher(String code, BigDecimal discountAmount, Voucher voucher) {
    }
}
