import 'package:equatable/equatable.dart';

class Food extends Equatable {
  const Food({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.servingSizeGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.isGymFriendly,
    required this.searchCount,
    required this.popularityScore,
  });

  final String id;
  final String name;
  final String normalizedName;
  final double servingSizeGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final bool isGymFriendly;
  final int searchCount;
  final int popularityScore;

  double get _servingDivisor => servingSizeGrams <= 0 ? 100 : servingSizeGrams;

  double caloriesFor(double grams) => grams / _servingDivisor * calories;
  double proteinFor(double grams) => grams / _servingDivisor * protein;
  double carbsFor(double grams) => grams / _servingDivisor * carbs;
  double fatFor(double grams) => grams / _servingDivisor * fat;

  @override
  List<Object?> get props => [
        id,
        name,
        normalizedName,
        servingSizeGrams,
        calories,
        protein,
        carbs,
        fat,
        caloriesPer100g,
        proteinPer100g,
        carbsPer100g,
        fatPer100g,
        isGymFriendly,
        searchCount,
        popularityScore,
      ];
}
