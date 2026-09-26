import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/main_navigation_shell.dart'; // Import your correct navigation shell

class JoinFamilyBottomSheet extends StatefulWidget {
  final String userEmail;

  const JoinFamilyBottomSheet({super.key, required this.userEmail});

  @override
  State<JoinFamilyBottomSheet> createState() => _JoinFamilyBottomSheetState();
}

class _JoinFamilyBottomSheetState extends State<JoinFamilyBottomSheet> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter an invite code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');
      String? userId = prefs.getString('user_id');

      if (userId == null) {
        final userResponse = await http.get(
          Uri.parse('http://localhost:8080/api/users/by-email?email=${widget.userEmail}'),
          headers: {
            if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
          },
        );
        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          userId = userData['id']?.toString();
          if (userId != null) {
            await prefs.setString('user_id', userId);
          }
        }
      }

      if (userId == null) {
        setState(() {
          _errorMessage = 'Could not resolve user session. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:8080/api/families/join-by-code'),
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'inviteCode': code,
          'userId': userId,
          'nickname': nickname.isEmpty ? 'Member' : nickname,
          'role': 'FAMILY_MEMBER',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Correctly extract the family ID from the joined response
        final familyId = responseData['familyId']?.toString() ?? responseData['id']?.toString();

        await prefs.setBool('has_family', true);
        if (familyId != null) {
          await prefs.setString('current_family_id', familyId);
        }

        if (mounted) {
          // --- ROUTE DIRECTLY TO MainNavigationShell JUST LIKE ChooseFamilyScreen DOES ---
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainNavigationShell(
                userEmail: widget.userEmail,
                familyId: familyId ?? '',
              ),
            ),
            (route) => false,
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorBody['error'] ?? 'Failed to join family. Check your code.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Join an Existing Family',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF244032),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the invite code provided by your family admin.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Invite Code (e.g. HSH-12AB34)',
              filled: true,
              fillColor: const Color(0xFFF8FAF9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF4A8B71)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: 'Your Nickname in Family (Optional)',
              hintText: 'e.g. Uncle John, Mom, Alex',
              filled: true,
              fillColor: const Color(0xFFF8FAF9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF4A8B71)),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _joinFamily,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A8B71),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Join Family Space',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}