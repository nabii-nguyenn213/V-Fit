package com.vfit.infrastructure.external.payment;

import java.math.BigDecimal;

public interface PaymentClient {
    String createCheckout(String userId, BigDecimal amount, String currency);
}
