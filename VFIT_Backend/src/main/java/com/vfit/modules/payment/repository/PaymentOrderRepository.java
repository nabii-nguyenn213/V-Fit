package com.vfit.modules.payment.repository;

import com.vfit.modules.payment.entity.PaymentOrder;
import com.vfit.modules.payment.entity.PaymentOrderStatus;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PaymentOrderRepository extends MongoRepository<PaymentOrder, String> {
    Optional<PaymentOrder> findFirstByUserIdAndStatusOrderByCreatedAtDesc(String userId, PaymentOrderStatus status);
}
