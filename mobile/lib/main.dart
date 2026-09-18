import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/home/screens/home_screen.dart';

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
      home: const AuthRouterScreen(),
    );
  }
}

/// Intelligent router: Only auto-logs in if the user has a fully completed family profile.
class AuthRouterScreen extends StatelessWidget {
  const AuthRouterScreen({super.key});

  Future<Widget> _determineInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final hasFamily = prefs.getBool('has_family') ?? false;
    final userEmail = prefs.getString('user_email') ?? '';

    // Only skip onboarding if they are logged in AND already finished setting up their family
    if (token != null && token.isNotEmpty && hasFamily) {
      return HomeScreen(userEmail: userEmail);
    }

    // Otherwise, always start them fresh at the Welcome Screen (Step 1)
    // This allows them to click "I already have an account" and log in naturally.
    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAF9),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4A8B71)),
            ),
          );
        }

        return snapshot.data ?? const WelcomeScreen();
      },
    );
  }
}