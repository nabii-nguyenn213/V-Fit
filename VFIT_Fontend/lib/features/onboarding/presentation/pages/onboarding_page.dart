import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/repositories/onboarding_repository.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  int _step = 0;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    ref.read(profileRepositoryProvider).bodyMetrics().then((metrics) {
      if (mounted) {
        setState(() {
          _heightController.text = metrics.heightCm != null
              ? metrics.heightCm!.toStringAsFixed(0)
              : '';
          _weightController.text = metrics.weightKg != null
              ? metrics.weightKg!.toStringAsFixed(1)
              : '';
          _bodyFatController.text = metrics.bodyFatPercent != null
              ? metrics.bodyFatPercent!.toStringAsFixed(1)
              : '';
        });
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final user =
          await ref.read(onboardingRepositoryProvider).updatePhysicalProfile(
                heightCm: double.parse(_heightController.text.trim()),
                weightKg: double.parse(_weightController.text.trim()),
                bodyFatPercent: double.tryParse(_bodyFatController.text.trim()),
              );
      ref.read(authControllerProvider.notifier).setUser(user);
      if (mounted) {
        setState(() => _step = 1);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }



  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    AppFeedback.error(error.toString(), title: 'Không hoàn tất onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Onboarding'),
          actions: [
            IconButton(
              onPressed: _savingProfile
                  ? null
                  : () => context.go('/home'),
              icon: const Icon(Icons.close),
              tooltip: 'Thoát về trang chủ',
            ),
          ],
        ),
        body: SafeArea(
          child: Stepper(
            currentStep: _step,
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: [
              Step(
                title: const Text('Physical profile'),
                subtitle: const Text('Height and weight are required'),
                isActive: _step == 0,
                state: _step > 0 ? StepState.complete : StepState.indexed,
                content: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _heightController,
                        label: 'Height (cm)',
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            Validators.optionalNumber(
                              value,
                              min: 80,
                              max: 250,
                              label: 'Height',
                            ) ??
                            Validators.required(value, label: 'Height'),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            Validators.optionalNumber(
                              value,
                              min: 20,
                              max: 300,
                              label: 'Weight',
                            ) ??
                            Validators.required(value, label: 'Weight'),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _bodyFatController,
                        label: 'Body fat (%) optional',
                        keyboardType: TextInputType.number,
                        validator: (value) => Validators.optionalNumber(
                          value,
                          min: 1,
                          max: 70,
                          label: 'Body fat',
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppButton.primary(
                        label: 'Save and continue',
                        icon: Icons.arrow_forward,
                        loading: _savingProfile,
                        onPressed: _savingProfile ? null : _saveProfile,
                      ),
                    ],
                  ),
                ),
              ),
              Step(
                title: const Text('Quét cơ thể'),
                subtitle: const Text('Bắt đầu phân tích hình thể realtime bằng AI'),
                isActive: _step == 1,
                state: _step > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    AppButton.primary(
                      label: 'Bắt đầu quét cơ thể realtime',
                      icon: Icons.accessibility_new_rounded,
                      onPressed: () => context.push('/onboarding/body-scan-realtime'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
