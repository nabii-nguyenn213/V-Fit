import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ai_planners_repository.dart';

class AiFoodScannerState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;

  const AiFoodScannerState({
    required this.isLoading,
    this.error,
    this.result,
  });

  AiFoodScannerState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? result,
  }) {
    return AiFoodScannerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }
}

class AiFoodScannerNotifier extends StateNotifier<AiFoodScannerState> {
  final Ref _ref;

  AiFoodScannerNotifier(this._ref)
      : super(const AiFoodScannerState(isLoading: false));

  Future<void> estimateFood({
    required String foodName,
    required String portion,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(aiPlannersRepositoryProvider);
      final scanResult = await repository.scanFoodText(
        foodName: foodName,
        portion: portion,
      );

      state = state.copyWith(isLoading: false, result: scanResult);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const AiFoodScannerState(isLoading: false);
  }
}

final aiFoodScannerProvider =
    StateNotifierProvider.autoDispose<AiFoodScannerNotifier, AiFoodScannerState>((ref) {
  return AiFoodScannerNotifier(ref);
});
