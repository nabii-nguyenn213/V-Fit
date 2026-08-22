package com.vfit.modules.admin.repository;

import com.vfit.modules.admin.document.VisitorLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VisitorLogRepository extends MongoRepository<VisitorLog, String> {
    Page<VisitorLog> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
