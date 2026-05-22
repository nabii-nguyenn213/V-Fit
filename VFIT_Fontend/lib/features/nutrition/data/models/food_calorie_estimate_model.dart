class FoodCalorieEstimateModel {
  const FoodCalorieEstimateModel({
    required this.foodName,
    required this.servingSize,
    required this.calories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    required this.confidence,
    required this.notes,
    required this.estimatedAt,
  });

  final String foodName;
  final String servingSize;
  final int calories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final double confidence;
  final List<String> notes;
  final DateTime? estimatedAt;

  factory FoodCalorieEstimateModel.fromJson(Map<String, dynamic> json) {
    return FoodCalorieEstimateModel(
      foodName: json['foodName']?.toString() ?? 'Unknown food',
      servingSize: json['servingSize']?.toString() ?? '1 serving',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble() ?? 0,
      carbGrams: (json['carbGrams'] as num?)?.toDouble() ?? 0,
      fatGrams: (json['fatGrams'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      notes: (json['notes'] as List?)
              ?.map((note) => note.toString())
              .toList(growable: false) ??
          const [],
      estimatedAt: DateTime.tryParse(json['estimatedAt']?.toString() ?? ''),
    );
  }
}
