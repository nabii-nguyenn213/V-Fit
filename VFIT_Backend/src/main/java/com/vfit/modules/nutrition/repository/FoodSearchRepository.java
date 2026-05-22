package com.vfit.modules.nutrition.repository;

import com.vfit.modules.nutrition.entity.Food;
import java.util.List;

public interface FoodSearchRepository {
    List<Food> searchByKeyword(String keyword, int limit);
}
