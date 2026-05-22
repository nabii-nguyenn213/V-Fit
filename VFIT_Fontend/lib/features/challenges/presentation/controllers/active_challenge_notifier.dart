import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/challenge_model.dart';
import '../../data/models/participation_model.dart';
import '../../data/repositories/challenge_repository.dart';

class ActiveChallengeState {
  final List<ParticipationModel> activeParticipations;
  final List<ChallengeModel> allChallenges;
  final bool isLoading;
  final String? errorMessage;

  ActiveChallengeState({
    required this.activeParticipations,
    required this.allChallenges,
    required this.isLoading,
    this.errorMessage,
  });

  factory ActiveChallengeState.initial() {
    return ActiveChallengeState(
      activeParticipations: [],
      allChallenges: [],
      isLoading: false,
    );
  }

  ActiveChallengeState copyWith({
    List<ParticipationModel>? activeParticipations,
    List<ChallengeModel>? allChallenges,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ActiveChallengeState(
      activeParticipations: activeParticipations ?? this.activeParticipations,
      allChallenges: allChallenges ?? this.allChallenges,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  // Business logic checks
  bool get isMilestoneDay {
    if (activeParticipations.isEmpty) return false;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final participation in activeParticipations) {
      if (participation.status != 'IN_PROGRESS') continue;

      // Find challenge configurations
      final challenge = allChallenges.firstWhere(
        (c) => c.id == participation.challengeId,
        orElse: () => ChallengeModel(
          id: participation.challengeId,
          title: 'Thử thách',
          description: '',
          active: true,
          durationDays: 30,
          requiredPhotoMilestones: [1, 5, 10, 15, 20, 25, 30],
          rewards: null,
          type: ChallengeType.STREAK,
        ),
      );

      final startDate = participation.startedAt;
      final daysDiff = now.difference(startDate).inDays;
      final dayIndex = daysDiff + 1;

      // Check if today is a required milestone
      final isRequired = challenge.requiredPhotoMilestones.contains(dayIndex);
      if (isRequired) {
        // Check if photo is already submitted today
        final hasPhoto = participation.verifiedPhotos.any((p) => p.checkinDate == todayStr);
        if (!hasPhoto) {
          return true;
        }
      }
    }
    return false;
  }

  String get activeChallengeTitle {
    if (activeParticipations.isEmpty) return 'Thử thách';
    for (final p in activeParticipations) {
      if (p.status == 'IN_PROGRESS') {
        final challenge = allChallenges.firstWhere(
          (c) => c.id == p.challengeId,
          orElse: () => ChallengeModel(
            id: p.challengeId,
            title: 'Kỷ luật V-FIT',
            description: '',
            active: true,
            durationDays: 30,
            requiredPhotoMilestones: [],
            type: ChallengeType.STREAK,
          ),
        );
        return challenge.title;
      }
    }
    return 'Kỷ luật V-FIT';
  }
}

final activeChallengeNotifierProvider =
    StateNotifierProvider.autoDispose<ActiveChallengeNotifier, ActiveChallengeState>((ref) {
  final repo = ref.watch(challengeRepositoryProvider);
  final notifier = ActiveChallengeNotifier(repo);
  notifier.loadActiveChallengeData();
  return notifier;
});

class ActiveChallengeNotifier extends StateNotifier<ActiveChallengeState> {
  ActiveChallengeNotifier(this._repository) : super(ActiveChallengeState.initial());

  final ChallengeRepository _repository;

  Future<void> loadActiveChallengeData() async {
    state = state.copyWith(isLoading: true);
    try {
      final participations = await _repository.getActiveParticipations();
      final challengesPage = await _repository.getActiveChallenges(page: 0, size: 50);
      
      state = state.copyWith(
        activeParticipations: participations,
        allChallenges: challengesPage.content,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> joinChallenge(String challengeId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.joinChallenge(challengeId);
      await loadActiveChallengeData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> reviveStreak(String challengeId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.reviveStreak(challengeId);
      await loadActiveChallengeData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
