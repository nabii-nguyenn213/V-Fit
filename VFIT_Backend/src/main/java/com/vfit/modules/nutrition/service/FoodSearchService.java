package com.vfit.modules.nutrition.service;

import com.vfit.modules.nutrition.dto.FoodResponse;
import java.util.List;

public interface FoodSearchService {
    List<FoodResponse> search(String keyword, int page, int size);
}
