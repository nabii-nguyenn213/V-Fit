import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/vfit_logo_avatar.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../application/auth_controller.dart';
import '../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          if (state is RegisterSuccess) {
            context.go('/register-otp?email=${Uri.encodeComponent(state.email)}');
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
          final scheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // Mirror the login page layout: gradient background + card container.
          return Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF070711),
                          Color(0xFF190B2D),
                          Color(0xFF061E2A),
                        ]
                      : const [
                          Color(0xFFF8FAFF),
                          Color(0xFFE5FBFF),
                          Color(0xFFFFE7FB),
                        ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: AppResponsive.isPhone(context)
                            ? EdgeInsets.zero
                            : const EdgeInsets.all(22),
                        decoration: AppResponsive.isPhone(context)
                            ? null
                            : BoxDecoration(
                                color: scheme.surface.withValues(alpha: 0.96),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.30 : 0.08,
                                    ),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: AppBackButton(),
                              ),
                              const SizedBox(height: 12),
                              const Align(child: VFitLogoAvatar(size: 78)),
                              const SizedBox(height: 16),
                              Text(
                                'Tạo tài khoản',
                                textAlign: TextAlign.center,
                                style: AppTypography.headerLargeFor(context),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Điền thông tin để tạo tài khoản và bắt đầu hành trình.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyFor(
                                  context,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 24),
                              AppTextField(
                                controller: _nameController,
                                label: 'Họ và tên',
                                validator: (value) =>
                                    Validators.required(value, label: 'Họ và tên'),
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: _emailController,
                                label: 'Email',
                                validator: Validators.email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: _passwordController,
                                label: 'Mật khẩu',
                                validator: Validators.password,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                              ),
                              if (state is AuthBlocFailure) ...[
                                const SizedBox(height: 12),
                                Text(
                                  state.errorMessage,
                                  style: AppTypography.bodySmallFor(
                                    context,
                                    color: scheme.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              AppButton(
                                label: 'Đăng ký',
                                loading: isLoading,
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          authBloc.add(
                                            RegisterSubmitted(
                                              email: _emailController.text.trim(),
                                              password: _passwordController.text,
                                              fullName: _nameController.text,
                                            ),
                                          );
                                        }
                                      },
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.go('/login'),
                                child: const Text('Đã có tài khoản? Đăng nhập'),
                              ),
                            ],
                          ),
                        ),
                      ),
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
