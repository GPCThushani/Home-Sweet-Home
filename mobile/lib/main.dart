import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/login_screen.dart';
import 'core/services/auth_session.dart';

final _navigatorKey = GlobalKey<NavigatorState>();
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  AuthSession.onAuthenticationRequired = (message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      _messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  };
  runApp(const HomeSweetHomeApp());
}

class HomeSweetHomeApp extends StatelessWidget {
  const HomeSweetHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      title: 'Home Sweet Home',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // Every time the app icon is tapped and launched, it starts fresh here:
      home: const WelcomeScreen(),
    );
  }
}
