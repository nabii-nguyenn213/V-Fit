class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
  });

  final String id;
  final String name;
  final String? description;
  final String? iconUrl;

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      iconUrl: json['iconUrl']?.toString(),
    );
  }
}

class ChallengeModel {
  const ChallengeModel({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.xpReward,
    required this.active,
    this.description,
    this.badgeName,
  });

  final String id;
  final String title;
  final String? description;
  final int targetValue;
  final int xpReward;
  final String? badgeName;
  final bool active;

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 0,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      badgeName: json['badgeName']?.toString(),
      active: json['active'] != false,
    );
  }
}
