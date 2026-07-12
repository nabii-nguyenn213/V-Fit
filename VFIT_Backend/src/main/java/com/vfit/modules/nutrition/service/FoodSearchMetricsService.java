package com.vfit.modules.nutrition.service;

import com.vfit.modules.nutrition.entity.Food;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class FoodSearchMetricsService {
    private final MongoTemplate mongoTemplate;

    @Async("visitorLogExecutor")
    public void incrementSearchCount(List<String> matchedIds) {
        if (matchedIds == null || matchedIds.isEmpty()) {
            return;
        }
        Query query = new Query(Criteria.where("id").in(matchedIds));
        Update update = new Update().inc("searchCount", 1);
        mongoTemplate.updateMulti(query, update, Food.class);
    }
}
