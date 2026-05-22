import '../entities/food.dart';

abstract class FoodRepository {
  Future<List<Food>> searchFoods(String keyword, {int page = 0, int size = 6});
  Future<void> rememberFood(Food food);
  Future<List<Food>> frequentlyUsedFoods({String keyword = ''});
}
