class VerifiedPhotoModel {
  final String photoId;
  final String photoUrl;
  final DateTime uploadedAt;
  final String checkinDate;
  final int challengeDayIndex;
  final String status;

  VerifiedPhotoModel({
    required this.photoId,
    required this.photoUrl,
    required this.uploadedAt,
    required this.checkinDate,
    required this.challengeDayIndex,
    required this.status,
  });

  factory VerifiedPhotoModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.parse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is Map && val[r'$date'] != null) {
        return DateTime.parse(val[r'$date']);
      }
      return DateTime.now();
    }

    return VerifiedPhotoModel(
      photoId: json['photoId'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      uploadedAt: parseDate(json['uploadedAt']),
      checkinDate: json['checkinDate'] ?? '',
      challengeDayIndex: json['challengeDayIndex'] ?? 0,
      status: json['status'] ?? 'VERIFIED',
    );
  }
}

class ParticipationModel {
  final String id;
  final String userId;
  final String challengeId;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int currentStreak;
  final int maxStreakAchieved;
  final String? lastCheckinDate;
  final List<VerifiedPhotoModel> verifiedPhotos;

  ParticipationModel({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.currentStreak,
    required this.maxStreakAchieved,
    this.lastCheckinDate,
    required this.verifiedPhotos,
  });

  factory ParticipationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.parse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is Map && val[r'$date'] != null) {
        return DateTime.parse(val[r'$date']);
      }
      return DateTime.now();
    }

    DateTime? parseDateNullable(dynamic val) {
      if (val == null) return null;
      return parseDate(val);
    }

    return ParticipationModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      challengeId: json['challengeId'] ?? '',
      status: json['status'] ?? 'IN_PROGRESS',
      startedAt: parseDate(json['startedAt']),
      completedAt: parseDateNullable(json['completedAt']),
      currentStreak: json['currentStreak'] ?? 0,
      maxStreakAchieved: json['maxStreakAchieved'] ?? 0,
      lastCheckinDate: json['lastCheckinDate'],
      verifiedPhotos: (json['verifiedPhotos'] as List? ?? [])
          .map((item) => VerifiedPhotoModel.fromJson(item))
          .toList(),
    );
  }
}
