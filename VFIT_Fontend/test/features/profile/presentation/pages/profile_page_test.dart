import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vfit_frontend/core/network/token_storage.dart';
import 'package:vfit_frontend/core/theme/theme_controller.dart';
import 'package:vfit_frontend/core/utils/enum_parsers.dart';
import 'package:vfit_frontend/features/auth/application/auth_controller.dart';
import 'package:vfit_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:vfit_frontend/features/auth/data/services/social_login_client.dart';
import 'package:vfit_frontend/features/profile/data/models/user_model.dart';
import 'package:vfit_frontend/features/profile/data/repositories/profile_repository.dart';
import 'package:vfit_frontend/features/profile/presentation/pages/profile_page.dart';

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<StoredTokens?> read() async => null;

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
    required int expiresInMs,
  }) async {}
}

class _TestAuthController extends AuthController {
  _TestAuthController(UserModel user)
      : super(
          AuthRepository(Dio(), _FakeTokenStorage()),
          SocialLoginClient(),
        ) {
    setUser(user);
  }
}

class _StubProfileRepository extends ProfileRepository {
  _StubProfileRepository() : super(Dio());

  int bodyMetricsCalls = 0;

  @override
  Future<BodyMetricModel> bodyMetrics() async {
    bodyMetricsCalls++;
    return const BodyMetricModel(
      heightCm: 170,
      weightKg: 65,
      bodyFatPercent: 18,
      bmi: 22.5,
    );
  }
}

const _pendingUser = UserModel(
  id: 'pending-user',
  email: 'pending@example.com',
  fullName: 'Người dùng mới',
  role: RoleName.user,
  onboardingStatus: OnboardingStatus.pending,
  active: false,
  xp: 0,
  level: 1,
  subscriptionStatus: SubscriptionStatus.active,
  subscriptionPlanCode: 'VIP_TRIAL',
  premiumActive: true,
  premiumPlan: 'VIP_TRIAL',
  premiumRemainingDays: 3,
  canRenewPremium: false,
);

void main() {
  testWidgets(
    'hồ sơ chưa hoàn tất thiết lập chỉ hiện lời nhắc và mở onboarding',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _StubProfileRepository();
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const Scaffold(body: ProfilePage()),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) =>
                const Scaffold(body: Text('ONBOARDING_TARGET')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => _TestAuthController(_pendingUser),
            ),
            profileRepositoryProvider.overrideWithValue(repository),
            themeControllerProvider.overrideWith(
              (ref) => ThemeController(false, (_, __) async => true),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hoàn tất thiết lập ban đầu'), findsOneWidget);
      expect(
        find.text(
          'Hiện tại bạn chưa hoàn tất bước thiết lập. Hãy nhấp vào đây để hoàn thành, để chúng tôi chuẩn bị cho bạn một kế hoạch chi tiết nhất nhé.',
        ),
        findsOneWidget,
      );
      expect(find.text('Chỉ số cơ thể'), findsNothing);
      expect(find.text('Chiều cao'), findsNothing);
      expect(find.text('Cân nặng'), findsNothing);
      expect(find.text('Chỉ số BMI'), findsNothing);
      expect(find.text('Tỷ lệ mỡ'), findsNothing);
      expect(repository.bodyMetricsCalls, 0);

      await tester.tap(find.text('Hoàn tất thiết lập'));
      await tester.pumpAndSettle();

      expect(find.text('ONBOARDING_TARGET'), findsOneWidget);
    },
  );
}
