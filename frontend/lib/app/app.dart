import 'package:flutter/material.dart';

import '../screens/shell.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'こおり日和',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffef7d68)),
          scaffoldBackgroundColor: const Color(0xfffffaf4),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xfffffaf4),
            foregroundColor: Color(0xff263238),
          ),
        ),
        home: const Shell(),
      );
}
