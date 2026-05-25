package com.vfit.modules.payment.service;

import com.vfit.modules.payment.dto.CheckoutRequestDto;
import com.vfit.modules.payment.dto.CheckoutResponseDto;
import com.vfit.modules.payment.dto.CreatePaymentRequest;
import com.vfit.modules.payment.dto.PaymentResponse;
import com.vfit.modules.payment.dto.PaymentStatusResponse;
import com.vfit.modules.payment.dto.PaymentQuoteResponseDto;

public interface PaymentService {
    PaymentQuoteResponseDto applyVoucher(String userId, CheckoutRequestDto request);

    CheckoutResponseDto checkout(String userId, CheckoutRequestDto request);

    PaymentResponse createPremiumPayment(String userId, CreatePaymentRequest request);

    PaymentStatusResponse getPaymentStatus(String userId, String paymentId);
}
