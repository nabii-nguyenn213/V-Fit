package com.vfit.modules.ai.repository;

import com.vfit.modules.ai.document.FormCheckResult;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface FormCheckResultRepository extends MongoRepository<FormCheckResult, String> {
}
