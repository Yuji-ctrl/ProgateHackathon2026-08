// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('home, timer, and album flow works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('こおり日和'), findsOneWidget);
    expect(find.text('朝のストレッチ'), findsOneWidget);

    // Timer buttons live on the home screen.
    expect(find.text('タイマー開始'), findsNothing);

    // Open a task by pressing its timer button frame.
    await tester.tap(find.text('朝のストレッチ'));
    await tester.pumpAndSettle();
    expect(find.text('タイマー開始'), findsOneWidget);
    expect(find.text('振って完成'), findsOneWidget);

    // Completion starts with an instruction dialog; shaking completes the habit.
    await tester.tap(find.text('振って完成').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('端末を振ってください'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('振って完成'), findsOneWidget);
  });
}
