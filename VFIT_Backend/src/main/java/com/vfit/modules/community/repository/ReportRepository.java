package com.vfit.modules.community.repository;

import com.vfit.modules.community.document.Report;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface ReportRepository extends MongoRepository<Report, String> {
}
