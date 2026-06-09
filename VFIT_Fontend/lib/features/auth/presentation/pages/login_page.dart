import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/vfit_logo_avatar.dart';
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
    final palette = _LoginPalette.of(context);
    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                compact ? 10 : 18,
                18,
                compact ? 12 : 18,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (compact ? 22 : 36),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _LoginShell(
                      compact: compact,
                      palette: palette,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LoginHeader(compact: compact, palette: palette),
                            SizedBox(height: compact ? 16 : 20),
                            _LoginTextField(
                              controller: _emailController,
                              label: 'Nhập sdt hoặc mã sinh viên',
                              icon: Icons.alternate_email_rounded,
                              validator: Validators.email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              palette: palette,
                            ),
                            SizedBox(height: compact ? 10 : 12),
                            _LoginTextField(
                              controller: _passwordController,
                              label: 'Mật khẩu',
                              icon: Icons.lock_outline_rounded,
                              validator: Validators.required,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              palette: palette,
                            ),
                            SizedBox(height: compact ? 6 : 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.go('/forgot-password'),
                                style: TextButton.styleFrom(
                                  foregroundColor: palette.accent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ),
                            if (auth.error != null) ...[
                              SizedBox(height: compact ? 8 : 10),
                              _ErrorBanner(message: auth.error!),
                            ],
                            SizedBox(height: compact ? 12 : 16),
                            _PrimaryLoginButton(
                              loading: auth.isLoading,
                              palette: palette,
                              onPressed: _submit,
                            ),
                            SizedBox(height: compact ? 14 : 18),
                            _DividerLabel(palette: palette),
                            SizedBox(height: compact ? 12 : 14),
                            _SocialLoginButton(
                              label: 'Chọn tài khoản Google',
                              supportingLabel: 'Mở màn hình chọn tài khoản',
                              brandLabel: 'G',
                              brandColor: const Color(0xFF4285F4),
                              loading: auth.isLoading,
                              palette: palette,
                              onPressed: _loginWithGoogle,
                            ),
                            SizedBox(height: compact ? 8 : 10),
                            _SocialLoginButton(
                              label: 'Tiếp tục với Facebook',
                              supportingLabel: 'Đăng nhập bằng Facebook',
                              brandLabel: 'f',
                              brandColor: const Color(0xFF1877F2),
                              loading: auth.isLoading,
                              palette: palette,
                              onPressed: _loginWithFacebook,
                            ),
                            SizedBox(height: compact ? 12 : 16),
                            _RegisterPrompt(palette: palette),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({
    required this.compact,
    required this.palette,
  });

  final bool compact;
  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.controlSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border),
              ),
              child: const AppBackButton(),
            ),
            const Spacer(),
            _ModePill(palette: palette),
          ],
        ),
        SizedBox(height: compact ? 14 : 18),
        Align(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: palette.accent
                      .withValues(alpha: palette.isDark ? 0.24 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: VFitLogoAvatar(size: compact ? 56 : 64),
          ),
        ),
        SizedBox(height: compact ? 12 : 14),
        Text(
          'Đăng nhập V-FIT',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.primaryText,
            fontSize: compact ? 24 : 28,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          'Huấn luyện cá nhân hóa, dữ liệu riêng tư, trải nghiệm cao cấp.',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.secondaryText,
            fontSize: compact ? 12.5 : 13.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _LoginShell extends StatelessWidget {
  const _LoginShell({
    required this.compact,
    required this.palette,
    required this.child,
  });

  final bool compact;
  final _LoginPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.scaffold,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: palette.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : palette.border,
            ),
            boxShadow: palette.isDark
                ? [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0A6A36FF),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 20,
              compact ? 14 : 18,
              compact ? 16 : 20,
              compact ? 14 : 18,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.palette,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final _LoginPalette palette;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: TextStyle(
        color: palette.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        isDense: true,
        filled: true,
        fillColor: palette.controlSurface,
        labelStyle: TextStyle(
          color: palette.secondaryText,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: palette.accent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: _fieldBorder(palette.border),
        enabledBorder: _fieldBorder(palette.border),
        focusedBorder: _fieldBorder(palette.accent, width: 1.5),
        errorBorder: _fieldBorder(_LoginPalette.error),
        focusedErrorBorder: _fieldBorder(_LoginPalette.error, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({
    required this.loading,
    required this.palette,
    required this.onPressed,
  });

  final bool loading;
  final _LoginPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.accent.withValues(alpha: 0.48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Đăng nhập'),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.supportingLabel,
    required this.brandLabel,
    required this.brandColor,
    required this.loading,
    required this.palette,
    required this.onPressed,
  });

  final String label;
  final String supportingLabel;
  final String brandLabel;
  final Color brandColor;
  final bool loading;
  final _LoginPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.controlSurface,
          foregroundColor: palette.primaryText,
          disabledForegroundColor: palette.secondaryText.withValues(alpha: 0.6),
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: brandColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(
                        alpha: palette.isDark ? 0.32 : 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox.square(
                dimension: 28,
                child: Center(
                  child: Text(
                    brandLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    supportingLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: palette.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.palette});

  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: palette.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'hoặc',
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(child: Divider(color: palette.border)),
      ],
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt({required this.palette});

  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Chưa có tài khoản?',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          style: TextButton.styleFrom(
            foregroundColor: palette.accent,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          child: const Text('Tạo ngay'),
        ),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.palette});

  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.controlSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 15,
              color: palette.accent,
            ),
            const SizedBox(width: 5),
            Text(
              'Premium',
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = _LoginPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.isDark
            ? _LoginPalette.error.withValues(alpha: 0.10)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _LoginPalette.error.withValues(alpha: 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: palette.isDark
                  ? const Color(0xFFF87171)
                  : _LoginPalette.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: palette.isDark
                      ? const Color(0xFFF87171)
                      : _LoginPalette.error,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
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

class _LoginPalette {
  const _LoginPalette({
    required this.isDark,
    required this.canvas,
    required this.scaffold,
    required this.card,
    required this.controlSurface,
    required this.primaryText,
    required this.secondaryText,
    required this.border,
    required this.accent,
  });

  static const accentPurple = Color(0xFF6A36FF);
  static const error = Color(0xFFEF4444);

  final bool isDark;
  final Color canvas;
  final Color scaffold;
  final Color card;
  final Color controlSurface;
  final Color primaryText;
  final Color secondaryText;
  final Color border;
  final Color accent;

  static _LoginPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _LoginPalette(
        isDark: true,
        canvas: Color(0xFF0B0A0F),
        scaffold: Color(0xFF12111A),
        card: Color(0xFF1C1A26),
        controlSurface: Color(0xFF12111A),
        primaryText: Color(0xFFFFFFFF),
        secondaryText: Color(0xFF94A3B8),
        border: Color(0xFF2D2B3A),
        accent: accentPurple,
      );
    }
    return const _LoginPalette(
      isDark: false,
      canvas: Color(0xFFFFFFFF),
      scaffold: Color(0xFFF9F9FB),
      card: Color(0xFFFFFFFF),
      controlSurface: Color(0xFFF9F9FB),
      primaryText: Color(0xFF0B0A0F),
      secondaryText: Color(0xFF64748B),
      border: Color(0xFFE2E8F0),
      accent: accentPurple,
    );
  }
}
