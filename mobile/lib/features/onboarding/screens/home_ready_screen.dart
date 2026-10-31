import 'package:mobile/core/services/api_config.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/services/authenticated_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/widgets/main_navigation_shell.dart';

class HomeReadyScreen extends StatefulWidget {
  final String familyName;
  final String familyMotto;
  final String? customAvatarPath;
  final int? presetAvatarIndex;
  final int memberCount;
  final String userEmail;
  final List<Map<String, dynamic>> familyMembers;
  final int creatorProfileIndex;

  const HomeReadyScreen({
    super.key,
    required this.familyName,
    required this.familyMotto,
    this.customAvatarPath,
    this.presetAvatarIndex,
    required this.memberCount,
    required this.userEmail,
    required this.familyMembers,
    required this.creatorProfileIndex,
  });

  @override
  State<HomeReadyScreen> createState() => _HomeReadyScreenState();
}

class _HomeReadyScreenState extends State<HomeReadyScreen> {
  bool _isSubmitting = false;

  static const List<String> _presetAvatars = [
    'assets/images/family_avatars/avatar_1.png',
    'assets/images/family_avatars/avatar_2.jpg',
    'assets/images/family_avatars/avatar_3.jpg',
    'assets/images/family_avatars/avatar_4.jpg',
    'assets/images/family_avatars/avatar_5.jpg',
    'assets/images/family_avatars/avatar_6.jpg',
    'assets/images/family_avatars/avatar_7.jpg',
  ];

  Future<void> _completeOnboarding() async {
    if (_isSubmitting) return;

    final members = widget.familyMembers;

    if (members.isEmpty ||
        widget.creatorProfileIndex < 0 ||
        widget.creatorProfileIndex >= members.length) {
      _showError(
        'Please go back and select a valid family creator profile.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      String? userId = prefs.getString('user_id');
      final jwtToken = prefs.getString('jwt_token');

      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception(
          'Your login session is missing. Please log in again.',
        );
      }

      if (userId == null || userId.isEmpty) {
        final lookupResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/users/by-email')
              .replace(
                queryParameters: {
                  'email': widget.userEmail,
                },
              ),
          headers: {
            'Authorization': 'Bearer $jwtToken',
          },
        );

        if (lookupResponse.statusCode != 200) {
          throw Exception(
            'Could not identify the logged-in user.',
          );
        }

        final userData = jsonDecode(lookupResponse.body);

        userId = userData['id']?.toString();

        if (userId == null || userId.isEmpty) {
          throw Exception('User ID was not returned.');
        }

        await prefs.setString('user_id', userId);
      }

      String? avatarPath = widget.customAvatarPath;

      if (avatarPath == null &&
          widget.presetAvatarIndex != null &&
          widget.presetAvatarIndex! >= 0 &&
          widget.presetAvatarIndex! < _presetAvatars.length) {
        avatarPath = _presetAvatars[widget.presetAvatarIndex!];
      }

      final creator = members[widget.creatorProfileIndex];

      final creatorName =
          creator['name']?.toString().trim() ?? '';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/families'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'creatorId': userId,
          'familyName': widget.familyName.trim().isEmpty
              ? 'The Family'
              : widget.familyName.trim(),
          'timezone': 'Asia/Colombo',
          'creatorNickname': creatorName.isEmpty
              ? 'Admin'
              : creatorName,
          'avatarPath': avatarPath,
          'members': members,
          'creatorProfileIndex': widget.creatorProfileIndex,
        }),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        String message = 'Could not create family.';

        try {
          final errorData = jsonDecode(response.body);

          if (errorData is Map &&
              errorData['error'] != null) {
            message = errorData['error'].toString();
          } else if (errorData is Map &&
              errorData['message'] != null) {
            message = errorData['message'].toString();
          }
        } catch (_) {}

        throw Exception(message);
      }

      final data = jsonDecode(response.body);
      final createdFamilyId = data['id']?.toString();

      if (createdFamilyId == null ||
          createdFamilyId.isEmpty) {
        throw Exception(
          'Family was created but no family ID was returned.',
        );
      }

      await prefs.setString(
        'current_family_id',
        createdFamilyId,
      );

      await prefs.setString(
        'family_name',
        widget.familyName.trim().isEmpty
            ? 'The Family'
            : widget.familyName.trim(),
      );

      await prefs.setString(
        'family_motto',
        widget.familyMotto,
      );

      await prefs.setInt(
        'family_member_count',
        members.length,
      );

      await prefs.setBool('has_family', true);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationShell(
            userEmail: widget.userEmail,
            familyId: createdFamilyId,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Family onboarding error: $e');

      if (!mounted) return;

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return const SizedBox(
      width: 120,
      height: 120,
      child: Icon(
        Icons.family_restroom_rounded,
        size: 60,
        color: Color(0xFF4A8B71),
      ),
    );
  }

  Widget _buildFamilyAvatar() {
    if (widget.customAvatarPath != null &&
        widget.customAvatarPath!.isNotEmpty) {
      if (!kIsWeb) {
        return ClipOval(
          child: Image.file(
            File(widget.customAvatarPath!),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildFallbackAvatar(),
          ),
        );
      }

      return _buildFallbackAvatar();
    }

    final index = widget.presetAvatarIndex;

    if (index != null &&
        index >= 0 &&
        index < _presetAvatars.length) {
      return ClipOval(
        child: Image.asset(
          _presetAvatars[index],
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildFallbackAvatar(),
        ),
      );
    }

    return _buildFallbackAvatar();
  }

  @override
  Widget build(BuildContext context) {
    final displayFamilyName =
        widget.familyName.trim().isEmpty
            ? 'The Family'
            : widget.familyName.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
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
                      border: Border.all(
                        color: const Color(0xFF4A8B71)
                            .withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8F2ED),
                          border: Border.all(
                            color: const Color(0xFF4A8B71),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _buildFamilyAvatar(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    displayFamilyName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF244032),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Your home is ready!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF355E4A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.familyMembers.length} family profiles configured.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A8B71),
                      minimumSize:
                          const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enter Our Home',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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