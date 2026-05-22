package com.vfit.modules.nutrition.repository;

import com.vfit.modules.nutrition.entity.Food;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface FoodRepository extends MongoRepository<Food, String> {
    List<Food> findTop10ByIsGymFriendlyTrueOrderByPopularityScoreDesc();
    List<Food> findByIsGymFriendlyTrueOrderByPopularityScoreDesc(Pageable pageable);
}
