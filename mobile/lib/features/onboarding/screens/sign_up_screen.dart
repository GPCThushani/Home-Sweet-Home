import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_or_join_family_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isLoading = false; 

  bool _hasMinLength = false;
  bool _hasLetter = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      final password = _passwordController.text;
      setState(() {
        _hasMinLength = password.length >= 8;
        _hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
        _hasNumber = password.contains(RegExp(r'[0-9]'));
        _hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (!email.contains('@') || !email.contains('.')) {
      _showError("Please enter a valid email address (must contain '@' and '.').");
      return;
    }

    if (!_hasMinLength || !_hasLetter || !_hasNumber || !_hasSymbol) {
      _showError("Please ensure your password meets all requirements.");
      return;
    }

    if (password != _confirmPasswordController.text) {
      _showError("Passwords do not match!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://10.0.2.2:8080/api/users/register');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        final userId = data['userId']?.toString();
        final token = data['token']?.toString();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        if (userId != null) {
          await prefs.setString('user_id', userId);
        }
        if (token != null) {
          await prefs.setString('jwt_token', token);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created successfully!"), backgroundColor: Colors.green),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreateOrJoinFamilyScreen(userEmail: email),
            ),
          );
        }
      } else if (response.statusCode == 500 || response.statusCode == 409) {
        _showError("An account is already registered under this email. Please log in instead.");
      } else {
        _showError("Something went wrong. Please try again later.");
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
                child: Column(
                  children: [
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF244032), 
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Let's get your home ready",
                      style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(label: 'Full name', icon: Icons.person_outline, controller: _nameController),
              const SizedBox(height: 16),
              
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
              
              Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 12.0),
                child: Column(
                  children: [
                    _buildRequirement('At least 8 characters', _hasMinLength),
                    _buildRequirement('Contains a letter', _hasLetter),
                    _buildRequirement('Contains a number', _hasNumber),
                    _buildRequirement('Contains a symbol (!@#\$&*)', _hasSymbol),
                  ],
                ),
              ),

              _buildTextField(
                label: 'Confirm password', 
                icon: Icons.lock_outline, 
                controller: _confirmPasswordController, 
                isObscured: _isConfirmPasswordHidden,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                ),
              ),
              
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser, 
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
                        'Create account',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(isMet ? Icons.check_circle : Icons.circle_outlined, color: isMet ? Colors.green : Colors.grey.shade400, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: isMet ? Colors.green.shade700 : Colors.grey.shade600)),
        ],
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