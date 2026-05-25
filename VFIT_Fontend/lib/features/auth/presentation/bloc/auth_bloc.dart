import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../application/auth_controller.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  final AuthRepository authRepository;
  final AuthController? authController;

  AuthBloc({
    required this.authRepository,
    this.authController,
  }) : super(AuthBlocInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
    on<ResendOtpRequested>(_onResendOtpRequested);
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocLoading());
    try {
      await authRepository.register(
        RegisterRequest(
          email: event.email,
          password: event.password,
          fullName: event.fullName,
        ),
      );
      emit(RegisterSuccess(email: event.email));
    } catch (e) {
      emit(AuthBlocFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmitted event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocLoading());
    try {
      final response = await authRepository.verifyOtp(
        email: event.email,
        otpCode: event.otpCode,
      );
      if (authController != null) {
        authController!.setUser(response.user);
      }
      emit(OtpVerifySuccess(authResponse: response));
    } catch (e) {
      emit(AuthBlocFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthBlocLoading());
    try {
      await authRepository.resendOtp(email: event.email);
      emit(OtpSentSuccess(email: event.email, message: 'Mã OTP mới đã được gửi.'));
    } catch (e) {
      emit(AuthBlocFailure(errorMessage: e.toString()));
    }
  }
}
