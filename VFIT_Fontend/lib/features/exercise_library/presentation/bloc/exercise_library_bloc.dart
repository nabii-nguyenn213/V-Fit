import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_error_mapper.dart';
import '../../../../core/error/crash_reporter.dart';
import '../../domain/entities/exercise_catalog.dart';
import '../../domain/usecases/get_exercise_catalog.dart';

sealed class ExerciseLibraryEvent extends Equatable {
  const ExerciseLibraryEvent();

  @override
  List<Object?> get props => [];
}

class ExerciseLibraryRequested extends ExerciseLibraryEvent {
  const ExerciseLibraryRequested({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class ExerciseLibraryState extends Equatable {
  const ExerciseLibraryState({
    this.catalog,
    this.loading = false,
    this.errorMessage,
  });

  final ExerciseCatalog? catalog;
  final bool loading;
  final String? errorMessage;

  bool get hasData => catalog != null && catalog!.groups.isNotEmpty;

  ExerciseLibraryState copyWith({
    ExerciseCatalog? catalog,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExerciseLibraryState(
      catalog: catalog ?? this.catalog,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [catalog, loading, errorMessage];
}

class ExerciseLibraryBloc
    extends Bloc<ExerciseLibraryEvent, ExerciseLibraryState> {
  ExerciseLibraryBloc(this._getExerciseCatalog)
      : super(const ExerciseLibraryState(loading: true)) {
    on<ExerciseLibraryRequested>(_onRequested);
  }

  final GetExerciseCatalog _getExerciseCatalog;

  Future<void> _onRequested(
    ExerciseLibraryRequested event,
    Emitter<ExerciseLibraryState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final catalog = await _getExerciseCatalog(
        forceRefresh: event.forceRefresh,
      );
      emit(ExerciseLibraryState(catalog: catalog));
    } catch (error, stackTrace) {
      await CrashReporter.record(error, stackTrace);
      emit(
        state.copyWith(
          loading: false,
          errorMessage: AppErrorMapper.friendlyMessage(error),
        ),
      );
    }
  }
}
