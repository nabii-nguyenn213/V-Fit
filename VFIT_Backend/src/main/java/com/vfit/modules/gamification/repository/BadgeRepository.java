package com.vfit.modules.gamification.repository;

import com.vfit.modules.gamification.document.Badge;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface BadgeRepository extends MongoRepository<Badge, String> {
}
