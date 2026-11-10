import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppSettingsScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const AppSettingsScreen({super.key, required this.userEmail, required this.familyId});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
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
        backgroundColor: paleGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: forest),
        title: const Text('App Settings', style: TextStyle(color: forest, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: green))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Appearance & Language', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Column(
                    children: [
                      _settingRow('Theme Mode', 'themeMode', ['Light', 'Dark', 'System Default']),
                      const Divider(height: 20),
                      _settingRow('App Language', 'appLanguage', ['English', 'Sinhala', 'Tamil']),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Regional Preferences', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Column(
                    children: [
                      _settingRow('Country', 'country', ['Sri Lanka', 'United States', 'United Kingdom', 'Australia']),
                      const Divider(height: 20),
                      _settingRow('Time Format', 'timeFormat', ['12-hour', '24-hour']),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('About Home Sweet Home', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Column(
                    children: [
                      const ListTile(title: Text('App Version', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)), trailing: Text('1.0.0', style: TextStyle(color: textSecondary, fontSize: 13))),
                      const Divider(height: 1),
                      ListTile(title: const Text('Terms & Conditions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)), onTap: () {}),
                      const Divider(height: 1),
                      ListTile(title: const Text('Privacy Policy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)), onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _settingRow(String title, String key, List<String> options) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
        DropdownButton<String>(
          value: _settings[key] ?? options.first,
          dropdownColor: white,
          underline: const SizedBox(),
          items: options.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
          onChanged: (v) => _updateSetting(key, v),
        ),
      ],
    );
  }
}