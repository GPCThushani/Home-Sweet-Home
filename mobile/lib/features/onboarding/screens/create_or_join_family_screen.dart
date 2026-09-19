import 'package:flutter/material.dart';
import 'family_setup_screen.dart'; // Import Step 4 screen
import 'join_family_bottom_sheet.dart'; // Import the join bottom sheet dialog

class CreateOrJoinFamilyScreen extends StatelessWidget {
  final String userEmail;

  const CreateOrJoinFamilyScreen({super.key, required this.userEmail});

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Create or Join a Family',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF244032),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Connect with your household members',
                style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),

              // --- FAMILY ILLUSTRATION CONTAINER ---
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD0E0D8), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/family_illustration.png', 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.family_restroom_rounded,
                      size: 80,
                      color: Color(0xFF4A8B71),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- OPTION 1: CREATE A NEW FAMILY ---
              _buildChoiceCard(
                icon: Icons.group_add_rounded,
                title: 'Create a new family',
                subtitle: 'Start your family space as the admin',
                onTap: () {
                  // Route to Step 4: Family Setup Screen to collect name, motto, and avatar
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FamilySetupScreen(userEmail: userEmail),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // --- OPTION 2: JOIN AN EXISTING FAMILY ---
              _buildChoiceCard(
                icon: Icons.login_rounded,
                title: 'Join an existing family',
                subtitle: 'Use an invite code from a family member',
                onTap: () {
                  // Opens the Join Family bottom sheet dialog
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => JoinFamilyBottomSheet(userEmail: userEmail),
                  );
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF4A8B71), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF244032),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}