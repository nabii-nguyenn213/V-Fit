package com.vfit.modules.exercise_library.service;

import com.vfit.modules.exercise_library.dto.ExerciseCatalogResponse;

public interface ExerciseLibraryService {
    ExerciseCatalogResponse grouped(String locale);

    ExerciseCatalogResponse seedDefaultCatalog(String locale);

    void evictGroupedCache();
}
