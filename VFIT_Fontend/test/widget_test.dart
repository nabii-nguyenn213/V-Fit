import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vfit_frontend/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton renders label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Continue',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('AppButton hides label while loading',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Continue',
            loading: true,
            onPressed: null,
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('destructive AppButton asks for confirmation',
      (WidgetTester tester) async {
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.destructive(
            label: 'Xóa',
            onPressed: () => deleted = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận xóa'), findsOneWidget);
    expect(deleted, isFalse);

    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });
}
