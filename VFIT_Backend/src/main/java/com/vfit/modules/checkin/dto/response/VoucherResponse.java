package com.vfit.modules.checkin.dto.response;

import com.vfit.modules.checkin.entity.UserVoucher;
import com.vfit.modules.checkin.entity.UserVoucherStatus;
import java.math.BigDecimal;
import java.time.Instant;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class VoucherResponse {
    private String id;
    private String code;
    private BigDecimal amount;
    private UserVoucherStatus status;
    private Instant issuedAt;
    private Instant expiredAt;
    private Integer rewardMilestone;

    public static VoucherResponse from(UserVoucher voucher) {
        return VoucherResponse.builder()
                .id(voucher.getId())
                .code(voucher.getCode())
                .amount(voucher.getAmount())
                .status(voucher.getStatus())
                .issuedAt(voucher.getIssuedAt())
                .expiredAt(voucher.getExpiredAt())
                .rewardMilestone(voucher.getRewardMilestone())
                .build();
    }
}
