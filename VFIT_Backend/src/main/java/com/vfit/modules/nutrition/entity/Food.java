package com.vfit.modules.nutrition.entity;

import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Field;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "foods")
@CompoundIndex(
        name = "idx_food_gym_friendly_popularity",
        def = "{'is_gym_friendly': -1, 'popularity_score': -1}")
public class Food {
    @Id
    private String id;

    @Indexed(name = "idx_food_name")
    private String name;

    @Field("normalized_name")
    @Indexed(name = "idx_food_normalized_name")
    private String normalizedName;

    @Field("serving_size_grams")
    private double servingSizeGrams;

    private double calories;
    private double protein;
    private double carbs;
    private double fat;

    @Field("calories_per_100g")
    private double caloriesPer100g;
    @Field("protein_per_100g")
    private double proteinPer100g;
    @Field("carbs_per_100g")
    private double carbsPer100g;
    @Field("fat_per_100g")
    private double fatPer100g;
    @Field("is_gym_friendly")
    @JsonAlias({"isGymFriendly", "is_gym_friendly"})
    private boolean isGymFriendly;
    @Field("search_count")
    private int searchCount;
    @Field("popularity_score")
    private int popularityScore;
}
