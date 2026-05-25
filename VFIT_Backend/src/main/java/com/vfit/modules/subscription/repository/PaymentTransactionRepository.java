package com.vfit.modules.subscription.repository;

import com.vfit.modules.payment.enums.PaymentStatus;
import com.vfit.modules.subscription.document.PaymentTransaction;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface PaymentTransactionRepository extends MongoRepository<PaymentTransaction, String> {
    Optional<PaymentTransaction> findByPaymentCode(String paymentCode);

    Optional<PaymentTransaction> findBySepayTransactionId(String sepayTransactionId);

    Optional<PaymentTransaction> findByIdAndUserId(String id, String userId);

    List<PaymentTransaction> findByPaymentStatusInAndExpiredAtBefore(Collection<PaymentStatus> statuses, Instant now);
}
