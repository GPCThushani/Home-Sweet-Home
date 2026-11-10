import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PrivacyScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const PrivacyScreen({super.key, required this.userEmail, required this.familyId});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const String baseUrl = 'http://localhost:8080/api/settings';
  static const Color ivory = Color(0xFFFAF8F3);
  static const Color white = Colors.white;
  static const Color forest = Color(0xFF355C4A);
  static const Color green = Color(0xFF4A8B71);
  static const Color paleGreen = Color(0xFFE5EEE7);
  static const Color textDark = Color(0xFF244032);
  static const Color textSecondary = Color(0xFF65716B);
  static const Color border = Color(0xFFE5E1D9);

  bool _isLoading = true;
  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/${widget.userEmail}'));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _settings = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() => _settings[key] = value);
    await http.put(
      Uri.parse('$baseUrl/${widget.userEmail}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: paleGreen.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('Privacy & Permissions', style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: green))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Data Visibility Rules', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Column(
                    children: [
                      _visibilityDropdown('Family Profile Visibility', 'familyVisibility'),
                      const Divider(height: 20),
                      _visibilityDropdown('Document Vault Visibility', 'documentVisibility'),
                      const Divider(height: 20),
                      _visibilityDropdown('Pet Information Visibility', 'petVisibility'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Device Permissions', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Column(
                    children: [
                      _permissionTile('Camera', 'Capture profile photos and documents', Icons.camera_alt_outlined),
                      const Divider(height: 1),
                      _permissionTile('Photos / Gallery', 'Select images and uploads', Icons.photo_library_outlined),
                      const Divider(height: 1),
                      _permissionTile('Notifications', 'Receive household reminders', Icons.notifications_outlined),
                      const Divider(height: 1),
                      _permissionTile('Location', 'Emergency and proximity features', Icons.location_on_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Account Security & Data', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Download My Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
                        trailing: const Icon(Icons.download_rounded, size: 18, color: forest),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data export requested.'))),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Request Account Deletion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
                        trailing: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.red),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _visibilityDropdown(String title, String key) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
        DropdownButton<String>(
          value: _settings[key] ?? 'Family Only',
          dropdownColor: white,
          underline: const SizedBox(),
          items: ['Public', 'Family Only', 'Private']
              .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))))
              .toList(),
          onChanged: (v) => _updateSetting(key, v),
        ),
      ],
    );
  }

  Widget _permissionTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: forest, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: textSecondary)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: paleGreen, borderRadius: BorderRadius.circular(8)),
        child: const Text('Allowed', style: TextStyle(color: forest, fontSize: 11, fontWeight: FontWeight.w800)),
      ),
    );
  }
}