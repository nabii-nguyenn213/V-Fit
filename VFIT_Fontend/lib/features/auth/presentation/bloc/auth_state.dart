import 'package:equatable/equatable.dart';
import '../../data/models/auth_models.dart';

abstract class AuthBlocState extends Equatable {
  const AuthBlocState();

  @override
  List<Object?> get props => [];
}

class AuthBlocInitial extends AuthBlocState {}

class AuthBlocLoading extends AuthBlocState {}

class RegisterSuccess extends AuthBlocState {
  final String email;
  const RegisterSuccess({required this.email});

  @override
  List<Object?> get props => [email];
}

class OtpSentSuccess extends AuthBlocState {
  final String email;
  final String message;

  const OtpSentSuccess({required this.email, required this.message});

  @override
  List<Object?> get props => [email, message];
}

class OtpVerifySuccess extends AuthBlocState {
  final AuthResponse authResponse;
  const OtpVerifySuccess({required this.authResponse});

  @override
  List<Object?> get props => [authResponse];
}

class AuthBlocFailure extends AuthBlocState {
  final String errorMessage;
  const AuthBlocFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
