package com.vfit.modules.admin_dashboard.dto;

import java.time.Instant;

public record OrderDto(
    String id,
    String userId,
    String orderType,
    Double amount,
    String status,
    String voucherCode,
    Instant createdAt
) {}
