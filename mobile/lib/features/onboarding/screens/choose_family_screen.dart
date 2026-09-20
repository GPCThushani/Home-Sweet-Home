import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_or_join_family_screen.dart';
import 'join_family_bottom_sheet.dart';
import '../../../shared/widgets/main_navigation_shell.dart';

class FamilyModel {
  final String id;
  final String name;
  final int memberCount;
  final String? avatarPath;

  FamilyModel({
    required this.id,
    required this.name,
    required this.memberCount,
    this.avatarPath,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['id'].toString(),
      name: json['name'] ?? 'The Family',
      memberCount: json['memberCount'] ?? 1,
      avatarPath: json['avatarPath'] ?? json['customAvatarPath'] ?? json['avatar_path'],
    );
  }
}

class ChooseFamilyScreen extends StatefulWidget {
  final String userEmail;

  const ChooseFamilyScreen({super.key, required this.userEmail});

  @override
  State<ChooseFamilyScreen> createState() => _ChooseFamilyScreenState();
}

class _ChooseFamilyScreenState extends State<ChooseFamilyScreen> {
  bool _isLoading = true;
  List<FamilyModel> _families = [];

  @override
  void initState() {
    super.initState();
    _fetchUserFamilies();
  }

  Future<void> _fetchUserFamilies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      final url = Uri.parse('http://10.0.2.2:8080/api/families/user?email=${widget.userEmail}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _families = data.map((json) => FamilyModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _families = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user families: $e");
      setState(() {
        _families = [];
        _isLoading = false;
      });
    }
  }

  void _selectFamily(FamilyModel family) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainNavigationShell(
          userEmail: widget.userEmail,
          familyId: family.id,
        ),
      ),
      (route) => false,
    );
  }

  Widget _buildFamilyAvatar(String? path) {
    if (path == null || path.isEmpty) {
      return const Icon(
        Icons.family_restroom_rounded,
        color: Color(0xFF4A8B71),
        size: 28,
      );
    }

    if (path.startsWith('/') || path.startsWith('file://')) {
      final cleanPath = path.replaceFirst('file://', '');
      return ClipOval(
        child: Image.file(
          File(cleanPath),
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.family_restroom_rounded, color: Color(0xFF4A8B71), size: 28),
        ),
      );
    }

    if (path.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          path,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.family_restroom_rounded, color: Color(0xFF4A8B71), size: 28),
        ),
      );
    }

    return const Icon(
      Icons.family_restroom_rounded,
      color: Color(0xFF4A8B71),
      size: 28,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a Family',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF244032),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a household space to manage',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF4A8B71)),
                      )
                    : _families.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F2ED),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.group_off_rounded, size: 48, color: Color(0xFF4A8B71)),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No families found',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap below to create or join your first family space.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _families.length,
                            itemBuilder: (context, index) {
                              final family = _families[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFD0E0D8),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4A8B71).withValues(alpha: 0.06),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _selectFamily(family),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 58,
                                            height: 58,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFFE8F2ED),
                                              border: Border.all(
                                                color: const Color(0xFF4A8B71),
                                                width: 2,
                                              ),
                                            ),
                                            child: _buildFamilyAvatar(family.avatarPath),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  family.name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF244032),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.people_rounded, size: 14, color: Color(0xFF4A8B71)),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '${family.memberCount} ${family.memberCount == 1 ? 'member' : 'members'}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE8F2ED),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: Color(0xFF4A8B71),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateOrJoinFamilyScreen(
                        userEmail: widget.userEmail,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, color: Color(0xFF4A8B71), size: 22),
                label: const Text(
                  'Create a family space',
                  style: TextStyle(
                    color: Color(0xFF4A8B71),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFF4A8B71), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => JoinFamilyBottomSheet(userEmail: widget.userEmail),
                  );
                },
                icon: const Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
                label: const Text(
                  'Join with Invite Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A8B71),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}