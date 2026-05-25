import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/enum_parsers.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/application/auth_controller.dart';
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
  File? _selectedAvatar;
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

    // Asynchronously fetch current body metrics to populate fields
    ref.read(profileRepositoryProvider).bodyMetrics().then((metrics) {
      if (mounted) {
        setState(() {
          _heightController.text = metrics.heightCm != null ? metrics.heightCm!.toStringAsFixed(0) : '';
          _weightController.text = metrics.weightKg != null ? metrics.weightKg!.toStringAsFixed(1) : '';
          _bodyFatController.text = metrics.bodyFatPercent != null ? metrics.bodyFatPercent!.toStringAsFixed(1) : '';
        });
      }
    }).catchError((_) {});
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
      _selectedAvatar = File(pickedFile.path);
      _avatarUploading = true;
    });

    try {
      final user = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(File(pickedFile.path));
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
              title: const Text('Chup anh'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chon tu thu vien'),
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
    final avatarProvider = _selectedAvatar != null
        ? FileImage(_selectedAvatar!)
        : _avatarImageProvider(_avatarUrl);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('Chinh sua ho so'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? const Icon(Icons.person, size: 44)
                        : null,
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
              label: 'Ho va ten',
              validator: (value) =>
                  Validators.required(value, label: 'Ho va ten'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<Gender>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gioi tinh'),
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
                        labelText: 'Muc tieu',
                        suffixIcon: alreadySet
                            ? const Tooltip(
                                message: 'Mục tiêu đã được chọn và không thể thay đổi',
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
                    if (alreadySet)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          'Mục tiêu đã được chọn và không thể thay đổi.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _heightController,
              label: 'Chieu cao (cm)',
              keyboardType: TextInputType.number,
              validator: (value) => Validators.optionalNumber(
                value,
                min: 80,
                max: 250,
                label: 'Chieu cao',
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _weightController,
              label: 'Can nang (kg)',
              keyboardType: TextInputType.number,
              validator: (value) => Validators.optionalNumber(
                value,
                min: 20,
                max: 300,
                label: 'Can nang',
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _bodyFatController,
              label: 'Ty le mo (%)',
              keyboardType: TextInputType.number,
              validator: (value) => Validators.optionalNumber(
                value,
                min: 1,
                max: 70,
                label: 'Ty le mo',
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Luu ho so',
              loading: _loading,
              onPressed: _avatarUploading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

ImageProvider? _avatarImageProvider(String? avatarUrl) {
  final resolvedUrl = MediaUrlResolver.resolveNullable(avatarUrl);
  if (resolvedUrl == null) {
    return null;
  }
  return NetworkImage(resolvedUrl);
}
