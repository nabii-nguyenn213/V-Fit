package com.vfit.infrastructure.external.payment;

import java.math.BigDecimal;
import java.util.UUID;
import org.springframework.stereotype.Component;

@Component
public class MockPaymentClient implements PaymentClient {
    @Override
    public String createCheckout(String userId, BigDecimal amount, String currency) {
        return "mock-checkout-" + UUID.randomUUID();
    }
}
