import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/vfit_logo_avatar.dart';
import '../../application/auth_controller.dart';
import '../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterOtpPage extends ConsumerStatefulWidget {
  const RegisterOtpPage({
    super.key,
    required this.email,
  });

  final String email;

  @override
  ConsumerState<RegisterOtpPage> createState() => _RegisterOtpPageState();
}

class _RegisterOtpPageState extends ConsumerState<RegisterOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 120;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(
        authRepository: ref.read(authRepositoryProvider),
        authController: ref.read(authControllerProvider.notifier),
      ),
      child: BlocConsumer<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state is OtpVerifySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xác thực tài khoản thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            // Router redirect will handle moving to onboarding automatically
          } else if (state is OtpSentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            _otpController.clear();
            _startTimer();
          } else if (state is AuthBlocFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final authBloc = BlocProvider.of<AuthBloc>(context);
          final isLoading = state is AuthBlocLoading;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              // Block back navigation to force completion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Vui lòng hoàn tất xác thực OTP để kích hoạt tài khoản.',
                  ),
                ),
              );
            },
            child: Scaffold(
              appBar: AppBar(
                leadingWidth: 76,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: AppBackButton(),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(child: VFitLogoAvatar(size: 78)),
                        const SizedBox(height: 16),
                        Text(
                          'Xác thực OTP',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mã xác thực đã được gửi về email:\n${widget.email}',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 32),

                        // Beautiful Centered 6-digit OTP Input
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          enabled: _secondsRemaining > 0 && !isLoading,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 16,
                          ),
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '000000',
                            hintStyle: TextStyle(
                              color: Colors.grey[300],
                              letterSpacing: 16,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length != 6) {
                              return 'Vui lòng nhập đủ 6 chữ số';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Countdown Timer Display
                        Center(
                          child: Column(
                            children: [
                              Text(
                                _formatTime(_secondsRemaining),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _secondsRemaining == 0
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              if (_secondsRemaining == 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Mã OTP đã hết hạn. Vui lòng gửi lại mã mới.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (state is AuthBlocFailure) ...[
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        AppButton(
                          label: 'Kích hoạt tài khoản',
                          loading: isLoading,
                          onPressed: _secondsRemaining > 0 && !isLoading
                              ? () {
                                  if (_formKey.currentState!.validate()) {
                                    authBloc.add(
                                      VerifyOtpSubmitted(
                                        email: widget.email,
                                        otpCode: _otpController.text,
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),
                        if (_secondsRemaining == 0)
                          AppButton(
                            label: 'Gửi lại mã OTP',
                            variant: AppButtonVariant.secondary,
                            loading: isLoading,
                            onPressed: () {
                              authBloc
                                  .add(ResendOtpRequested(email: widget.email));
                            },
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.go('/register');
                                },
                          child: const Text('Quay lại trang đăng ký'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
