import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/auth_logout_signal.dart';
import '../../../../core/network/api_exception.dart';
import '../../profile/data/models/user_model.dart';
import '../data/models/auth_models.dart';
import '../data/repositories/auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  final signal = ref.read(authLogoutSignalProvider);
  final sub = signal.onLogout.listen((_) {
    controller.logout();
  });
  ref.onDispose(sub.cancel);
  return controller;
});

enum AuthStatus { initial, unauthenticated, pendingOnboarding, active }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.loading = false,
  });

  const AuthState.initial() : this(status: AuthStatus.initial, loading: true);

  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool loading;

  bool get isAuthenticated =>
      (status == AuthStatus.active || status == AuthStatus.pendingOnboarding) &&
      user != null;
  bool get isActive => status == AuthStatus.active && user != null;
  bool get isPendingOnboarding =>
      status == AuthStatus.pendingOnboarding && user != null;
  bool get isLoading => loading || status == AuthStatus.initial;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? loading,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      error: clearError ? null : error ?? this.error,
      loading: loading ?? this.loading,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.initial());

  final AuthRepository _repository;

  Future<void> bootstrap() async {
    state = const AuthState.initial();
    try {
      final hasValidAccessToken = await _repository.hasValidLocalAccessToken();
      if (!hasValidAccessToken) {
        try {
          await _repository.refreshToken();
        } catch (_) {
          await _repository.clearLocalSession();
          state = const AuthState(status: AuthStatus.unauthenticated);
          return;
        }
      }
      setUser(await _repository.me());
    } catch (error) {
      await _repository.clearLocalSession();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: error.toString(),
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      loading: true,
    );
    try {
      final auth = await _repository
          .login(LoginRequest(email: email, password: password));
      setUser(auth.user);
    } catch (error) {
      await _repository.clearLocalSession();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _loginErrorMessage(error),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _repository.register(
        RegisterRequest(email: email, password: password, fullName: fullName),
      );
      state = state.copyWith(loading: false);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> verifyRegisterOtp({
    required String email,
    required String otpCode,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final auth = await _repository.verifyOtp(email: email, otpCode: otpCode);
      setUser(auth.user);
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> reloadMe() async {
    setUser(await _repository.me());
  }

  void setUser(UserModel user) {
    state = AuthState(
      status: user.isOnboardingCompleted
          ? AuthStatus.active
          : AuthStatus.pendingOnboarding,
      user: user,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> forgotPassword(String email) {
    return _repository.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) {
    return _repository.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }

  String _loginErrorMessage(Object error) {
    if (error is ApiException && error.statusCode == 401) {
      return 'Email hoặc mật khẩu không chính xác.';
    }
    return error.toString();
  }
}
