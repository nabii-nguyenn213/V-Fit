import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/auth_controller.dart';

class SetupPasswordPage extends ConsumerStatefulWidget {
  const SetupPasswordPage({super.key});

  @override
  ConsumerState<SetupPasswordPage> createState() => _SetupPasswordPageState();
}

class _SetupPasswordPageState extends ConsumerState<SetupPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .setupPassword(_passwordController.text);
      if (mounted) {
        AppFeedback.success(
            'Đã thiết lập mật khẩu. Hãy tiếp tục thiết lập hồ sơ.');
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.error(
          error.toString(),
          title: 'Không thiết lập được mật khẩu',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _confirmPassword(String? value) {
    final requiredMessage = Validators.required(
      value,
      label: 'Xác nhận mật khẩu',
    );
    if (requiredMessage != null) {
      return requiredMessage;
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final email = user?.email;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppResponsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_reset_rounded,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Thiết lập mật khẩu',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      email == null || email.isEmpty
                          ? 'Tài khoản Google của bạn cần có mật khẩu V-FIT trước khi bắt đầu thiết lập hồ sơ.'
                          : 'Tài khoản $email cần có mật khẩu V-FIT trước khi bắt đầu thiết lập hồ sơ.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu mới',
                      validator: Validators.password,
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _confirmController,
                      label: 'Xác nhận mật khẩu',
                      validator: _confirmPassword,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Tiếp tục',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 10),
                    AppButton.secondary(
                      label: 'Đăng xuất',
                      onPressed: _loading
                          ? null
                          : ref.read(authControllerProvider.notifier).logout,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
