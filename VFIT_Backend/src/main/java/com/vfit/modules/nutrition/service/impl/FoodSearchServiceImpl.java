package com.vfit.modules.nutrition.service.impl;

import com.vfit.modules.nutrition.dto.FoodResponse;
import com.vfit.modules.nutrition.entity.Food;
import com.vfit.modules.nutrition.repository.FoodRepository;
import com.vfit.modules.nutrition.repository.FoodSearchRepository;
import com.vfit.modules.nutrition.service.FoodSearchService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class FoodSearchServiceImpl implements FoodSearchService {
    private static final int SEARCH_LIMIT = 10;

    private final FoodRepository foodRepository;
    private final FoodSearchRepository foodSearchRepository;

    @Override
    public List<FoodResponse> search(String keyword, int page, int size) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.max(1, Math.min(size, 20));
        List<Food> foods = StringUtils.hasText(keyword)
                ? foodSearchRepository.searchByKeyword(keyword, SEARCH_LIMIT)
                : foodRepository.findByIsGymFriendlyTrueOrderByPopularityScoreDesc(
                        PageRequest.of(safePage, safeSize));
        return foods.stream().map(FoodResponse::from).toList();
    }
}
