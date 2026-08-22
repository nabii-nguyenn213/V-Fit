import 'package:flutter_test/flutter_test.dart';
import 'package:vfit_frontend/core/utils/enum_parsers.dart';
import 'package:vfit_frontend/features/profile/data/models/user_model.dart';

UserModel _user({
  SubscriptionStatus subscriptionStatus = SubscriptionStatus.active,
  String? subscriptionPlanCode,
  String? premiumPlan,
  DateTime? premiumExpiredAt,
  bool premiumActive = true,
  bool canRenewPremium = false,
}) {
  return UserModel(
    id: 'user-id',
    email: 'user@example.com',
    fullName: 'Người dùng',
    role: RoleName.user,
    onboardingStatus: OnboardingStatus.completed,
    active: true,
    xp: 0,
    level: 1,
    subscriptionStatus: subscriptionStatus,
    subscriptionPlanCode: subscriptionPlanCode,
    premiumActive: premiumActive,
    premiumPlan: premiumPlan,
    premiumExpiredAt: premiumExpiredAt,
    canRenewPremium: canRenewPremium,
  );
}

void main() {
  group('VIP Trial', () {
    test('hiển thị đúng nhãn gói', () {
      expect(
        subscriptionLabel(SubscriptionStatus.active, 'VIP_TRIAL'),
        'Vip Trial',
      );
    });

    test('nhận diện mã gói từ premiumPlan hoặc subscriptionPlanCode', () {
      expect(_user(premiumPlan: ' vip_trial ').isVipTrial, isTrue);
      expect(
        _user(subscriptionPlanCode: 'VIP_TRIAL').isVipTrial,
        isTrue,
      );
    });

    test('cho phép nâng cấp khi trial đang hoạt động dù chưa được gia hạn', () {
      final trialUser = _user(
        subscriptionPlanCode: 'VIP_TRIAL',
        premiumPlan: 'VIP_TRIAL',
        premiumExpiredAt: DateTime.now().add(const Duration(days: 10)),
      );

      expect(trialUser.isVipActive, isTrue);
      expect(trialUser.canRenewVip, isFalse);
      expect(trialUser.canPurchasePremium, isTrue);
    });

    test('giữ nguyên quy tắc gia hạn cho VIP trả phí đang hoạt động', () {
      final expiresLater = DateTime.now().add(const Duration(days: 10));
      final nonRenewablePaidUser = _user(
        subscriptionPlanCode: 'VIP_MONTHLY',
        premiumPlan: 'MONTHLY',
        premiumExpiredAt: expiresLater,
      );
      final renewablePaidUser = _user(
        subscriptionPlanCode: 'VIP_MONTHLY',
        premiumPlan: 'MONTHLY',
        premiumExpiredAt: expiresLater,
        canRenewPremium: true,
      );

      expect(nonRenewablePaidUser.isVipTrial, isFalse);
      expect(nonRenewablePaidUser.canRenewVip, isFalse);
      expect(nonRenewablePaidUser.canPurchasePremium, isFalse);
      expect(renewablePaidUser.canRenewVip, isTrue);
      expect(renewablePaidUser.canPurchasePremium, isTrue);
    });
  });
}
