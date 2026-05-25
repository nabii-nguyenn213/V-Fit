import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/vfit_logo_avatar.dart';
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

          return Scaffold(
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
                        'Tạo tài khoản',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 20),
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
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                        onPressed: isLoading ? null : () => context.go('/login'),
                        child: const Text('Đã có tài khoản? Đăng nhập'),
                      ),
                    ],
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
