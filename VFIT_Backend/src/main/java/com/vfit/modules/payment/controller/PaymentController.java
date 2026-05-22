package com.vfit.modules.payment.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.util.SecurityUtil;
import com.vfit.modules.payment.dto.CheckoutRequestDto;
import com.vfit.modules.payment.dto.CheckoutResponseDto;
import com.vfit.modules.payment.dto.PaymentQuoteResponseDto;
import com.vfit.modules.payment.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
@Tag(name = "Payments", description = "Checkout and anti-stacking voucher validation")
public class PaymentController {
    private final PaymentService paymentService;

    @PostMapping("/apply-voucher")
    @Operation(summary = "Apply exactly one voucher to current draft order")
    public ApiResponse<PaymentQuoteResponseDto> applyVoucher(@Valid @RequestBody CheckoutRequestDto request) {
        return ApiResponse.ok(paymentService.applyVoucher(SecurityUtil.requireCurrentUserId(), request));
    }

    @PostMapping("/checkout")
    @Operation(summary = "Checkout current order with at most one voucher")
    public ApiResponse<CheckoutResponseDto> checkout(@Valid @RequestBody CheckoutRequestDto request) {
        return ApiResponse.ok(paymentService.checkout(SecurityUtil.requireCurrentUserId(), request));
    }
}
