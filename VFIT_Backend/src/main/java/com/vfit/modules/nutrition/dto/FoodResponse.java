package com.vfit.modules.nutrition.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vfit.modules.nutrition.entity.Food;

public record FoodResponse(
        String id,
        String name,
        @JsonProperty("normalized_name") String normalizedName,
        @JsonProperty("serving_size_grams") double servingSizeGrams,
        double calories,
        double protein,
        double carbs,
        double fat,
        @JsonProperty("calories_per_100g") double caloriesPer100g,
        @JsonProperty("protein_per_100g") double proteinPer100g,
        @JsonProperty("carbs_per_100g") double carbsPer100g,
        @JsonProperty("fat_per_100g") double fatPer100g,
        @JsonProperty("is_gym_friendly") boolean isGymFriendly,
        @JsonProperty("search_count") int searchCount,
        @JsonProperty("popularity_score") int popularityScore) {

    public static FoodResponse from(Food food) {
        return new FoodResponse(
                food.getId(),
                food.getName(),
                food.getNormalizedName(),
                food.getServingSizeGrams(),
                food.getCalories(),
                food.getProtein(),
                food.getCarbs(),
                food.getFat(),
                food.getCaloriesPer100g(),
                food.getProteinPer100g(),
                food.getCarbsPer100g(),
                food.getFatPer100g(),
                food.isGymFriendly(),
                food.getSearchCount(),
                food.getPopularityScore());
    }
}
