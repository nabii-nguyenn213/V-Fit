package com.vfit.modules.nutrition.controller;

import com.vfit.modules.nutrition.dto.FoodResponse;
import com.vfit.modules.nutrition.service.FoodSearchService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/foods")
@RequiredArgsConstructor
public class FoodSearchController {
    private final FoodSearchService foodSearchService;

    @GetMapping("/search")
    public ResponseEntity<List<FoodResponse>> search(
            @RequestParam(required = false, defaultValue = "") String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "6") int size) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(foodSearchService.search(keyword, page, size));
    }
}
