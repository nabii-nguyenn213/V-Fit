package com.vfit.modules.exercise_library.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.modules.exercise_library.document.ExerciseCatalog;
import com.vfit.modules.exercise_library.dto.ExerciseCatalogResponse;
import com.vfit.modules.exercise_library.repository.ExerciseCatalogRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class ExerciseLibraryServiceImplTest {
    @Mock
    private ExerciseCatalogRepository repository;
    @Mock
    private ExerciseCatalogSeedFactory seedFactory;
    @Mock
    private StringRedisTemplate redisTemplate;
    @Mock
    private ValueOperations<String, String> valueOperations;

    private ExerciseLibraryServiceImpl service;

    @BeforeEach
    void setUp() {
        service = new ExerciseLibraryServiceImpl(repository, seedFactory, redisTemplate, new ObjectMapper());
        ReflectionTestUtils.setField(service, "cacheTtlSeconds", 86400L);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    void groupedReturnsCachedPayloadWithoutRepositoryCall() throws Exception {
        String cached = new ObjectMapper().writeValueAsString(new ExerciseCatalogResponse(7, List.of()));
        when(valueOperations.get("exercise-library:grouped:vi-VN")).thenReturn(cached);

        ExerciseCatalogResponse response = service.grouped("vi-VN");

        assertThat(response.catalogVersion()).isEqualTo(7);
        verify(repository, never()).findFirstByLocaleAndActiveTrueOrderByVersionDesc("vi-VN");
    }

    @Test
    void groupedSortsCatalogAndFiltersInactiveExercises() {
        when(valueOperations.get("exercise-library:grouped:vi-VN")).thenReturn(null);
        when(repository.findFirstByLocaleAndActiveTrueOrderByVersionDesc("vi-VN"))
                .thenReturn(Optional.of(catalog()));

        ExerciseCatalogResponse response = service.grouped("vi-VN");

        assertThat(response.catalogVersion()).isEqualTo(1);
        assertThat(response.groups()).extracting(ExerciseCatalogResponse.MuscleGroupResponse::id)
                .containsExactly("chest", "back");
        assertThat(response.groups().get(0).subGroups().get(0).exercises())
                .extracting(ExerciseCatalogResponse.ExerciseItemResponse::id)
                .containsExactly("bench");
    }

    @Test
    void groupedReturnsEmptyCatalogWhenMissing() {
        when(valueOperations.get("exercise-library:grouped:vi-VN")).thenReturn(null);
        when(repository.findFirstByLocaleAndActiveTrueOrderByVersionDesc("vi-VN")).thenReturn(Optional.empty());

        ExerciseCatalogResponse response = service.grouped("vi-VN");

        assertThat(response.catalogVersion()).isZero();
        assertThat(response.groups()).isEmpty();
    }

    private ExerciseCatalog catalog() {
        ExerciseCatalog.ExerciseItem active = ExerciseCatalog.ExerciseItem.builder()
                .id("bench")
                .name("Bench")
                .sortOrder(1)
                .active(true)
                .build();
        ExerciseCatalog.ExerciseItem inactive = ExerciseCatalog.ExerciseItem.builder()
                .id("old")
                .name("Old")
                .sortOrder(0)
                .active(false)
                .build();
        return ExerciseCatalog.builder()
                .version(1)
                .locale("vi-VN")
                .active(true)
                .groups(List.of(
                        ExerciseCatalog.MuscleGroup.builder()
                                .slug("back")
                                .name("Back")
                                .sortOrder(20)
                                .subGroups(List.of())
                                .build(),
                        ExerciseCatalog.MuscleGroup.builder()
                                .slug("chest")
                                .name("Chest")
                                .sortOrder(10)
                                .subGroups(List.of(ExerciseCatalog.SubMuscleGroup.builder()
                                        .slug("mid")
                                        .name("Mid")
                                        .sortOrder(10)
                                        .exercises(List.of(inactive, active))
                                        .build()))
                                .build()))
                .build();
    }
}
