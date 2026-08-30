import 'app/app.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tnsnwhicteyxcsqlhfcw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRuc253aGljdGV5eGNzcWxoZmN3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NjE2ODcsImV4cCI6MjEwMzIzNzY4N30.8tpIrG_0YXsbJZRQd_7oT4UCC02nrCpqHi5CppMvtZ8',
  );

  runApp(const MyApp());
}
