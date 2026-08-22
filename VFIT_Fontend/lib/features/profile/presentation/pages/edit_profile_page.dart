import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/enum_parsers.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../onboarding/data/repositories/onboarding_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  Gender? _gender;
  GoalType? _goalType;
  String? _avatarUrl;
  XFile? _selectedAvatar;
  bool _loading = false;
  bool _avatarUploading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _avatarUrl = user?.avatarUrl;
    _gender = user?.gender;
    _goalType = user?.goalType;

    // Asynchronously fetch current body metrics to populate fields if onboarding is completed
    if (user?.onboardingStatus == OnboardingStatus.completed) {
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() {
      _selectedAvatar = pickedFile;
      _avatarUploading = true;
    });

    try {
      final user = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(pickedFile);
      ref.read(authControllerProvider.notifier).setUser(user);
      if (mounted) {
        setState(() => _avatarUrl = user.avatarUrl);
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.error(
          error.toString(),
          title: 'Tải ảnh đại diện thất bại',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
      }
    }
  }

  Future<void> _showAvatarPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    try {
      final request = UpdateProfileRequest(
        fullName: _nameController.text.trim(),
        avatarUrl: _avatarUrl,
        gender: _gender,
        goalType: _goalType,
        heightCm: double.tryParse(_heightController.text.trim()),
        weightKg: double.tryParse(_weightController.text.trim()),
        bodyFatPercent: double.tryParse(_bodyFatController.text.trim()),
      );
      final user =
          await ref.read(profileRepositoryProvider).updateProfile(request);
      ref.read(authControllerProvider.notifier).setUser(user);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.error(error.toString(), title: 'Không cập nhật được hồ sơ');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    if (user != null && user.onboardingStatus != OnboardingStatus.completed) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: 76,
          leading: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: AppBackButton(),
          ),
          title: const Text('Chỉnh sửa hồ sơ'),
        ),
        body: const Center(
          child: PendingOnboardingPlaceholder(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('Chỉnh sửa hồ sơ'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppResponsive.pagePadding(context),
          children: [
            Center(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(52),
                    child: Container(
                      width: 104,
                      height: 104,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: _selectedAvatar != null
                          ? (kIsWeb
                              ? Image.network(
                                  _selectedAvatar!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_selectedAvatar!.path),
                                  fit: BoxFit.cover,
                                ))
                          : (_avatarUrl != null
                              ? Image.network(
                                  MediaUrlResolver.resolve(_avatarUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 44),
                                )
                              : const Icon(Icons.person, size: 44)),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      onPressed: _avatarUploading ? null : _showAvatarPicker,
                      icon: _avatarUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _nameController,
              label: 'Họ và tên',
              validator: (value) =>
                  Validators.required(value, label: 'Họ và tên'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<Gender>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Giới tính'),
              items: Gender.values
                  .map(
                    (gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(genderLabel(gender)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final user = ref.read(authControllerProvider).user;
                final alreadySet = user?.goalType != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<GoalType>(
                      value: _goalType,
                      decoration: InputDecoration(
                        labelText: 'Mục tiêu',
                        suffixIcon: alreadySet
                            ? const Tooltip(
                                message:
                                    'Mục tiêu đã được chọn và không thể thay đổi trực tiếp',
                                child: Icon(Icons.lock_outline, size: 18),
                              )
                            : null,
                      ),
                      items: GoalType.values
                          .map(
                            (goal) => DropdownMenuItem(
                              value: goal,
                              child: Text(goalLabel(goal)),
                            ),
                          )
                          .toList(),
                      onChanged: alreadySet
                          ? null // Disable dropdown if already set
                          : (value) => setState(() => _goalType = value),
                    ),
                    if (alreadySet) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          'Mục tiêu đã được chọn và không thể thay đổi trực tiếp.',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _loading ? null : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Thiết lập lại từ đầu'),
                                content: const Text(
                                  'Bạn có chắc chắn muốn thay đổi phương hướng? Hệ thống sẽ thiết lập lại trạng thái để bạn thực hiện thiết lập lại từ đầu.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Đồng ý'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              setState(() => _loading = true);
                              try {
                                final updatedUser = await ref
                                    .read(onboardingRepositoryProvider)
                                    .resetOnboarding();
                                ref.read(authControllerProvider.notifier).setUser(updatedUser);
                                if (mounted) {
                                  AppFeedback.success('Trạng thái thiết lập đã được đặt lại.');
                                }
                              } catch (e) {
                                if (mounted) {
                                  AppFeedback.error(e.toString());
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _loading = false);
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Thiết lập lại từ đầu'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _heightController,
              label: 'Chiều cao (cm)',
              keyboardType: TextInputType.number,
              validator: (value) => Validators.optionalNumber(
                value,
                min: 80,
                max: 250,
                label: 'Chiều cao',
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _weightController,
              label: 'Cân nặng (kg)',
              keyboardType: TextInputType.number,
              validator: (value) => Validators.optionalNumber(
                value,
                min: 20,
                max: 300,
                label: 'Cân nặng',
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _bodyFatController,
              label: 'Tỷ lệ mỡ (%)',
              keyboardType: TextInputType.number,
              validator: (value) => Validators.optionalNumber(
                value,
                min: 1,
                max: 70,
                label: 'Tỷ lệ mỡ',
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Lưu hồ sơ',
              loading: _loading,
              onPressed: _avatarUploading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
