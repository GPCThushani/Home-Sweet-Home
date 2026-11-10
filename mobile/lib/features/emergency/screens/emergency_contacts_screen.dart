import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../tasks/screens/global_tasks_screen.dart';
import '../../family/models/family_profile.dart';
import '../../family/services/family_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;
  final List<FamilyProfile> familyMembers;

  const EmergencyContactsScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
    required this.familyMembers,
  });

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  static const String baseUrl = 'http://localhost:8080/api';

  static const Color ivory = Color(0xFFFAF8F3);
  static const Color white = Colors.white;
  static const Color forest = Color(0xFF355C4A);
  static const Color green = Color(0xFF4A8B71);
  static const Color paleGreen = Color(0xFFE5EEE7);
  static const Color textDark = Color(0xFF244032);
  static const Color textSecondary = Color(0xFF65716B);
  static const Color muted = Color(0xFF98A19C);
  static const Color border = Color(0xFFE5E1D9);
  static const Color terracotta = Color(0xFFC98268);

  final FamilyService _familyApi = FamilyService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _personalContacts = [];
  List<FamilyProfile> _profiles = [];
  int _currentNavIndex = 4;

  final List<Map<String, String>> _emergencyServices = [
    {'name': 'Police Emergency', 'number': '119', 'desc': 'National police emergency hotline'},
    {'name': 'Ambulance / Medical', 'number': '1990', 'desc': 'Suwa Seriya free ambulance service'},
    {'name': 'Fire & Rescue', 'number': '110', 'desc': 'Fire department and rescue services'},
    {'name': 'Disaster Management', 'number': '117', 'desc': 'Emergency disaster operations center'},
    {'name': 'Accident Service (Hospital)', 'number': '0112691111', 'desc': 'National Hospital emergency desk'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _familyApi.close();
    super.dispose();
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
    };
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('$baseUrl/emergency-contacts/${widget.familyId}'), headers: headers);
      final profs = widget.familyMembers.isNotEmpty ? widget.familyMembers : await _familyApi.getFamilyProfiles(widget.familyId);

      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _personalContacts = List<Map<String, dynamic>>.from(decoded);
          _profiles = profs;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final sanitizedPhoneNumber = phoneNumber.trim();
    if (sanitizedPhoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available.')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dialing $sanitizedPhoneNumber is not available in this build.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: paleGreen.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: green.withValues(alpha: 0.2), width: 1.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency Contacts', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Quick access to emergency services and trusted contacts.', style: TextStyle(color: textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : RefreshIndicator(
                      color: green,
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text('Emergency Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDark)),
                          const SizedBox(height: 2),
                          const Text('Always available public emergency lines', style: TextStyle(fontSize: 11, color: textSecondary)),
                          const SizedBox(height: 10),
                          ..._emergencyServices.map(_buildServiceCard),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Personal Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDark)),
                                  const SizedBox(height: 2),
                                  Text('${_personalContacts.length} trusted contacts', style: const TextStyle(fontSize: 11, color: textSecondary)),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _showAddContactModal,
                                icon: const Icon(Icons.add_rounded, size: 16, color: forest),
                                label: const Text('Add Contact', style: TextStyle(color: forest, fontWeight: FontWeight.w800, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _personalContacts.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                  child: const Center(
                                    child: Text('No personal emergency contacts added yet.', style: TextStyle(color: muted, fontSize: 12)),
                                  ),
                                )
                              : Column(children: _personalContacts.map(_buildPersonalContactCard).toList()),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildServiceCard(Map<String, String> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: paleGreen, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_hospital_rounded, color: forest, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
                const SizedBox(height: 2),
                Text(service['desc']!, style: const TextStyle(fontSize: 11, color: textSecondary)),
                const SizedBox(height: 2),
                Text(service['number']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: terracotta)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _makeCall(service['number']!),
            style: ElevatedButton.styleFrom(
              backgroundColor: forest,
              foregroundColor: white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.call_rounded, size: 14),
            label: const Text('Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalContactCard(Map<String, dynamic> contact) {
    final name = contact['fullName']?.toString() ?? 'Contact';
    final relationship = contact['relationship']?.toString() ?? 'Family member';
    final phone = contact['phoneNumber']?.toString() ?? '';
    final priority = contact['priority']?.toString() ?? 'Secondary';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: paleGreen,
            child: Text(initials, style: const TextStyle(color: forest, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priority == 'Primary' ? paleGreen : ivory,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: priority == 'Primary' ? green : border),
                      ),
                      child: Text(priority, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: priority == 'Primary' ? forest : textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$relationship · $phone', style: const TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteContact(contact['id'].toString()),
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: muted),
          ),
          ElevatedButton(
            onPressed: () => _makeCall(phone),
            style: ElevatedButton.styleFrom(
              backgroundColor: forest,
              foregroundColor: white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddContactModal() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final altPhoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    const availableRelationships = ['Parent', 'Spouse', 'Relative', 'Neighbour', 'Doctor', 'Friend', 'Other'];
    String relationship = 'Relative';
    
    const availablePriorities = ['Primary', 'Secondary'];
    String priority = 'Secondary';
    
    String category = 'Family member';
    String? linkedProfileId;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 20, 22, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add Emergency Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                    IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(sheetContext)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_profiles.isNotEmpty) ...[
                  const Text('Link existing family profile (Optional)', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: linkedProfileId,
                    dropdownColor: white,
                    decoration: _inputDecoration('Select family member'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None (Custom contact)', style: TextStyle(fontSize: 13))),
                      ..._profiles.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text('${p.name} (${p.relationship})', style: TextStyle(fontSize: 13)))),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        linkedProfileId = val;
                        if (val != null) {
                          final match = _profiles.firstWhere((p) => p.id == val);
                          nameController.text = match.name;
                          if (availableRelationships.contains(match.relationship)) {
                            relationship = match.relationship;
                          } else {
                            relationship = 'Relative';
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: nameController, decoration: _inputDecoration('e.g. John Doe')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Relationship', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: relationship,
                            dropdownColor: white,
                            decoration: _inputDecoration('Relationship'),
                            items: availableRelationships
                                .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => relationship = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority Status', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: priority,
                            dropdownColor: white,
                            decoration: _inputDecoration('Priority'),
                            items: availablePriorities
                                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => priority = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration('e.g. +94 77 123 4567')),
                const SizedBox(height: 12),
                const Text('Alternative Phone (Optional)', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: altPhoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration('Optional')),
                const SizedBox(height: 12),
                const Text('Email & Address (Optional)', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: TextField(controller: emailController, decoration: _inputDecoration('Email'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: addressController, decoration: _inputDecoration('Address'))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: forest,
                      foregroundColor: white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: saving ? null : () async {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      if (name.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and phone number.')));
                        return;
                      }

                      setModalState(() => saving = true);
                      try {
                        final headers = await _authHeaders();
                        final body = {
                          'fullName': name,
                          'relationship': relationship,
                          'phoneNumber': phone,
                          'altPhoneNumber': altPhoneController.text.trim(),
                          'email': emailController.text.trim(),
                          'address': addressController.text.trim(),
                          'priority': priority,
                          'category': category,
                          'familyProfileId': linkedProfileId,
                        };

                        final res = await http.post(
                          Uri.parse('$baseUrl/emergency-contacts/${widget.familyId}'),
                          headers: headers,
                          body: jsonEncode(body),
                        );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await _loadData();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact added successfully!')));
                        }
                      } catch (_) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save contact.')));
                      } finally {
                        if (sheetContext.mounted) setModalState(() => saving = false);
                      }
                    },
                    child: Text(saving ? 'Saving...' : 'Save Contact', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteContact(String id) async {
    try {
      final headers = await _authHeaders();
      final res = await http.delete(Uri.parse('$baseUrl/emergency-contacts/$id'), headers: headers);
      if (res.statusCode == 200 || res.statusCode == 204) {
        await _loadData();
      }
    } catch (_) {}
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: muted, fontSize: 12),
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: green)),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(color: white, border: Border(top: BorderSide(color: border))),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: white,
        selectedItemColor: green,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group_rounded), label: 'Family'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today_rounded), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.task_outlined), activeIcon: Icon(Icons.task_rounded), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_outlined), activeIcon: Icon(Icons.menu_rounded), label: 'More'),
        ],
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GlobalTasksScreen(userEmail: widget.userEmail, familyId: widget.familyId),
              ),
            );
          } else if (index == 4) {
            Navigator.maybePop(context);
          }
        },
      ),
    );
  }
}