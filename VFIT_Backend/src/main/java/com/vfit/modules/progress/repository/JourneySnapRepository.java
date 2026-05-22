package com.vfit.modules.progress.repository;

import com.vfit.modules.progress.document.JourneySnap;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface JourneySnapRepository extends MongoRepository<JourneySnap, String> {
    Page<JourneySnap> findByUserIdOrderByCreatedAtDesc(String userId, Pageable pageable);
}
