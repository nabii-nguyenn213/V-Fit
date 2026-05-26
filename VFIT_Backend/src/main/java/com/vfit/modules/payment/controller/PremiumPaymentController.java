package com.vfit.modules.payment.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.util.SecurityUtil;
import com.vfit.modules.payment.dto.CreatePaymentRequest;
import com.vfit.modules.payment.dto.PaymentResponse;
import com.vfit.modules.payment.dto.PaymentStatusResponse;
import com.vfit.modules.payment.dto.VipStatusResponse;
import com.vfit.modules.payment.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
@Tag(name = "Premium Payments", description = "VietQR premium checkout")
public class PremiumPaymentController {
    private final PaymentService paymentService;

    @PostMapping("/create")
    @Operation(summary = "Create pending premium payment and return VietQR info")
    public ApiResponse<PaymentResponse> create(@Valid @RequestBody CreatePaymentRequest request) {
        return ApiResponse.created(paymentService.createPremiumPayment(SecurityUtil.requireCurrentUserId(), request));
    }

    @GetMapping("/{paymentId}/status")
    @Operation(summary = "Poll current premium payment status")
    public ApiResponse<PaymentStatusResponse> status(@PathVariable String paymentId) {
        return ApiResponse.ok(paymentService.getPaymentStatus(SecurityUtil.requireCurrentUserId(), paymentId));
    }

    @GetMapping("/vip-status")
    @Operation(summary = "Get current VIP membership status and renewal eligibility")
    public ApiResponse<VipStatusResponse> vipStatus() {
        return ApiResponse.ok(paymentService.getVipStatus(SecurityUtil.requireCurrentUserId()));
    }
}
