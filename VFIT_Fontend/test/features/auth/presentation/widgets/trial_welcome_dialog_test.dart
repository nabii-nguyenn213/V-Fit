import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vfit_frontend/features/auth/presentation/widgets/trial_welcome_dialog.dart';

void main() {
  testWidgets('trial welcome explains the benefit and returns upgrade action',
      (tester) async {
    TrialWelcomeAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                selectedAction = await showDialog<TrialWelcomeAction>(
                  context: context,
                  builder: (context) => const TrialWelcomeDialog(),
                );
              },
              child: const Text('Mở thông báo'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở thông báo'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn đã nhận 3 ngày VIP miễn phí!'), findsOneWidget);
    expect(
      find.textContaining('bạn vẫn có thể nâng cấp lên gói VIP tháng hoặc năm'),
      findsOneWidget,
    );
    expect(find.text('Bắt đầu trải nghiệm'), findsOneWidget);
    expect(find.text('Nâng cấp VIP ngay'), findsOneWidget);

    await tester.tap(find.text('Nâng cấp VIP ngay'));
    await tester.pumpAndSettle();

    expect(selectedAction, TrialWelcomeAction.upgrade);
  });
}
