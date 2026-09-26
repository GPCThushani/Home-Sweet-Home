import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'choose_family_screen.dart';
import 'create_or_join_family_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter both email and password.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://localhost:8080/api/users/login'); 
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final token = data['token'] ?? data['accessToken'] ?? 'mock_jwt_token';
        final userId = data['userId']?.toString();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_email', email);
        if (userId != null) {
          await prefs.setString('user_id', userId);
        }

        // Check if the user already belongs to a family via backend API
        final familyCheckUrl = Uri.parse('http://localhost:8080/api/families/user?email=$email');
        final familyResponse = await http.get(
          familyCheckUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        bool hasFamily = false;
        if (familyResponse.statusCode == 200) {
          final List<dynamic> families = jsonDecode(familyResponse.body);
          hasFamily = families.isNotEmpty;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logged in successfully!"), backgroundColor: Colors.green),
          );
          
          if (hasFamily) {
            // --- ROUTE TO CHOOSE FAMILY SCREEN UPON SUCCESSFUL LOGIN ---
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChooseFamilyScreen(userEmail: email),
              ),
            );
          } else {
            // Only route to create/join if they have no families attached
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CreateOrJoinFamilyScreen(userEmail: email),
              ),
            );
          }
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _showError("Invalid email or password.");
      } else {
        _showError("Login failed. Please try again.");
      }
    } catch (e) {
      _showError("Could not connect to server. Is Spring Boot running?");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF244032)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8F2ED), 
                    border: Border.all(color: const Color(0xFFD0E0D8), width: 2), 
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0), 
                      child: Image.asset(
                        'assets/images/logo1.png', 
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.home_rounded,
                            size: 55,
                            color: Color(0xFF4A8B71),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF244032), 
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Let's get your home organized",
                      style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                label: 'Email', 
                icon: Icons.email_outlined, 
                controller: _emailController, 
                isEmail: true,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                label: 'Password', 
                icon: Icons.lock_outline, 
                controller: _passwordController, 
                isObscured: _isPasswordHidden,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                ),
              ),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: Color(0xFF4A8B71), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _loginUser, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A8B71),
                  disabledBackgroundColor: Colors.grey.shade400,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 24, width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                    : const Text(
                        'Log In',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't you have an account? ",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'SignUp',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A8B71),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label, required IconData icon, required TextEditingController controller,
    bool isObscured = false, bool isEmail = false, Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller, obscureText: isObscured,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: label, hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade400), suffixIcon: suffixIcon,
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4A8B71), width: 1.5)),
      ),
    );
  }
}