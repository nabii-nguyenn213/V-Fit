import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vfit_frontend/core/network/token_storage.dart';
import 'package:vfit_frontend/core/utils/enum_parsers.dart';
import 'package:vfit_frontend/features/auth/application/auth_controller.dart';
import 'package:vfit_frontend/features/auth/data/models/auth_models.dart';
import 'package:vfit_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:vfit_frontend/features/auth/data/services/social_login_client.dart';
import 'package:vfit_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vfit_frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:vfit_frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:vfit_frontend/features/profile/data/models/user_model.dart';

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

class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository(this.response) : super(Dio(), _FakeTokenStorage());

  final AuthResponse response;

  @override
  Future<AuthResponse> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    return response;
  }

  @override
  Future<AuthResponse> socialLogin(SocialLoginCredential credential) async {
    return response;
  }
}

class _StubSocialLoginClient extends SocialLoginClient {
  @override
  Future<SocialLoginCredential?> signInWithGoogle() async {
    return const SocialLoginCredential(
      provider: SocialLoginProvider.google,
      providerToken: 'provider-token',
      platform: 'android',
    );
  }
}

const _trialUser = UserModel(
  id: 'new-user',
  email: 'new@example.com',
  fullName: 'Người dùng mới',
  role: RoleName.user,
  onboardingStatus: OnboardingStatus.pending,
  active: true,
  xp: 0,
  level: 1,
  subscriptionStatus: SubscriptionStatus.active,
  subscriptionPlanCode: 'VIP_TRIAL',
  premiumActive: true,
  premiumPlan: 'VIP_TRIAL',
  premiumRemainingDays: 3,
  canRenewPremium: false,
);

const _tokens = TokenResponse(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  tokenType: 'Bearer',
  expiresInMs: 900000,
);

void main() {
  test('auth response parses the new-registration signal', () {
    final response = AuthResponse.fromJson({
      'user': <String, dynamic>{},
      'tokens': <String, dynamic>{
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'expiresInMs': 900000,
      },
      'newRegistration': true,
    });

    expect(response.newRegistration, isTrue);
  });

  test('OTP activation queues the trial welcome for a new registration',
      () async {
    const response = AuthResponse(
      user: _trialUser,
      tokens: _tokens,
      newRegistration: true,
    );
    final repository = _StubAuthRepository(response);
    final controller = AuthController(repository, SocialLoginClient());
    final bloc = AuthBloc(
      authRepository: repository,
      authController: controller,
    );
    addTearDown(bloc.close);

    final success = bloc.stream.firstWhere((state) => state is OtpVerifySuccess);
    bloc.add(
      const VerifyOtpSubmitted(
        email: 'new@example.com',
        otpCode: '123456',
      ),
    );
    await success;

    expect(controller.state.trialWelcomePending, isTrue);
    expect(controller.state.user?.isVipTrial, isTrue);

    controller.consumeTrialWelcome();
    expect(controller.state.trialWelcomePending, isFalse);
  });

  test('OTP login without a new-registration signal does not queue welcome',
      () async {
    const response = AuthResponse(user: _trialUser, tokens: _tokens);
    final repository = _StubAuthRepository(response);
    final controller = AuthController(repository, SocialLoginClient());
    final bloc = AuthBloc(
      authRepository: repository,
      authController: controller,
    );
    addTearDown(bloc.close);

    final success = bloc.stream.firstWhere((state) => state is OtpVerifySuccess);
    bloc.add(
      const VerifyOtpSubmitted(
        email: 'new@example.com',
        otpCode: '123456',
      ),
    );
    await success;

    expect(controller.state.trialWelcomePending, isFalse);
  });

  test('new social registration queues the same trial welcome', () async {
    const response = AuthResponse(
      user: _trialUser,
      tokens: _tokens,
      newRegistration: true,
    );
    final repository = _StubAuthRepository(response);
    final controller = AuthController(
      repository,
      _StubSocialLoginClient(),
    );

    await controller.loginWithGoogle();

    expect(controller.state.trialWelcomePending, isTrue);
    expect(controller.state.user?.id, 'new-user');
  });
}
