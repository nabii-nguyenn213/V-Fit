/// Food calorie database for offline lookup and estimation
class FoodDatabase {
  // ✨ FIX #5: Comprehensive food database with calorie info
  // Data per 100 grams unless specified
  
  static const Map<String, double> caloriesPerHundredGrams = {
    // Vietnamese staples
    'com': 150,        // rice (plain)
    'com trang': 150,  // white rice
    'com luc': 110,    // brown rice
    'tron': 130,       // mixed rice
    'mi': 140,         // noodles (dry weight)
    'mi tom': 280,     // instant ramen
    'mi gan': 110,     // fresh noodles
    'banh': 265,       // bread
    'banh mi': 265,    // baguette
    'banh mi nuong': 290,  // toasted bread
    'bap': 86,         // corn
    
    // Protein
    'ga': 165,         // chicken (cooked)
    'ga roti': 190,    // roasted chicken
    'ga luoc': 130,    // boiled chicken
    'ca': 120,         // fish (white fish)
    'ca hoi': 208,     // salmon
    'ca tray': 100,    // seabass
    'tom': 99,         // shrimp
    'muc': 92,         // squid
    'thit': 250,       // pork (fatty)
    'thit leo': 250,   // pork shoulder
    'thit nac': 250,   // pork belly
    'thit nai': 130,   // lean pork
    'bo': 250,         // beef (fatty)
    'bo nai': 130,     // lean beef
    'gan': 110,        // liver
    'trung': 155,      // egg (1 egg = 50g)
    'trung ga': 155,   // chicken egg
    
    // Vegetables
    'rau': 30,         // vegetables (generic)
    'ca chua': 18,     // tomato
    'khoai mon': 18,   // cassava leaves
    'spinach': 23,     // spinach
    'ca rot': 41,      // carrot
    'su su': 19,       // chayote
    'dua chuot': 16,   // cucumber
    'su': 13,          // radish
    'khoai lang': 86,  // sweet potato
    'khoai tay': 77,   // potato
    'hanh': 40,        // onion
    'toi': 149,        // garlic
    'sau rieng': 160,  // durian
    'tao': 52,         // apple
    'cam': 47,         // orange
    'chuoi': 89,       // banana
    'day': 30,         // grape
    'dau tay': 120,    // strawberry
    'sau': 44,         // papaya
    'xoai': 60,        // mango
    
    // Oils & Condiments
    'dau': 884,        // oil
    'bo dia': 717,     // butter
    'mayo': 680,       // mayonnaise
    'sot ca chua': 17, // tomato sauce
    'mam tom': 120,    // shrimp paste
    
    // Dairy
    'sua': 61,         // milk
    'sua duong': 49,   // sweetened milk
    'pho mai': 402,    // cheese
    'sua chua': 59,    // yogurt
  };

  // Portion size multipliers
  static const Map<String, double> portionMultipliers = {
    // Vietnamese portions
    'to': 2.0,             // bowl (200-300g)
    'chen': 1.5,           // cup (150g)
    'bat': 1.5,            // small bowl
    'muong': 0.2,          // spoon (20g)
    'muong canh': 0.5,     // tablespoon (50g)
    'tay': 1.0,            // handful (100g)
    'trang': 0.5,          // plate/small serving
    'dia': 1.0,            // plate
    'qua': 1.0,            // piece
    'lat': 0.5,            // slice
    'hop': 2.5,            // box
    'goi': 1.5,            // pack
    'cai': 0.8,            // bunch
    'bap': 0.3,            // cob
    
    // English portions
    'bowl': 2.0,
    'cup': 1.5,
    'spoon': 0.2,
    'tablespoon': 0.5,
    'piece': 1.0,
    'slice': 0.5,
    'serving': 1.0,
    'plate': 1.0,
    'box': 2.5,
    'handful': 1.0,
    'fillet': 1.5,
    'half': 0.5,
  };

  /// Get calories for a food item (per 100g default)
  static double getCaloriesPer100g(String foodName) {
    final normalized = foodName.toLowerCase().trim();
    
    // Exact match
    if (caloriesPerHundredGrams.containsKey(normalized)) {
      return caloriesPerHundredGrams[normalized]!;
    }
    
    // Partial match (contains word)
    for (final entry in caloriesPerHundredGrams.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }
    
    // Default to generic calorie value
    return 100.0;
  }

  /// Get calories for a portion
  static double getCaloriesForPortion(String foodName, String portionType, [double portionMultiplier = 1.0]) {
    final baseCalories = getCaloriesPer100g(foodName);
    final normalized = portionType.toLowerCase().trim();
    
    double sizeMultiplier = 1.0;
    
    // Get portion multiplier
    if (portionMultipliers.containsKey(normalized)) {
      sizeMultiplier = portionMultipliers[normalized]!;
    } else {
      // Try partial match
      for (final entry in portionMultipliers.entries) {
        if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
          sizeMultiplier = entry.value;
          break;
        }
      }
    }
    
    return baseCalories * sizeMultiplier * portionMultiplier / 100.0;
  }

  /// Estimate total nutrition from food name and portion
  static Map<String, dynamic> estimateNutrition(
    String foodName, {
    String portionType = 'serving',
    double portionWeight = 100,
  }) {
    final calories = getCaloriesForPortion(foodName, portionType);
    
    // Estimate macros based on food category
    final normalized = foodName.toLowerCase();
    
    double proteinPercent = 15; // Default ~15% calories from protein
    double carbPercent = 50;    // Default ~50% from carbs
    double fatPercent = 35;     // Default ~35% from fat
    
    // Adjust based on food type
    if (_isProteinFood(normalized)) {
      proteinPercent = 40;
      carbPercent = 5;
      fatPercent = 55;
    } else if (_isVegetable(normalized)) {
      proteinPercent = 20;
      carbPercent = 70;
      fatPercent = 10;
    } else if (_isFruit(normalized)) {
      proteinPercent = 5;
      carbPercent = 90;
      fatPercent = 5;
    } else if (_isGrain(normalized)) {
      proteinPercent = 12;
      carbPercent = 75;
      fatPercent = 13;
    }
    
    // Calculate grams
    final proteinCalories = calories * proteinPercent / 100;
    final carbCalories = calories * carbPercent / 100;
    final fatCalories = calories * fatPercent / 100;
    
    return {
      'food_name': foodName,
      'portion_type': portionType,
      'portion_weight_g': portionWeight,
      'calories': calories.round(),
      'protein_g': (proteinCalories / 4).toStringAsFixed(1),
      'carbs_g': (carbCalories / 4).toStringAsFixed(1),
      'fat_g': (fatCalories / 9).toStringAsFixed(1),
      'fiber_g': _estimateFiber(foodName, portionWeight),
      'sodium_mg': _estimateSodium(foodName, portionWeight),
      'confidence': 0.7, // 70% confidence for database lookup
    };
  }

  static bool _isProteinFood(String food) {
    final proteinFoods = [
      'ga', 'ca', 'tom', 'muc', 'thit', 'bo', 'gan', 'trung', 'sua', 'pho mai'
    ];
    return proteinFoods.any((p) => food.contains(p));
  }

  static bool _isVegetable(String food) {
    final vegFoods = [
      'rau', 'ca chua', 'ca rot', 'dua chuot', 'su', 'khoai mon', 'hanh', 'toi',
      'spinach', 'broccoli', 'lettuce'
    ];
    return vegFoods.any((v) => food.contains(v));
  }

  static bool _isFruit(String food) {
    final fruitFoods = [
      'tao', 'cam', 'chuoi', 'day', 'dau', 'sau', 'xoai', 'dua', 'le', 'cherry'
    ];
    return fruitFoods.any((f) => food.contains(f));
  }

  static bool _isGrain(String food) {
    final grainFoods = [
      'com', 'mi', 'banh', 'bap', 'lua', 'yến mạch'
    ];
    return grainFoods.any((g) => food.contains(g));
  }

  static double _estimateFiber(String food, double weight) {
    // Fiber typically 1-4% of food weight for whole foods
    if (_isVegetable(food) || _isFruit(food) || _isGrain(food)) {
      return double.parse((weight * 0.02).toStringAsFixed(1)); // ~2%
    }
    return 0.0;
  }

  static double _estimateSodium(String food, double weight) {
    // Sodium varies widely; estimate for common foods
    if (food.contains('mam') || food.contains('nuoc mam')) {
      return weight * 10; // High sodium
    }
    if (food.contains('thit') || food.contains('ca')) {
      return weight * 0.8; // Moderate sodium
    }
    return weight * 0.3; // Low sodium for vegetables/fruits
  }

  /// Get all available foods (for autocomplete)
  static List<String> getAllFoods() {
    return caloriesPerHundredGrams.keys.toList();
  }

  /// Get all portion types (for dropdown)
  static List<String> getAllPortionTypes() {
    return portionMultipliers.keys.toList();
  }

  /// Search for similar foods
  static List<String> searchFoods(String query) {
    final normalized = query.toLowerCase().trim();
    
    if (normalized.isEmpty) {
      return [];
    }
    
    return caloriesPerHundredGrams.keys
        .where((food) => food.contains(normalized))
        .toList();
  }
}
