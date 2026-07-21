import 'package:flutter/material.dart';

import 'screens/home_menu_screen.dart';

void main() {
  runApp(const ControlFincaWebApp());
}

class ControlFincaWebApp extends StatelessWidget {
  const ControlFincaWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control Finca Web',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6F42)),
        useMaterial3: true,
      ),
      home: const HomeMenuScreen(),
    );
  }
}
