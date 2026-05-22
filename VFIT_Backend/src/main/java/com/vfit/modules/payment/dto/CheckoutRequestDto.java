package com.vfit.modules.payment.dto;

import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CheckoutRequestDto {
    @Size(max = 64)
    private String voucherCode;
}
