package com.vfit.modules.subscription.repository;

import com.vfit.modules.subscription.document.Subscription;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface SubscriptionRepository extends MongoRepository<Subscription, String> {
}
