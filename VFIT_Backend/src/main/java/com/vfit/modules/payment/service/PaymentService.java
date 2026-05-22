package com.vfit.modules.payment.service;

import com.vfit.modules.payment.dto.CheckoutRequestDto;
import com.vfit.modules.payment.dto.CheckoutResponseDto;
import com.vfit.modules.payment.dto.PaymentQuoteResponseDto;

public interface PaymentService {
    PaymentQuoteResponseDto applyVoucher(String userId, CheckoutRequestDto request);

    CheckoutResponseDto checkout(String userId, CheckoutRequestDto request);
}
