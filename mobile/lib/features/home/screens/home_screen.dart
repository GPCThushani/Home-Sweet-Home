import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../onboarding/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;

  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _familyName = 'Our Family';
  String _inviteCode = 'Loading...';
  String? _familyId;
  String? _familyAvatarPath;
  int _memberCount = 1;

  @override
  void initState() {
    super.initState();
    _fetchFamilyDetails();
  }

  Future<void> _fetchFamilyDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      final url = Uri.parse('http://localhost:8080/api/families/user?email=${widget.userEmail}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> families = jsonDecode(response.body);
        if (families.isNotEmpty) {
          setState(() {
            _familyName = families[0]['name'] ?? 'Our Family';
            _inviteCode = families[0]['inviteCode'] ?? 'HSH-DEMO2026';
            _familyId = families[0]['id'];
            _familyAvatarPath = families[0]['avatarPath'];
            _memberCount = families[0]['memberCount'] ?? 1;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching family details for home screen: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildAvatarImage(String? path, double size) {
    if (path == null || path.isEmpty) {
      return Icon(Icons.family_restroom_rounded, color: const Color(0xFF4A8B71), size: size * 0.5);
    }

    if (path.startsWith('/') || path.startsWith('file://')) {
      final cleanPath = path.replaceFirst('file://', '');
      return Image.file(
        File(cleanPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.family_restroom_rounded, color: const Color(0xFF4A8B71), size: size * 0.5),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.family_restroom_rounded, color: const Color(0xFF4A8B71), size: size * 0.5),
      );
    }

    return Icon(Icons.family_restroom_rounded, color: const Color(0xFF4A8B71), size: size * 0.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F2ED),
                border: Border.all(color: const Color(0xFF4A8B71), width: 1.5),
              ),
              child: ClipOval(child: _buildAvatarImage(_familyAvatarPath, 36)),
            ),
            const SizedBox(width: 10),
            Text(
              _familyName,
              style: const TextStyle(
                color: Color(0xFF244032),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF244032)),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD0E0D8), width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(fontSize: 14, color: Color(0xFF4A8B71), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.userEmail,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF244032),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_memberCount family members connected.',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF4A8B71), width: 2),
                      ),
                      child: ClipOval(child: _buildAvatarImage(_familyAvatarPath, 60)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- INVITE CODE CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4A8B71).withValues(alpha: 0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Family Invite Code',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoading ? 'Loading code...' : _inviteCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF244032),
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF4A8B71)),
                      tooltip: 'Copy Invite Code',
                      onPressed: _isLoading
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: _inviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Invite code copied to clipboard!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Family Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF244032),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    icon: Icons.task_alt,
                    title: 'Global Tasks',
                    subtitle: 'View chores',
                    color: Colors.orange.shade50,
                    iconColor: Colors.orange.shade700,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Access Household Tasks from the bottom navigation bar.')),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.people_outline,
                    title: 'Family Avatars',
                    subtitle: 'Manage members',
                    color: Colors.blue.shade50,
                    iconColor: Colors.blue.shade700,
                    onTap: () {},
                  ),
                  _buildFeatureCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Groceries',
                    subtitle: 'Shared lists',
                    color: Colors.purple.shade50,
                    iconColor: Colors.purple.shade700,
                    onTap: () {},
                  ),
                  _buildFeatureCard(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'House preferences',
                    color: Colors.green.shade50,
                    iconColor: const Color(0xFF4A8B71),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}