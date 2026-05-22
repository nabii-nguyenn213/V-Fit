package com.vfit.modules.app.repository;

import com.vfit.modules.app.document.AppConfig;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface AppConfigRepository extends MongoRepository<AppConfig, String> {
    Optional<AppConfig> findByConfigKey(String configKey);

    boolean existsByConfigKey(String configKey);
}
