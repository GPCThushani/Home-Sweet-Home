import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'choose_family_screen.dart';

class HomeReadyScreen extends StatelessWidget {
  final String familyName;
  final String familyMotto;
  final String? customAvatarPath;
  final int? presetAvatarIndex;
  final int memberCount;
  final String userEmail;

  HomeReadyScreen({
    super.key,
    required this.familyName,
    required this.familyMotto,
    this.customAvatarPath,
    this.presetAvatarIndex,
    required this.memberCount,
    required this.userEmail,
  }) {
    print("DEBUG: HomeReadyScreen initialized with customAvatarPath = $customAvatarPath, presetAvatarIndex = $presetAvatarIndex");
  }

  final List<String> _presetAvatars = const [
    'assets/images/family_avatars/avatar_1.png',
    'assets/images/family_avatars/avatar_2.jpg',
    'assets/images/family_avatars/avatar_3.jpg',
    'assets/images/family_avatars/avatar_4.jpg',
    'assets/images/family_avatars/avatar_5.jpg',
    'assets/images/family_avatars/avatar_6.jpg',
    'assets/images/family_avatars/avatar_7.jpg',
  ];

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? jwtToken = prefs.getString('jwt_token');

    if (userId == null && userEmail.isNotEmpty) {
      try {
        final lookupResponse = await http.get(
          Uri.parse('http://localhost:8080/api/users/by-email?email=$userEmail'),
        );
        if (lookupResponse.statusCode == 200) {
          final userData = jsonDecode(lookupResponse.body);
          userId = userData['id']?.toString();
          if (userId != null) {
            await prefs.setString('user_id', userId);
          }
        }
      } catch (e) {
        debugPrint("Error fetching fallback user ID: $e");
      }
    }

    String? resolvedAvatarPath = customAvatarPath;
    if (resolvedAvatarPath == null && presetAvatarIndex != null && presetAvatarIndex! >= 0 && presetAvatarIndex! < _presetAvatars.length) {
      resolvedAvatarPath = _presetAvatars[presetAvatarIndex!];
    }

    print("DEBUG: Final resolved user_id for family creation = $userId");
    print("DEBUG: Final resolved avatar path being posted = $resolvedAvatarPath");

    if (userId != null) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:8080/api/families'),
          headers: {
            'Content-Type': 'application/json',
            if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'creatorId': userId,
            'familyName': familyName.isEmpty ? 'The Family' : familyName,
            'timezone': 'Asia/Colombo',
            'creatorNickname': 'Admin',
            'avatarPath': resolvedAvatarPath,
          }),
        );

        print("DEBUG: Family creation response code = ${response.statusCode}");
        print("DEBUG: Family creation response body = ${response.body}");
      } catch (e) {
        debugPrint("Error creating family on backend: $e");
      }
    } else {
      print("ERROR: Could not resolve user ID for family creation.");
    }

    await prefs.setBool('has_family', true);
    await prefs.setString('family_name', familyName.isEmpty ? 'The Family' : familyName);
    await prefs.setString('family_motto', familyMotto);
    await prefs.setInt('family_member_count', memberCount);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ChooseFamilyScreen(userEmail: userEmail),
        ),
        (route) => false,
      );
    }
  }

  Widget _buildFamilyAvatar() {
    if (customAvatarPath != null && customAvatarPath!.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(customAvatarPath!),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
        ),
      );
    }

    if (presetAvatarIndex != null && presetAvatarIndex! >= 0 && presetAvatarIndex! < _presetAvatars.length) {
      return ClipOval(
        child: Image.asset(
          _presetAvatars[presetAvatarIndex!],
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
        ),
      );
    }

    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    return const SizedBox(
      width: 120,
      height: 120,
      child: Icon(Icons.family_restroom_rounded, size: 60, color: Color(0xFF4A8B71)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayFamilyName = familyName.trim().isEmpty ? 'The Family' : familyName.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF4A8B71).withValues(alpha: 0.3), width: 3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8F2ED),
                          border: Border.all(color: const Color(0xFF4A8B71), width: 2),
                        ),
                        child: ClipOval(child: _buildFamilyAvatar()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    displayFamilyName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF244032)),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Your home is ready!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF355E4A)),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => _completeOnboarding(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A8B71),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Enter Our Home',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}