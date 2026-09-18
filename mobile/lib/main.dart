import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/welcome_screen.dart';

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
      // Every time the app icon is tapped and launched, it starts fresh here:
      home: const WelcomeScreen(),
    );
  }
}