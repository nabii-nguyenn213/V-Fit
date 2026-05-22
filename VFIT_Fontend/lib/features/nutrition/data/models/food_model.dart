import '../../domain/entities/food.dart';

class FoodModel extends Food {
  const FoodModel({
    required super.id,
    required super.name,
    required super.normalizedName,
    required super.servingSizeGrams,
    required super.calories,
    required super.protein,
    required super.carbs,
    required super.fat,
    required super.caloriesPer100g,
    required super.proteinPer100g,
    required super.carbsPer100g,
    required super.fatPer100g,
    required super.isGymFriendly,
    required super.searchCount,
    required super.popularityScore,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      normalizedName: json['normalized_name']?.toString() ??
          json['normalizedName']?.toString() ??
          '',
      servingSizeGrams: _toDouble(
        json['serving_size_grams'] ?? json['servingSizeGrams'] ?? 100,
      ),
      calories: _toDouble(json['calories'] ?? json['calories_per_100g']),
      protein: _toDouble(json['protein'] ?? json['protein_per_100g']),
      carbs: _toDouble(json['carbs'] ?? json['carbs_per_100g']),
      fat: _toDouble(json['fat'] ?? json['fat_per_100g']),
      caloriesPer100g: _toDouble(json['calories_per_100g']),
      proteinPer100g: _toDouble(json['protein_per_100g']),
      carbsPer100g: _toDouble(json['carbs_per_100g']),
      fatPer100g: _toDouble(json['fat_per_100g']),
      isGymFriendly: json['is_gym_friendly'] == true,
      searchCount: _toInt(json['search_count']),
      popularityScore: _toInt(json['popularity_score']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'normalized_name': normalizedName,
      'serving_size_grams': servingSizeGrams,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'is_gym_friendly': isGymFriendly,
      'search_count': searchCount,
      'popularity_score': popularityScore,
    };
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
