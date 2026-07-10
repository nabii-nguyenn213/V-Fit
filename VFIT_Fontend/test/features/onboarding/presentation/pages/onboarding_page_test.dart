import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vfit_frontend/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vfit_frontend/features/profile/data/models/user_model.dart';
import 'package:vfit_frontend/features/profile/data/repositories/profile_repository.dart';

class _StubProfileRepository extends ProfileRepository {
  _StubProfileRepository() : super(Dio());

  @override
  Future<BodyMetricModel> bodyMetrics() async => const BodyMetricModel();
}

void main() {
  testWidgets('hiển thị nội dung thiết lập ban đầu bằng tiếng Việt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(
            _StubProfileRepository(),
          ),
        ],
        child: const MaterialApp(home: OnboardingPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Thiết lập ban đầu'), findsOneWidget);
    expect(find.text('Thông tin thể chất'), findsOneWidget);
    expect(
      find.text('Chiều cao và cân nặng là thông tin bắt buộc'),
      findsOneWidget,
    );
    expect(find.text('Chiều cao (cm)'), findsOneWidget);
    expect(find.text('Cân nặng (kg)'), findsOneWidget);
    expect(
      find.text('Tỷ lệ mỡ cơ thể (%) (không bắt buộc)'),
      findsOneWidget,
    );
    expect(find.text('Lưu và tiếp tục'), findsOneWidget);

    for (final englishText in [
      'Onboarding',
      'Physical profile',
      'Height and weight are required',
      'Height (cm)',
      'Weight (kg)',
      'Body fat (%) optional',
      'Save and continue',
    ]) {
      expect(find.text(englishText), findsNothing);
    }
  });
}
