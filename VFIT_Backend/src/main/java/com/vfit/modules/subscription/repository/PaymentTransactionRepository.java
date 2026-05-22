package com.vfit.modules.subscription.repository;

import com.vfit.modules.subscription.document.PaymentTransaction;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface PaymentTransactionRepository extends MongoRepository<PaymentTransaction, String> {
}
