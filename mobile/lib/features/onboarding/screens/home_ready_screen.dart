import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/screens/home_screen.dart';

class HomeReadyScreen extends StatelessWidget {
  final String familyName;
  final String familyMotto;
  final String? customAvatarPath;
  final int? presetAvatarIndex;
  final int memberCount;
  final String userEmail;

  const HomeReadyScreen({
    super.key,
    required this.familyName,
    required this.familyMotto,
    this.customAvatarPath,
    this.presetAvatarIndex,
    required this.memberCount,
    required this.userEmail,
  });

  // Available family avatars
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

    // Mark family setup as completed
    await prefs.setBool('has_family', true);

    // Save basic family information
    await prefs.setString(
      'family_name',
      familyName.isEmpty ? 'The Family' : familyName,
    );

    await prefs.setString('family_motto', familyMotto);
    await prefs.setInt('family_member_count', memberCount);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userEmail: userEmail,
          ),
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
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar();
          },
        ),
      );
    }

    if (presetAvatarIndex != null &&
        presetAvatarIndex! >= 0 &&
        presetAvatarIndex! < _presetAvatars.length) {
      return ClipOval(
        child: Image.asset(
          _presetAvatars[presetAvatarIndex!],
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar();
          },
        ),
      );
    }

    return _buildFallbackAvatar();
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

  @override
  Widget build(BuildContext context) {
    final displayFamilyName =
        familyName.trim().isEmpty ? 'The Family' : familyName.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // ------------------------------------------------
          // AMBIENT WATERCOLOR GLOW BACKGROUND DECORATIONS
          // ------------------------------------------------
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F2ED).withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD0E0D8).withValues(alpha: 0.4),
              ),
            ),
          ),

          // ------------------------------------------------
          // MAIN CONTENT
          // ------------------------------------------------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // 1. SELECTED FAMILY AVATAR WITH DUAL GLOW RING
                  Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF4A8B71).withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A8B71).withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
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
                        child: ClipOval(child: _buildFamilyAvatar()),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 2. FAMILY NAME (Styled cleanly as a bold header)
                  Text(
                    displayFamilyName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF244032),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3. YOUR HOME IS READY!
                  const Text(
                    'Your home is ready!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF355E4A),
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. MEMBER COUNT BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2ED),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4A8B71).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          size: 16,
                          color: Color(0xFF4A8B71),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A8B71),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. FAMILY MOTTO / SLOGAN
                  if (familyMotto.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '"${familyMotto.trim()}"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // 6. ENTER OUR HOME BUTTON WITH SOFT DROP SHADOW
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A8B71).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _completeOnboarding(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A8B71),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Enter Our Home',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}