package com.vfit.modules.exercise_library.repository;

import com.vfit.modules.exercise_library.document.ExerciseCatalog;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface ExerciseCatalogRepository extends MongoRepository<ExerciseCatalog, String> {
    Optional<ExerciseCatalog> findFirstByLocaleAndActiveTrueOrderByVersionDesc(String locale);
}
