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

  Future<void> _loginWithGoogle() {
    return ref.read(authControllerProvider.notifier).loginWithGoogle();
  }

  Future<void> _loginWithFacebook() {
    return ref.read(authControllerProvider.notifier).loginWithFacebook();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error == 'ACCOUNT_DEACTIVATED') {
        ref.read(authControllerProvider.notifier).clearError();
        context.push('/deactivated');
      } else if (next.error != null &&
          (next.error!.contains('OTP') || next.error!.contains('xác thực'))) {
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
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'hoặc',
                                style: AppTypography.labelFor(
                                  context,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SocialLoginButton(
                          label: 'Đăng nhập bằng Google',
                          brandLabel: 'G',
                          brandColor: const Color(0xFF4285F4),
                          loading: auth.isLoading,
                          onPressed: _loginWithGoogle,
                        ),
                        const SizedBox(height: 10),
                        _SocialLoginButton(
                          label: 'Đăng nhập bằng Facebook',
                          brandLabel: 'f',
                          brandColor: const Color(0xFF1877F2),
                          loading: auth.isLoading,
                          onPressed: _loginWithFacebook,
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

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.brandLabel,
    required this.brandColor,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final String brandLabel;
  final Color brandColor;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: AppColors.textPrimaryOf(context),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: brandColor,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 24,
                child: Center(
                  child: Text(
                    brandLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
