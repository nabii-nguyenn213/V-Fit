import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/repositories/profile_repository.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      if (mounted) {
        AppFeedback.success('Đổi mật khẩu thành công');
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.error(error.toString(), title: 'Không đổi được mật khẩu');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('Thay đổi mật khẩu'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppResponsive.pagePadding(context),
          children: [
            AppTextField(
              controller: _currentController,
              label: 'Mật khẩu hiện tại',
              validator: Validators.required,
              obscureText: true,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _newController,
              label: 'Mật khẩu mới',
              validator: Validators.password,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Thay đổi mật khẩu',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
