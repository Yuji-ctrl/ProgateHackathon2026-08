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

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.text('朝のストレッチ'));
    await tester.pumpAndSettle();
    expect(find.text('とりかかる'), findsOneWidget);
    expect(find.text('振って完成'), findsOneWidget);

    // Verify that our counter has incremented.
    await tester.tap(find.text('振って完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('アルバム'));
    await tester.pumpAndSettle();
    expect(find.text('朝のストレッチ'), findsOneWidget);
  });
}
