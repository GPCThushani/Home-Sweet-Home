import 'package:flutter/material.dart';
import 'sign_up_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF8FAF9);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [backgroundColor, Colors.transparent],
                  stops: [0.0, 0.2], 
                ).createShader(rect);
              },
              blendMode: BlendMode.dstOut,
              child: Image.asset(
                'assets/images/welcome_bg.jpg', 
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.65, 
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png', 
                      width: MediaQuery.of(context).size.width * 0.75, 
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.favorite_border, size: 100, color: Color(0xFF4A8B71)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, left: 24, right: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A8B71), 
                          minimumSize: const Size(double.infinity, 56), 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16), 
                          ),
                          elevation: 3, 
                        ),
                        child: const Text(
                          'Get Started', 
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                      ),
                      const SizedBox(height: 8), 
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'I already have an account', 
                          style: TextStyle(
                            fontSize: 16, 
                            color: Color(0xFF1E362A), 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}