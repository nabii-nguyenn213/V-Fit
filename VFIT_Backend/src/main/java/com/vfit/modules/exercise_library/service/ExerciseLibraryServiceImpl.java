package com.vfit.modules.exercise_library.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.modules.exercise_library.document.ExerciseCatalog;
import com.vfit.modules.exercise_library.dto.ExerciseCatalogResponse;
import com.vfit.modules.exercise_library.repository.ExerciseCatalogRepository;
import java.time.Duration;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Slf4j
@Service
@RequiredArgsConstructor
public class ExerciseLibraryServiceImpl implements ExerciseLibraryService {
    private static final String CACHE_KEY_PREFIX = "exercise-library:grouped:";

    private final ExerciseCatalogRepository exerciseCatalogRepository;
    private final ExerciseCatalogSeedFactory seedFactory;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    @Value("${app.exercise-library.cache-ttl-seconds:86400}")
    private long cacheTtlSeconds;

    @Value("${app.redis.required:false}")
    private boolean redisRequired;

    @Override
    public ExerciseCatalogResponse grouped(String locale) {
        String normalizedLocale = normalizeLocale(locale);
        String cacheKey = cacheKey(normalizedLocale);
        ExerciseCatalogResponse cached = readCache(cacheKey);
        if (cached != null) {
            return cached;
        }

        ExerciseCatalogResponse response = exerciseCatalogRepository
                .findFirstByLocaleAndActiveTrueOrderByVersionDesc(normalizedLocale)
                .map(this::toResponse)
                .orElseGet(ExerciseCatalogResponse::empty);
        writeCache(cacheKey, response);
        return response;
    }

    @Override
    public ExerciseCatalogResponse seedDefaultCatalog(String locale) {
        String normalizedLocale = normalizeLocale(locale);
        ExerciseCatalog catalog = seedFactory.defaultCatalog(normalizedLocale);
        // Xóa catalog cũ trước để đảm bảo replace hoàn toàn (tránh stale fields)
        if (exerciseCatalogRepository.existsById(catalog.getId())) {
            log.info("[ExerciseLibrary] Deleting old catalog id={} before re-seeding", catalog.getId());
            exerciseCatalogRepository.deleteById(catalog.getId());
        }
        ExerciseCatalog saved = exerciseCatalogRepository.save(catalog);
        log.info("[ExerciseLibrary] Seeded catalog id={} version={} locale={} with {} groups",
                saved.getId(), saved.getVersion(), saved.getLocale(), saved.getGroups().size());
        evictGroupedCache();
        return toResponse(saved);
    }

    @Override
    public void evictGroupedCache() {
        try {
            Set<String> keys = redisTemplate.keys(CACHE_KEY_PREFIX + "*");
            if (keys != null && !keys.isEmpty()) {
                redisTemplate.delete(keys);
            }
        } catch (RedisConnectionFailureException ex) {
            logRedisUnavailable("evicting exercise library cache", ex);
        }
    }

    private ExerciseCatalogResponse readCache(String cacheKey) {
        try {
            String json = redisTemplate.opsForValue().get(cacheKey);
            if (!StringUtils.hasText(json)) {
                return null;
            }
            return objectMapper.readValue(json, ExerciseCatalogResponse.class);
        } catch (RedisConnectionFailureException ex) {
            logRedisUnavailable("reading exercise library cache", ex);
            return null;
        } catch (JsonProcessingException ex) {
            log.warn("Invalid exercise library cache payload for key {}", cacheKey, ex);
            return null;
        }
    }

    private void writeCache(String cacheKey, ExerciseCatalogResponse response) {
        try {
            redisTemplate.opsForValue().set(
                    cacheKey,
                    objectMapper.writeValueAsString(response),
                    Duration.ofSeconds(cacheTtlSeconds));
        } catch (RedisConnectionFailureException ex) {
            logRedisUnavailable("writing exercise library cache", ex);
        } catch (JsonProcessingException ex) {
            log.warn("Unable to serialize exercise library response for cache", ex);
        }
    }

    private ExerciseCatalogResponse toResponse(ExerciseCatalog catalog) {
        List<ExerciseCatalogResponse.MuscleGroupResponse> groups = catalog.getGroups().stream()
                .sorted(Comparator.comparingInt(ExerciseCatalog.MuscleGroup::getSortOrder))
                .map(group -> new ExerciseCatalogResponse.MuscleGroupResponse(
                        group.getSlug(),
                        group.getName(),
                        group.getSubGroups().stream()
                                .sorted(Comparator.comparingInt(ExerciseCatalog.SubMuscleGroup::getSortOrder))
                                .map(subGroup -> new ExerciseCatalogResponse.SubMuscleGroupResponse(
                                        subGroup.getSlug(),
                                        subGroup.getName(),
                                        subGroup.getExercises().stream()
                                                .filter(ExerciseCatalog.ExerciseItem::isActive)
                                                .sorted(Comparator.comparingInt(ExerciseCatalog.ExerciseItem::getSortOrder))
                                                .map(exercise -> new ExerciseCatalogResponse.ExerciseItemResponse(
                                                        exercise.getId(),
                                                        exercise.getName(),
                                                        exercise.getVideoUrl(),
                                                        exercise.getVideoSearchHint(),
                                                        exercise.getDescription(),
                                                        exercise.getEquipment()))
                                                .toList()))
                                .toList()))
                .toList();
        return new ExerciseCatalogResponse(catalog.getVersion(), groups);
    }

    private String normalizeLocale(String locale) {
        return StringUtils.hasText(locale) ? locale.trim() : "vi-VN";
    }

    private String cacheKey(String locale) {
        return CACHE_KEY_PREFIX + locale;
    }

    private void logRedisUnavailable(String action, RedisConnectionFailureException ex) {
        if (redisRequired) {
            log.warn("Redis unavailable while {}: {}", action, ex.getMessage());
            return;
        }
        log.debug("Redis unavailable while {}, using Mongo fallback: {}", action, ex.getMessage());
    }
}
