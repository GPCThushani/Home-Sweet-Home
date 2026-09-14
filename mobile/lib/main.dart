import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/onboarding/screens/splash_screen.dart';

void main() {
  runApp(const HomeSweetHomeApp());
}

class HomeSweetHomeApp extends StatelessWidget {
  const HomeSweetHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Sweet Home',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}