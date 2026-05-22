db.foods.createIndex({ name: 1 }, { name: "idx_food_name" });
db.foods.createIndex({ normalized_name: 1 }, { name: "idx_food_normalized_name" });
db.foods.createIndex(
  { is_gym_friendly: -1, popularity_score: -1 },
  { name: "idx_food_gym_friendly_popularity" }
);
