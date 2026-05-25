package com.vfit.modules.payment.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.math.BigDecimal;

@JsonIgnoreProperties(ignoreUnknown = true)
public record SepayWebhookPayload(
        @JsonAlias({"id", "transactionId", "transaction_id"})
        String transactionId,
        @JsonAlias({"amount", "transferAmount", "transfer_amount", "money"})
        BigDecimal amount,
        @JsonAlias({"content", "transferContent", "transfer_content", "transactionContent"})
        String content,
        @JsonAlias({"accountNumber", "account_number", "bankAccount", "bank_account"})
        String accountNumber,
        @JsonAlias({"transactionDate", "transaction_date", "createdAt", "created_at"})
        String transactionDate
) {
}
