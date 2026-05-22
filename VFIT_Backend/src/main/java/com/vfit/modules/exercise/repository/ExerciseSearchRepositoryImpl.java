package com.vfit.modules.exercise.repository;

import com.vfit.common.enums.DifficultyLevel;
import com.vfit.modules.exercise.document.Exercise;
import java.util.ArrayList;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;
import org.springframework.util.StringUtils;

@Repository
@RequiredArgsConstructor
public class ExerciseSearchRepositoryImpl implements ExerciseSearchRepository {
    private final MongoTemplate mongoTemplate;

    @Override
    public Page<Exercise> search(String muscleGroup, DifficultyLevel difficulty, String keyword, Pageable pageable) {
        Query query = new Query();
        List<Criteria> criteria = new ArrayList<>();
        if (StringUtils.hasText(muscleGroup)) {
            criteria.add(Criteria.where("muscleGroup").regex("^" + java.util.regex.Pattern.quote(muscleGroup.trim()) + "$", "i"));
        }
        if (difficulty != null) {
            criteria.add(Criteria.where("difficulty").is(difficulty));
        }
        if (StringUtils.hasText(keyword)) {
            criteria.add(Criteria.where("name").regex(java.util.regex.Pattern.quote(keyword.trim()), "i"));
        }
        if (!criteria.isEmpty()) {
            query.addCriteria(new Criteria().andOperator(criteria.toArray(Criteria[]::new)));
        }
        long total = mongoTemplate.count(query, Exercise.class);
        List<Exercise> content = mongoTemplate.find(query.with(pageable), Exercise.class);
        return new PageImpl<>(content, pageable, total);
    }
}
