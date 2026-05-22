import '../entities/food.dart';
import '../repositories/food_repository.dart';

class RememberFood {
  const RememberFood(this._repository);

  final FoodRepository _repository;

  Future<void> call(Food food) {
    return _repository.rememberFood(food);
  }
}
