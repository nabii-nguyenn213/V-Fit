import '../../../../core/utils/enum_parsers.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.onboardingStatus,
    required this.active,
    required this.xp,
    required this.level,
    required this.subscriptionStatus,
    this.subscriptionPlanCode,
    this.premiumActive = false,
    this.premiumPlan,
    this.premiumStartedAt,
    this.premiumExpiredAt,
    this.premiumRemainingDays = 0,
    this.canRenewPremium = true,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    this.goalType,
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final GoalType? goalType;
  final RoleName role;
  final OnboardingStatus onboardingStatus;
  final bool active;
  final int xp;
  final int level;
  final SubscriptionStatus subscriptionStatus;
  final String? subscriptionPlanCode;
  final bool premiumActive;
  final String? premiumPlan;
  final DateTime? premiumStartedAt;
  final DateTime? premiumExpiredAt;
  final int premiumRemainingDays;
  final bool canRenewPremium;
  final DateTime? createdAt;

  bool get isAdmin => role == RoleName.admin;
  bool get isOnboardingCompleted =>
      onboardingStatus == OnboardingStatus.completed;
  bool get hasVipPlan {
    final plan = (premiumPlan ?? subscriptionPlanCode)?.toUpperCase();
    return plan == 'VIP_MONTHLY' ||
        plan == 'VIP_YEARLY' ||
        plan == 'MONTHLY' ||
        plan == 'YEARLY';
  }

  bool get isVipActive {
    final expiredAt = premiumExpiredAt;
    if (premiumActive &&
        expiredAt != null &&
        expiredAt.isAfter(DateTime.now())) {
      return true;
    }
    if (subscriptionStatus == SubscriptionStatus.active && hasVipPlan) {
      return expiredAt == null || expiredAt.isAfter(DateTime.now());
    }
    return false;
  }

  bool get canRenewVip {
    if (!isVipActive) {
      return true;
    }
    final expiredAt = premiumExpiredAt;
    if (expiredAt == null) {
      return false;
    }
    return canRenewPremium ||
        expiredAt.difference(DateTime.now()) < const Duration(days: 3);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      gender: genderFromJson(json['gender']?.toString()),
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      goalType: goalTypeFromJson(json['goalType']?.toString()),
      role: roleNameFromJson(json['role']?.toString()),
      onboardingStatus: onboardingStatusFromJson(
        json['onboardingStatus']?.toString(),
      ),
      active: json['active'] == true,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      subscriptionStatus:
          subscriptionStatusFromJson(json['subscriptionStatus']?.toString()),
      subscriptionPlanCode: json['subscriptionPlanCode']?.toString(),
      premiumActive: json['premiumActive'] == true,
      premiumPlan: json['premiumPlan']?.toString() ??
          json['subscriptionPlanCode']?.toString(),
      premiumStartedAt:
          DateTime.tryParse(json['premiumStartedAt']?.toString() ?? ''),
      premiumExpiredAt:
          DateTime.tryParse(json['premiumExpiredAt']?.toString() ?? ''),
      premiumRemainingDays:
          (json['premiumRemainingDays'] as num?)?.toInt() ?? 0,
      canRenewPremium: json['canRenewPremium'] != false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.fullName,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    this.goalType,
    this.heightCm,
    this.weightKg,
    this.bodyFatPercent,
  });

  final String? fullName;
  final String? avatarUrl;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final GoalType? goalType;
  final double? heightCm;
  final double? weightKg;
  final double? bodyFatPercent;

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'fullName': fullName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (gender != null) 'gender': genderToJson(gender),
      if (dateOfBirth != null)
        'dateOfBirth': dateOfBirth!.toIso8601String().split('T').first,
      if (goalType != null) 'goalType': goalTypeToJson(goalType),
      if (heightCm != null) 'heightCm': heightCm,
      if (weightKg != null) 'weightKg': weightKg,
      if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
    };
  }
}

class BodyMetricModel {
  const BodyMetricModel({
    this.heightCm,
    this.weightKg,
    this.bodyFatPercent,
    this.bmi,
    this.measuredAt,
  });

  final double? heightCm;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? bmi;
  final DateTime? measuredAt;

  factory BodyMetricModel.fromJson(Map<String, dynamic> json) {
    return BodyMetricModel(
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      measuredAt: DateTime.tryParse(json['measuredAt']?.toString() ?? ''),
    );
  }
}
