import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/vfit_logo_avatar.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../application/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref.read(authControllerProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error == 'ACCOUNT_DEACTIVATED') {
        ref.read(authControllerProvider.notifier).clearError();
        context.push('/deactivated');
      } else if (next.error != null && (next.error!.contains('OTP') || next.error!.contains('xác thực'))) {
        final email = _emailController.text.trim();
        ref.read(authControllerProvider.notifier).clearError();
        context.go('/register-otp?email=${Uri.encodeComponent(email)}');
      }
    });

    final auth = ref.watch(authControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      // Structural border — uses outlineVariant not primary
                      // so the card reads as layout, not an accent highlight.
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
                          'Đăng nhập',
                          textAlign: TextAlign.center,
                          style: AppTypography.headerLargeFor(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đăng nhập để sử dụng các tính năng VIP và lưu lại tiến độ tập luyện.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyFor(
                            context,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 28),
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
                          validator: Validators.required,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: const Text('Quên mật khẩu?'),
                          ),
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            auth.error!,
                            style: TextStyle(color: scheme.error),
                          ),
                        ],
                        const SizedBox(height: 18),
                        AppButton(
                          label: 'Đăng nhập',
                          loading: auth.isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Tạo tài khoản mới'),
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
  }
}
