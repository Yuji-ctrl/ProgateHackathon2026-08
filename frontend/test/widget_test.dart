// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/main.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://tnsnwhicteyxcsqlhfcw.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRuc253aGljdGV5eGNzcWxoZmN3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NjE2ODcsImV4cCI6MjEwMzIzNzY4N30.8tpIrG_0YXsbJZRQd_7oT4UCC02nrCpqHi5CppMvtZ8',
    );
  });

  testWidgets('home, timer, and album flow works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('こおり日和'), findsOneWidget);
    expect(find.text('朝のストレッチ'), findsOneWidget);
    expect(find.text('タイマー開始'), findsNothing);

    await tester.tap(find.text('朝のストレッチ'));
    await tester.pumpAndSettle();
    expect(find.text('タイマー開始'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);

    await tester.tap(find.text('完成').first);
    await tester.pump();
    expect(find.text('振ってみよう！'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('振ってみよう！'), findsNothing);
    expect(find.text('完成'), findsOneWidget);
  });

  testWidgets('completion overlay appears with sparkle animation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('朝のストレッチ'));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    if (switchFinder.evaluate().isNotEmpty) {
      await tester.tap(switchFinder.first);
      await tester.pump();
    }

    await tester.tap(find.text('完成'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('かき氷完成！'), findsOneWidget);
  });
}
