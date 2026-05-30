import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/application/auth_controller.dart';
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
  File? _scanFile;
  int _step = 0;
  bool _savingProfile = false;
  bool _uploadingScan = false;

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

  Future<void> _pickScan(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1280,
    );
    if (pickedFile == null || !mounted) {
      return;
    }
    setState(() => _scanFile = File(pickedFile.path));
  }

  Future<void> _completeScan() async {
    final file = _scanFile;
    if (file == null) {
      _showError('Please capture or choose a body scan image first');
      return;
    }

    setState(() => _uploadingScan = true);
    try {
      final user =
          await ref.read(onboardingRepositoryProvider).completeBodyScan(file);
      ref.read(authControllerProvider.notifier).setUser(user);
      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _uploadingScan = false);
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
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Onboarding'),
          actions: [
            IconButton(
              onPressed: _savingProfile || _uploadingScan
                  ? null
                  : () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
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
                title: const Text('Body scan'),
                subtitle: const Text('Capture one clear full-body image'),
                isActive: _step == 1,
                state:
                    _scanFile == null ? StepState.indexed : StepState.complete,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: _scanFile == null
                            ? Icon(
                                Icons.accessibility_new,
                                size: 56,
                                color: scheme.onSurfaceVariant,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child:
                                    Image.file(_scanFile!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.secondary(
                            label: 'Camera',
                            icon: Icons.photo_camera_outlined,
                            onPressed: _uploadingScan
                                ? null
                                : () => _pickScan(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton.secondary(
                            label: 'Gallery',
                            icon: Icons.photo_library_outlined,
                            onPressed: _uploadingScan
                                ? null
                                : () => _pickScan(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppButton.primary(
                      label: 'Complete onboarding',
                      icon: Icons.check_circle_outline,
                      loading: _uploadingScan,
                      onPressed: _uploadingScan ? null : _completeScan,
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
