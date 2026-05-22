import '../entities/food.dart';
import '../repositories/food_repository.dart';

class SearchFoods {
  const SearchFoods(this._repository);

  final FoodRepository _repository;

  Future<List<Food>> call(String keyword, {int page = 0, int size = 6}) {
    return _repository.searchFoods(keyword, page: page, size: size);
  }
}
