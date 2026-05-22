enum RoleName { user, admin }

enum Gender { male, female, other }

enum GoalType {
  loseWeight,
  gainMuscle,
  maintain,
  improveEndurance,
  improveMobility,
}

enum DifficultyLevel { beginner, intermediate, advanced }

enum SubscriptionStatus { free, active, expired, canceled }

enum OnboardingStatus { pending, completed }

RoleName roleNameFromJson(String? value) {
  return switch (value) {
    'ADMIN' => RoleName.admin,
    _ => RoleName.user,
  };
}

String roleNameToJson(RoleName value) {
  return switch (value) {
    RoleName.user => 'USER',
    RoleName.admin => 'ADMIN',
  };
}

Gender? genderFromJson(String? value) {
  return switch (value) {
    'MALE' => Gender.male,
    'FEMALE' => Gender.female,
    'OTHER' => Gender.other,
    _ => null,
  };
}

String? genderToJson(Gender? value) {
  return switch (value) {
    Gender.male => 'MALE',
    Gender.female => 'FEMALE',
    Gender.other => 'OTHER',
    null => null,
  };
}

GoalType? goalTypeFromJson(String? value) {
  return switch (value) {
    'LOSE_WEIGHT' => GoalType.loseWeight,
    'GAIN_MUSCLE' => GoalType.gainMuscle,
    'MAINTAIN' => GoalType.maintain,
    'IMPROVE_ENDURANCE' => GoalType.improveEndurance,
    'IMPROVE_MOBILITY' => GoalType.improveMobility,
    _ => null,
  };
}

String? goalTypeToJson(GoalType? value) {
  return switch (value) {
    GoalType.loseWeight => 'LOSE_WEIGHT',
    GoalType.gainMuscle => 'GAIN_MUSCLE',
    GoalType.maintain => 'MAINTAIN',
    GoalType.improveEndurance => 'IMPROVE_ENDURANCE',
    GoalType.improveMobility => 'IMPROVE_MOBILITY',
    null => null,
  };
}

DifficultyLevel difficultyLevelFromJson(String? value) {
  return switch (value) {
    'INTERMEDIATE' => DifficultyLevel.intermediate,
    'ADVANCED' => DifficultyLevel.advanced,
    _ => DifficultyLevel.beginner,
  };
}

String difficultyLevelToJson(DifficultyLevel value) {
  return switch (value) {
    DifficultyLevel.beginner => 'BEGINNER',
    DifficultyLevel.intermediate => 'INTERMEDIATE',
    DifficultyLevel.advanced => 'ADVANCED',
  };
}

SubscriptionStatus subscriptionStatusFromJson(String? value) {
  return switch (value) {
    'ACTIVE' => SubscriptionStatus.active,
    'EXPIRED' => SubscriptionStatus.expired,
    'CANCELED' => SubscriptionStatus.canceled,
    _ => SubscriptionStatus.free,
  };
}

OnboardingStatus onboardingStatusFromJson(String? value) {
  return switch (value) {
    'COMPLETED' => OnboardingStatus.completed,
    _ => OnboardingStatus.pending,
  };
}

String roleLabel(RoleName value) {
  return switch (value) {
    RoleName.user => 'Customer',
    RoleName.admin => 'Admin',
  };
}

String subscriptionLabel(SubscriptionStatus status, String? planCode) {
  if (status != SubscriptionStatus.active) {
    return 'MIEN PHI';
  }
  return switch (planCode) {
    'VIP_MONTHLY' => 'VIP thang',
    'VIP_YEARLY' => 'VIP nam',
    _ => 'VIP',
  };
}

String genderLabel(Gender value) {
  return switch (value) {
    Gender.male => 'Nam',
    Gender.female => 'Nu',
    Gender.other => 'Khac',
  };
}

String goalLabel(GoalType value) {
  return switch (value) {
    GoalType.loseWeight => 'Giam can',
    GoalType.gainMuscle => 'Tang co',
    GoalType.maintain => 'Duy tri voc dang',
    GoalType.improveEndurance => 'Cai thien suc ben',
    GoalType.improveMobility => 'Tang do linh hoat',
  };
}

String difficultyLabel(DifficultyLevel value) {
  return switch (value) {
    DifficultyLevel.beginner => 'Nguoi moi',
    DifficultyLevel.intermediate => 'Trung binh',
    DifficultyLevel.advanced => 'Nang cao',
  };
}
