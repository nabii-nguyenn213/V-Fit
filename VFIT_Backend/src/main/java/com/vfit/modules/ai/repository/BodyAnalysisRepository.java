package com.vfit.modules.ai.repository;

import com.vfit.modules.ai.document.BodyAnalysisResult;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface BodyAnalysisRepository extends MongoRepository<BodyAnalysisResult, String> {
}
