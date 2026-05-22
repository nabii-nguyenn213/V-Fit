enum ChallengeType { STREAK, MILESTONE, TARGETED }

class ChallengeReward {
  final int points;
  final String? badgeId;
  final String? voucherTemplateId;
  final int premiumDaysGranted;

  ChallengeReward({
    required this.points,
    this.badgeId,
    this.voucherTemplateId,
    required this.premiumDaysGranted,
  });

  factory ChallengeReward.fromJson(Map<String, dynamic> json) {
    return ChallengeReward(
      points: json['points'] ?? 0,
      badgeId: json['badgeId'],
      voucherTemplateId: json['voucherTemplateId'],
      premiumDaysGranted: json['premiumDaysGranted'] ?? 0,
    );
  }
}

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final bool active;
  final ChallengeType? type;
  final int durationDays;
  final ChallengeReward? rewards;
  final List<int> requiredPhotoMilestones;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.active,
    this.type,
    required this.durationDays,
    this.rewards,
    required this.requiredPhotoMilestones,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    ChallengeType? parseType(String? val) {
      if (val == 'STREAK') return ChallengeType.STREAK;
      if (val == 'MILESTONE') return ChallengeType.MILESTONE;
      if (val == 'TARGETED') return ChallengeType.TARGETED;
      return null;
    }

    return ChallengeModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? true,
      type: parseType(json['type']),
      durationDays: json['durationDays'] ?? 0,
      rewards: json['rewards'] != null ? ChallengeReward.fromJson(json['rewards']) : null,
      requiredPhotoMilestones: List<int>.from(json['requiredPhotoMilestones'] ?? []),
    );
  }
}
