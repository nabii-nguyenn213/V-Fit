package com.vfit.modules.notification.repository;

import com.vfit.modules.notification.document.Notification;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface NotificationRepository extends MongoRepository<Notification, String> {
}
