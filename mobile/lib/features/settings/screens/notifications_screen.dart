import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationsScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const NotificationsScreen({super.key, required this.userEmail, required this.familyId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final resSettings = await http.get(Uri.parse('$baseUrl/${widget.userEmail}'));
      final resHistory = await http.get(Uri.parse('$baseUrl/notifications/${widget.userEmail}'));

      if (resSettings.statusCode == 200 && resHistory.statusCode == 200 && mounted) {
        setState(() {
          _settings = jsonDecode(resSettings.body);
          _history = List<Map<String, dynamic>>.from(
            (jsonDecode(resHistory.body) as List<dynamic>).map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          );
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
        title: const Text('Notifications', style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: green))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('General Controls', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Push Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
                        value: _settings['pushEnabled'] ?? true,
                        activeThumbColor: green,
                        onChanged: (v) => _updateSetting('pushEnabled', v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('In-App Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
                        value: _settings['inAppEnabled'] ?? true,
                        activeThumbColor: green,
                        onChanged: (v) => _updateSetting('inAppEnabled', v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Categories', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Column(
                    children: [
                      _categorySwitch('Tasks & Assignments', 'taskNotifications'),
                      _categorySwitch('Family Updates', 'familyNotifications'),
                      _categorySwitch('Health & Medicine', 'healthNotifications'),
                      _categorySwitch('Pets & Care', 'petNotifications'),
                      _categorySwitch('Documents Vault', 'docNotifications'),
                      _categorySwitch('Shopping & Maintenance', 'homeNotifications'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Recent Notification History', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                const SizedBox(height: 10),
                _history.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                        child: const Center(child: Text('No recent notifications.', style: TextStyle(color: textSecondary, fontSize: 12))),
                      )
                    : Column(
                        children: _history.map((n) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_active_outlined, color: forest, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(n['description'] ?? '', style: const TextStyle(color: textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
              ],
            ),
    );
  }

  Widget _categorySwitch(String title, String key) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark)),
      value: _settings[key] ?? true,
      activeThumbColor: green,
      onChanged: (v) => _updateSetting(key, v),
    );
  }
}