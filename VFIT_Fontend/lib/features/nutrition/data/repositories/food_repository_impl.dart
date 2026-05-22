import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../models/food_model.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepositoryImpl(ref.watch(dioProvider));
});

class FoodRepositoryImpl implements FoodRepository {
  const FoodRepositoryImpl(this._dio);

  static const _cacheBoxName = 'nutrition_frequent_foods_v1';
  static const _maxCachedFoods = 20;
  static const _starterFoods = [
    FoodModel(
      id: 'food-chicken-breast-fillet',
      name: 'Ức gà phi lê',
      normalizedName: 'uc ga phi le',
      servingSizeGrams: 100,
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 3.6,
      caloriesPer100g: 165,
      proteinPer100g: 31,
      carbsPer100g: 0,
      fatPer100g: 3.6,
      isGymFriendly: true,
      searchCount: 18420,
      popularityScore: 980,
    ),
    FoodModel(
      id: 'food-whole-egg',
      name: 'Trứng gà toàn phần',
      normalizedName: 'trung ga toan phan',
      servingSizeGrams: 100,
      calories: 143,
      protein: 12.6,
      carbs: 0.7,
      fat: 9.5,
      caloriesPer100g: 143,
      proteinPer100g: 12.6,
      carbsPer100g: 0.7,
      fatPer100g: 9.5,
      isGymFriendly: true,
      searchCount: 16240,
      popularityScore: 940,
    ),
    FoodModel(
      id: 'food-brown-rice',
      name: 'Gạo lứt',
      normalizedName: 'gao lut',
      servingSizeGrams: 100,
      calories: 111,
      protein: 2.6,
      carbs: 23,
      fat: 0.9,
      caloriesPer100g: 111,
      proteinPer100g: 2.6,
      carbsPer100g: 23,
      fatPer100g: 0.9,
      isGymFriendly: true,
      searchCount: 14310,
      popularityScore: 900,
    ),
    FoodModel(
      id: 'food-beef-tenderloin',
      name: 'Thịt bò thăn',
      normalizedName: 'thit bo than',
      servingSizeGrams: 100,
      calories: 190,
      protein: 29,
      carbs: 0,
      fat: 7.6,
      caloriesPer100g: 190,
      proteinPer100g: 29,
      carbsPer100g: 0,
      fatPer100g: 7.6,
      isGymFriendly: true,
      searchCount: 12880,
      popularityScore: 870,
    ),
    FoodModel(
      id: 'food-whey-isolate',
      name: 'Whey Protein cô lập',
      normalizedName: 'whey protein co lap',
      servingSizeGrams: 100,
      calories: 370,
      protein: 88,
      carbs: 3,
      fat: 1,
      caloriesPer100g: 370,
      proteinPer100g: 88,
      carbsPer100g: 3,
      fatPer100g: 1,
      isGymFriendly: true,
      searchCount: 21400,
      popularityScore: 995,
    ),
  ];

  final Dio _dio;

  @override
  Future<List<Food>> searchFoods(
    String keyword, {
    int page = 0,
    int size = 6,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.foodSearch,
        queryParameters: {
          'keyword': keyword.trim(),
          'page': page,
          'size': size,
        },
      );
      final rawItems = response.data is List
          ? response.data as List
          : (response.data as Map?)?['data'] as List? ?? const [];
      final foods = rawItems
          .map((item) => FoodModel.fromJson(Map<String, dynamic>.from(item)))
          .where((food) => food.id.isNotEmpty && food.name.isNotEmpty)
          .toList();
      if (foods.isEmpty && keyword.trim().isEmpty) {
        return _localFoods(keyword, page: page, size: size);
      }
      return foods;
    } on DioException {
      final cached = await frequentlyUsedFoods(keyword: keyword);
      if (cached.isNotEmpty) {
        return cached;
      }
      final localFoods = _localFoods(keyword, page: page, size: size);
      if (localFoods.isNotEmpty || keyword.trim().isEmpty) {
        return localFoods;
      }
      return const [];
    }
  }

  @override
  Future<void> rememberFood(Food food) async {
    final box = await _box();
    final stored = FoodModel(
      id: food.id,
      name: food.name,
      normalizedName: food.normalizedName,
      servingSizeGrams: food.servingSizeGrams,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      caloriesPer100g: food.caloriesPer100g,
      proteinPer100g: food.proteinPer100g,
      carbsPer100g: food.carbsPer100g,
      fatPer100g: food.fatPer100g,
      isGymFriendly: food.isGymFriendly,
      searchCount: food.searchCount + 1,
      popularityScore: food.popularityScore,
    );
    await box.put(stored.id, {
      ...stored.toJson(),
      'last_selected_at': DateTime.now().millisecondsSinceEpoch,
      'local_clicks':
          ((box.get(stored.id) as Map?)?['local_clicks'] as int? ?? 0) + 1,
    });
    await _trimCache(box);
  }

  @override
  Future<List<Food>> frequentlyUsedFoods({String keyword = ''}) async {
    final box = await _box();
    final normalizedKeyword = keyword.trim().toLowerCase();
    final items = box.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
      if (normalizedKeyword.isEmpty) {
        return true;
      }
      return (item['name']?.toString().toLowerCase() ?? '')
          .contains(normalizedKeyword);
    }).toList()
      ..sort((a, b) {
        final clickCompare = ((b['local_clicks'] as int?) ?? 0)
            .compareTo((a['local_clicks'] as int?) ?? 0);
        if (clickCompare != 0) {
          return clickCompare;
        }
        return ((b['last_selected_at'] as int?) ?? 0)
            .compareTo((a['last_selected_at'] as int?) ?? 0);
      });
    return items.take(_maxCachedFoods).map(FoodModel.fromJson).toList();
  }

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(_cacheBoxName)) {
      return Hive.box<dynamic>(_cacheBoxName);
    }
    return Hive.openBox<dynamic>(_cacheBoxName);
  }

  Future<void> _trimCache(Box<dynamic> box) async {
    if (box.length <= _maxCachedFoods) {
      return;
    }
    final entries = box.keys.map((key) {
      final item = Map<String, dynamic>.from(box.get(key) as Map);
      return MapEntry(key, (item['last_selected_at'] as int?) ?? 0);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in entries.skip(_maxCachedFoods)) {
      await box.delete(entry.key);
    }
  }

  List<Food> _localFoods(String keyword, {int page = 0, int size = 10}) {
    final normalizedKeyword = _normalize(keyword);
    if (normalizedKeyword.isEmpty) {
      final sortedFoods = [..._starterFoods]..sort(
          (a, b) => b.popularityScore.compareTo(a.popularityScore),
        );
      return sortedFoods.skip(page * size).take(size).toList();
    }
    return _starterFoods
        .where((food) => food.normalizedName.startsWith(normalizedKeyword))
        .toList();
  }

  String _normalize(String value) {
    const vietnameseMarks = {
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
      'đ': 'd',
    };
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(vietnameseMarks[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
