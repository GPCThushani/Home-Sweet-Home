import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../tasks/screens/global_tasks_screen.dart';

class HealthScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;
  final List<Map<String, dynamic>> initialFamilyMembers;

  const HealthScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
    required this.initialFamilyMembers,
  });

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  static const String baseUrl = 'http://localhost:8080/api';

  late List<Map<String, dynamic>> _familyMembers;
  String? _selectedMemberId;
  int _selectedTab = 0;
  int _currentNavIndex = 4;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  Map<String, dynamic>? _profile;
  List<dynamic> _medicines = [];
  List<dynamic> _appointments = [];
  List<dynamic> _records = [];
  List<dynamic> _documents = [];
  List<dynamic> _cycles = [];

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
  static const Color peach = Color(0xFFF4DDD2);

  @override
  void initState() {
    super.initState();
    _familyMembers = widget.initialFamilyMembers
        .map((member) => Map<String, dynamic>.from(member))
        .toList();

    if (_familyMembers.isNotEmpty) {
      _selectedMemberId = _getMemberId(_familyMembers.first)?.toString();
      _loadSelectedMember();
    }
  }

  String? _getMemberId(Map<String, dynamic> member) {
    return member['id']?.toString() ??
        member['memberId']?.toString() ??
        member['familyMemberId']?.toString();
  }

  Map<String, dynamic>? get _selectedMember {
    if (_selectedMemberId == null) return null;
    for (final member in _familyMembers) {
      if (_getMemberId(member) == _selectedMemberId) {
        return member;
      }
    }
    return null;
  }

  String _getFriendlyName(Map<String, dynamic> member) {
    final nickname = member['nickname']?.toString().trim();
    if (nickname != null && nickname.isNotEmpty && nickname.toLowerCase() != 'null') {
      return nickname;
    }

    final name = member['name']?.toString().trim();
    if (name != null && name.isNotEmpty && name.toLowerCase() != 'null') {
      return name;
    }

    if (member['user'] is Map) {
      final user = Map<String, dynamic>.from(member['user']);
      final userName = user['name']?.toString().trim();
      if (userName != null && userName.isNotEmpty) return userName;
      final email = user['email']?.toString();
      if (email != null && email.contains('@')) return email.split('@').first;
    }

    return 'Family Member';
  }

  String _getFriendlyRole(Map<String, dynamic> member) {
    final role = member['role']?.toString().trim();
    if (role != null && role.isNotEmpty && role.toUpperCase() != 'ADMIN') {
      return role[0].toUpperCase() + role.substring(1).toLowerCase();
    }

    if (member['user'] is Map) {
      final user = Map<String, dynamic>.from(member['user']);
      final userRole = user['role']?.toString().trim();
      if (userRole != null && userRole.isNotEmpty && userRole.toUpperCase() != 'ADMIN') {
        return userRole[0].toUpperCase() + userRole.substring(1).toLowerCase();
      }
    }

    final relationship = member['relationship']?.toString().trim();
    if (relationship != null && relationship.isNotEmpty) {
      return relationship;
    }

    return 'Family Member';
  }

  bool get _womensHealthEnabled {
    if (_profile?['womensHealthEnabled'] == true) return true;
    return false;
  }

  String? _getAvatarUrl(Map<String, dynamic> member) {
    final candidates = [
      member['avatarPath'],
      member['avatarUrl'],
      member['imageUrl'],
      member['photoUrl'],
      member['profilePicture'],
    ];

    for (final value in candidates) {
      final path = value?.toString().trim();
      if (path != null && path.isNotEmpty && path.toLowerCase() != 'null') return path;
    }

    if (member['user'] is Map) {
      final user = Map<String, dynamic>.from(member['user']);
      final userCandidates = [
        user['avatarPath'],
        user['avatarUrl'],
        user['imageUrl'],
        user['photoUrl'],
        user['profilePicture'],
      ];
      for (final value in userCandidates) {
        final path = value?.toString().trim();
        if (path != null && path.isNotEmpty && path.toLowerCase() != 'null') return path;
      }
    }

    return null;
  }

  Widget _buildAvatar(Map<String, dynamic> member, {double radius = 30}) {
    final name = _getFriendlyName(member);
    final path = _getAvatarUrl(member);

    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: paleGreen,
          backgroundImage: NetworkImage(path),
          onBackgroundImageError: (_, __) {},
        );
      } else if (path.startsWith('/') || path.startsWith('file://')) {
        final cleanPath = path.replaceFirst('file://', '');
        return CircleAvatar(
          radius: radius,
          backgroundColor: paleGreen,
          backgroundImage: FileImage(File(cleanPath)),
          onBackgroundImageError: (_, __) {},
        );
      } else if (path.startsWith('assets/')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: paleGreen,
          backgroundImage: AssetImage(path),
          onBackgroundImageError: (_, __) {},
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: paleGreen,
      child: Text(
        _getInitials(name),
        style: TextStyle(
          fontSize: radius * 0.52,
          fontWeight: FontWeight.w800,
          color: forest,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> _loadSelectedMember() async {
    final memberId = _selectedMemberId;
    if (memberId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _getProfile(widget.familyId, memberId),
        _getMedicines(widget.familyId, memberId),
        _getAppointments(widget.familyId, memberId),
        _getRecords(widget.familyId, memberId),
        _getDocuments(widget.familyId, memberId),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final medicines = results[1] as List<dynamic>;
      final appointments = results[2] as List<dynamic>;
      final records = results[3] as List<dynamic>;
      final documents = results[4] as List<dynamic>;

      List<dynamic> cycles = [];
      if (profile['womensHealthEnabled'] == true) {
        cycles = await _getCycles(widget.familyId, memberId);
      }

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _medicines = medicines;
        _appointments = appointments;
        _records = records;
        _documents = documents;
        _cycles = cycles;
        _isLoading = false;

        if (!_womensHealthEnabled && _selectedTab == 5) {
          _selectedTab = 0;
        }
      });
    } catch (e) {
      debugPrint('Health loading error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load health information. Please check connection.';
      });
    }
  }

  Future<Map<String, dynamic>> _getProfile(String familyId, String memberId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/profile/$familyId/$memberId'));
    if (response.statusCode == 404) return {};
    if (response.statusCode != 200) throw Exception('Profile request failed');
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  Future<List<dynamic>> _getMedicines(String familyId, String memberId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/medicines/$familyId/$memberId'));
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) throw Exception('Medicine request failed');
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<List<dynamic>> _getAppointments(String familyId, String memberId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/appointments/$familyId/$memberId'));
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) throw Exception('Appointment request failed');
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<List<dynamic>> _getRecords(String familyId, String memberId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/records/$familyId/$memberId'));
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) throw Exception('Records request failed');
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<List<dynamic>> _getDocuments(String familyId, String memberId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/documents/$familyId/$memberId'));
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) throw Exception('Documents request failed');
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<List<dynamic>> _getCycles(String familyId, String memberId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/womens-health/cycles/$familyId/$memberId'));
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) throw Exception('Cycle request failed');
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<void> _updateProfile(Map<String, dynamic> profile) async {
    if (_selectedMemberId == null) return;
    final response = await http.put(
      Uri.parse('$baseUrl/health/profile/${widget.familyId}/$_selectedMemberId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile),
    );
    if (response.statusCode != 200) throw Exception('Profile update failed');
  }

  Future<void> _deleteItem(String endpoint, dynamic id) async {
    final response = await http.delete(Uri.parse('$baseUrl/health/$endpoint/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Delete failed');
    }
  }

  Future<void> _addCycle({required DateTime startDate, DateTime? endDate, String? notes}) async {
    if (_selectedMemberId == null) return;
    final response = await http.post(
      Uri.parse('$baseUrl/health/womens-health/cycles/${widget.familyId}/$_selectedMemberId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'startDate': _formatDate(startDate),
        'endDate': endDate == null ? null : _formatDate(endDate),
        'notes': notes,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cycle save failed');
    }
  }

  Future<void> _endCycle(int cycleId, DateTime endDate) async {
    final response = await http.put(Uri.parse('$baseUrl/health/womens-health/cycles/$cycleId/end?endDate=${_formatDate(endDate)}'));
    if (response.statusCode != 200) throw Exception('Cycle end failed');
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return 'Date not available';
    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  int _calculateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    try {
      final dob = DateTime.parse(value);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  String _value(dynamic value) {
    if (value == null) return 'Not added';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return 'Not added';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final member = _selectedMember;

    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: Column(
          children: [
            // --- RESTORED GREEN SHADOW HEADER CONTAINER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: paleGreen.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: green.withValues(alpha: 0.2), width: 1.5)),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Health & Medicine', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('A safe place for your family’s health.', style: TextStyle(color: textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (_familyMembers.isNotEmpty) _buildFamilyMemberSelector(),
            if (_familyMembers.isNotEmpty) _buildTabs(),
            Expanded(
              child: _familyMembers.isEmpty
                  ? _buildNoFamilyMembers()
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator(color: green))
                      : _errorMessage != null
                          ? _buildErrorState()
                          : RefreshIndicator(
                              color: green,
                              backgroundColor: white,
                              onRefresh: _loadSelectedMember,
                              child: _buildContent(member),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: _familyMembers.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: forest,
              foregroundColor: white,
              elevation: 3,
              onPressed: () => _showAddRecordModal(),
              child: const Icon(Icons.add_rounded),
            ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildNoFamilyMembers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: paleGreen, shape: BoxShape.circle),
              child: const Icon(Icons.family_restroom_rounded, size: 42, color: forest),
            ),
            const SizedBox(height: 20),
            const Text('No family members yet', style: TextStyle(color: textDark, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Add family members during Family Setup to manage their health information here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberSelector() {
    return Container(
      height: 108,
      padding: const EdgeInsets.only(top: 5, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _familyMembers.length,
        itemBuilder: (context, index) {
          final member = _familyMembers[index];
          final id = _getMemberId(member);
          final selected = id == _selectedMemberId;
          final name = _getFriendlyName(member);
          final relationship = _getFriendlyRole(member);

          return GestureDetector(
            onTap: id == null
                ? null
                : () {
                    if (id == _selectedMemberId) return;
                    setState(() {
                      _selectedMemberId = id;
                      _selectedTab = 0;
                      _profile = null;
                      _medicines = [];
                      _appointments = [];
                      _records = [];
                      _documents = [];
                      _cycles = [];
                    });
                    _loadSelectedMember();
                  },
            child: SizedBox(
              width: 84,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: selected ? green : Colors.transparent, width: 2.5),
                        ),
                        child: _buildAvatar(member, radius: 28),
                      ),
                      if (selected)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(color: green, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, size: 13, color: white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? textDark : textSecondary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    relationship,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getTabs() {
    final tabs = ['Overview', 'Medicines', 'Appointments', 'Records', 'Documents'];
    if (_womensHealthEnabled) tabs.add("Women's Health");
    return tabs;
  }

  Widget _buildTabs() {
    final tabs = _getTabs();
    return Container(
      height: 54,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final selected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? forest : white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? forest : border),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: selected ? white : textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic>? member) {
    if (member == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [SizedBox(height: 100), Center(child: Text('Select a family member.'))],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMemberHeader(member),
          const SizedBox(height: 16),
          if (_selectedTab == 0) _buildOverview(),
          if (_selectedTab == 1) _buildMedicines(),
          if (_selectedTab == 2) _buildAppointments(),
          if (_selectedTab == 3) _buildRecords(),
          if (_selectedTab == 4) _buildDocuments(),
          if (_selectedTab == 5 && _womensHealthEnabled) _buildWomensHealth(),
        ],
      ),
    );
  }

  Widget _buildMemberHeader(Map<String, dynamic> member) {
    final name = _getFriendlyName(member);
    final relationship = _getFriendlyRole(member);
    final dob = _profile?['dateOfBirth']?.toString();
    final age = _calculateAge(dob);
    final bloodType = _value(_profile?['bloodType']);
    final allergies = _value(_profile?['allergies']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(member, radius: 31),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('$relationship${age > 0 ? " • $age years" : ""}', style: const TextStyle(color: textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _showEmergencyDialog(member),
                style: OutlinedButton.styleFrom(
                  foregroundColor: terracotta,
                  side: const BorderSide(color: Color(0xFFE9B7AC)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Emergency', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniInfo('Blood Type', bloodType)),
              Expanded(child: _miniInfo('Allergies', allergies)),
              Expanded(child: _miniInfo('Medicines', '${_medicines.length}')),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showEditProfileModal(member),
              icon: const Icon(Icons.edit_outlined, size: 15, color: green),
              label: const Text('Edit health profile', style: TextStyle(color: green, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 10)),
        const SizedBox(height: 3),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildOverview() {
    final profile = _profile ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Health at a Glance'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.75,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _statCard('Blood Type', _value(profile['bloodType'])),
            _statCard('Height', profile['heightCm'] != null ? '${profile["heightCm"]} cm' : 'Not added'),
            _statCard('Weight', profile['weightKg'] != null ? '${profile["weightKg"]} kg' : 'Not added'),
            _statCard('Date of Birth', _value(profile['dateOfBirth'])),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('Medical Information'),
        const SizedBox(height: 10),
        _infoCard(
          children: [
            _profileRow('Known conditions', _value(profile['knownConditions'])),
            _profileRow('Allergies', _value(profile['allergies'])),
            _profileRow('Previous surgeries', _value(profile['previousSurgeries'])),
            _profileRow('Previous hospitalizations', _value(profile['previousHospitalizations'])),
            _profileRow('Special notes', _value(profile['specialMedicalNotes'])),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('Primary Physician'),
        const SizedBox(height: 10),
        _infoCard(
          children: [
            _profileRow('Doctor', _value(profile['primaryPhysicianName'])),
            _profileRow('Phone', _value(profile['primaryPhysicianPhone'])),
            _profileRow('Hospital / Clinic', _value(profile['hospitalOrClinic'])),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('Insurance'),
        const SizedBox(height: 10),
        _infoCard(
          children: [
            _profileRow('Provider', _value(profile['insuranceProvider'])),
            _profileRow('Policy number', _value(profile['insurancePolicyNumber'])),
            _profileRow('Expiry', _value(profile['insuranceExpiryDate'])),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Medicines'),
        const SizedBox(height: 4),
        const Text('Current medicines, schedules and refill information.', style: TextStyle(color: textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        if (_medicines.isEmpty)
          _emptyState(
            icon: Icons.medication_outlined,
            title: 'No medicines added',
            message: 'Medicines added for this family member will appear here.',
            buttonText: 'Add medicine',
            onPressed: () => _showAddMedicineModal(),
          )
        else
          ..._medicines.map((medicine) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _medicineCard(medicine),
              )),
      ],
    );
  }

  Widget _medicineCard(dynamic medicine) {
    final map = Map<String, dynamic>.from(medicine);
    final id = map['id'];
    final name = _value(map['name']);
    final dosage = _value(map['dosage']);
    final frequency = _value(map['frequency']);
    final remaining = map['remainingQuantity'];
    final refill = map['refillThreshold'];

    return _card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: paleGreen, shape: BoxShape.circle),
            child: const Icon(Icons.medication_outlined, color: forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(dosage, style: const TextStyle(color: textSecondary, fontSize: 12)),
                const SizedBox(height: 3),
                Text(frequency, style: const TextStyle(color: textSecondary, fontSize: 12)),
                if (remaining != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Remaining: $remaining${refill != null ? " • Refill at $refill" : ""}', style: const TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: muted),
            onSelected: (value) async {
              if (value == 'edit') _showAddMedicineModal(existing: map);
              if (value == 'delete' && id != null) {
                try {
                  await _deleteItem('medicines', id);
                  if (!mounted) return;
                  await _loadSelectedMember();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine deleted.')));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete medicine.')));
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Appointments'),
        const SizedBox(height: 4),
        const Text('Doctor visits and follow-ups.', style: TextStyle(color: textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        if (_appointments.isEmpty)
          _emptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No appointments yet',
            message: 'Upcoming doctor visits and follow-ups will appear here.',
            buttonText: 'Add appointment',
            onPressed: () => _showAddAppointmentModal(),
          )
        else
          ..._appointments.map((appointment) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _appointmentCard(appointment),
              )),
      ],
    );
  }

  Widget _appointmentCard(dynamic appointment) {
    final map = Map<String, dynamic>.from(appointment);
    final id = map['id'];
    final doctor = _value(map['doctorName']);
    final specialty = map['specialty']?.toString() ?? '';
    final clinic = map['hospitalOrClinic']?.toString() ?? '';
    final date = map['appointmentDateTime']?.toString();
    final reason = map['reason']?.toString() ?? '';
    final status = map['status']?.toString() ?? 'UPCOMING';

    return _card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: peach, shape: BoxShape.circle),
            child: const Icon(Icons.calendar_today_outlined, color: terracotta),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(doctor, style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w800))),
                    _statusBadge(status),
                  ],
                ),
                if (specialty.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(specialty, style: const TextStyle(color: textSecondary, fontSize: 12))),
                const SizedBox(height: 6),
                Text(_formatDateTime(date), style: const TextStyle(color: green, fontSize: 12, fontWeight: FontWeight.w700)),
                if (clinic.isNotEmpty) Text(clinic, style: const TextStyle(color: muted, fontSize: 11)),
                if (reason.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(reason, style: const TextStyle(color: textSecondary, fontSize: 12))),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: muted),
            onSelected: (value) async {
              if (value == 'edit') _showAddAppointmentModal(existing: map);
              if (value == 'delete' && id != null) {
                try {
                  await _deleteItem('appointments', id);
                  if (!mounted) return;
                  await _loadSelectedMember();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment deleted.')));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete appointment.')));
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final completed = status.toUpperCase() == 'COMPLETED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: completed ? paleGreen : const Color(0xFFFFF1E8), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: completed ? forest : terracotta, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Health Records'),
        const SizedBox(height: 4),
        const Text('Medical history, reports and notes.', style: TextStyle(color: textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        if (_records.isEmpty)
          _emptyState(
            icon: Icons.folder_open_outlined,
            title: 'No health records yet',
            message: 'Blood reports, prescriptions, diagnoses and other records will appear here.',
            buttonText: 'Add record',
            onPressed: () => _showAddRecordModal(),
          )
        else
          ..._records.map((record) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _recordCard(record),
              )),
      ],
    );
  }

  Widget _recordCard(dynamic record) {
    final map = Map<String, dynamic>.from(record);
    final id = map['id'];
    final title = _value(map['title']);
    final category = _value(map['category']);
    final date = map['recordDate']?.toString() ?? '';
    final details = map['details']?.toString() ?? '';

    return _card(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: paleGreen, shape: BoxShape.circle),
            child: const Icon(Icons.description_outlined, color: forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(category, style: const TextStyle(color: terracotta, fontSize: 11, fontWeight: FontWeight.w700)),
                if (date.isNotEmpty) Text(date, style: const TextStyle(color: muted, fontSize: 11)),
                if (details.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(details, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: textSecondary, fontSize: 12))),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') _showAddRecordModal(existing: map);
              if (value == 'delete' && id != null) {
                try {
                  await _deleteItem('records', id);
                  if (!mounted) return;
                  await _loadSelectedMember();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted.')));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete record.')));
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Medical Documents'),
        const SizedBox(height: 4),
        const Text('Prescriptions, insurance and important health files.', style: TextStyle(color: textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        if (_documents.isEmpty)
          _emptyState(
            icon: Icons.folder_copy_outlined,
            title: 'No documents yet',
            message: 'Important medical documents can be stored for quick access during emergencies.',
            buttonText: 'Add document',
            onPressed: () => _showAddDocumentMessage(),
          )
        else
          ..._documents.map((document) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _documentCard(document),
              )),
      ],
    );
  }

  Widget _documentCard(dynamic document) {
    final map = Map<String, dynamic>.from(document);
    final title = _value(map['title']);
    final category = _value(map['category']);
    final date = map['uploadedDate']?.toString() ?? '';
    final id = map['id'];

    return _card(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: paleGreen, shape: BoxShape.circle),
            child: const Icon(Icons.insert_drive_file_outlined, color: forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: textDark, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(category, style: const TextStyle(color: textSecondary, fontSize: 11)),
                if (date.isNotEmpty) Text(date, style: const TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          if (id != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () async {
                try {
                  await _deleteItem('documents', id);
                  if (!mounted) return;
                  await _loadSelectedMember();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted.')));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete document.')));
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWomensHealth() {
    final latestCycle = _cycles.isNotEmpty ? Map<String, dynamic>.from(_cycles.first) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Women's Health"),
        const SizedBox(height: 4),
        const Text('Cycle tracking and personal health information.', style: TextStyle(color: textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        _buildCycleSummary(latestCycle),
        const SizedBox(height: 16),
        _buildCycleCalendar(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startPeriod,
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('Start period'),
                style: ElevatedButton.styleFrom(backgroundColor: terracotta, foregroundColor: white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _endCurrentCycle,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('End period'),
                style: OutlinedButton.styleFrom(foregroundColor: terracotta, minimumSize: const Size(0, 48), side: const BorderSide(color: Color(0xFFE3B2A4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('Cycle History'),
        const SizedBox(height: 10),
        _buildCycleHistory(),
        const SizedBox(height: 20),
        _buildPrivateHealthNotice(),
      ],
    );
  }

  Widget _buildCycleSummary(Map<String, dynamic>? cycle) {
    if (cycle == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: peach, borderRadius: BorderRadius.circular(18)),
        child: const Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: terracotta),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start tracking your cycle', style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Add the first period date to begin building personal history.', style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final start = _value(cycle['startDate']);
    final end = cycle['endDate']?.toString();
    final length = cycle['periodLength'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: peach, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8C1B5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_border_rounded, color: terracotta),
              const SizedBox(width: 8),
              const Expanded(child: Text('Current cycle', style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w800))),
              if (end == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(8)),
                  child: const Text('ONGOING', style: TextStyle(color: terracotta, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Started: $start', style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(end == null ? 'End date has not been recorded.' : 'Ended: $end', style: const TextStyle(color: textSecondary, fontSize: 12)),
          if (length != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Period length: $length days', style: const TextStyle(color: textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildCycleCalendar() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: CalendarDatePicker(
        initialDate: now,
        firstDate: DateTime(now.year - 2),
        lastDate: DateTime(now.year + 1),
        onDateChanged: _showCycleDateOptions,
      ),
    );
  }

  Future<void> _showCycleDateOptions(DateTime date) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatDate(date), style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.water_drop_outlined, color: terracotta),
                  title: const Text('Mark period start'),
                  onTap: () => Navigator.pop(context, 'start'),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_calendar_outlined, color: green),
                  title: const Text('Add note'),
                  onTap: () => Navigator.pop(context, 'note'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == 'start') await _saveCycleStart(date);
    if (result == 'note') _showDateNoteDialog(date);
  }

  Future<void> _startPeriod() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (date != null) await _saveCycleStart(date);
  }

  Future<void> _saveCycleStart(DateTime date) async {
    setState(() => _isSaving = true);
    try {
      await _addCycle(startDate: date);
      if (!mounted) return;
      await _loadSelectedMember();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Period start date saved.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the cycle date.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _endCurrentCycle() async {
    if (_cycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There is no cycle to end yet.')));
      return;
    }
    final latest = Map<String, dynamic>.from(_cycles.first);
    final cycleId = latest['id'];
    if (cycleId == null) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (date == null) return;

    try {
      await _endCycle(int.parse(cycleId.toString()), date);
      if (!mounted) return;
      await _loadSelectedMember();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Period end date saved.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the end date.')));
    }
  }

  Widget _buildCycleHistory() {
    if (_cycles.isEmpty) {
      return _emptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No cycle history yet',
        message: 'Recorded cycles will appear here.',
        buttonText: 'Add period',
        onPressed: _startPeriod,
      );
    }

    return Column(
      children: _cycles.map((cycle) {
        final map = Map<String, dynamic>.from(cycle);
        final start = _value(map['startDate']);
        final end = map['endDate']?.toString();
        final length = map['periodLength'];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(15), border: Border.all(color: border)),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: terracotta),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$start → ${end ?? "Ongoing"}', style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w800)),
                    if (length != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text('$length days', style: const TextStyle(color: textSecondary, fontSize: 11))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivateHealthNotice() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: paleGreen, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 20, color: forest),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Private health information', style: TextStyle(color: forest, fontWeight: FontWeight.w800, fontSize: 13)),
                SizedBox(height: 4),
                Text('Women’s health information should follow member privacy permissions and should not automatically be visible to everyone.', style: TextStyle(color: textSecondary, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileModal(Map<String, dynamic> member) {
    final profile = Map<String, dynamic>.from(_profile ?? {});
    final dobController = TextEditingController(text: profile['dateOfBirth']?.toString() ?? '');
    final heightController = TextEditingController(text: profile['heightCm']?.toString() ?? '');
    final weightController = TextEditingController(text: profile['weightKg']?.toString() ?? '');
    final allergiesController = TextEditingController(text: profile['allergies']?.toString() ?? '');
    final conditionsController = TextEditingController(text: profile['knownConditions']?.toString() ?? '');
    final surgeryController = TextEditingController(text: profile['previousSurgeries']?.toString() ?? '');
    final hospitalizationController = TextEditingController(text: profile['previousHospitalizations']?.toString() ?? '');
    final notesController = TextEditingController(text: profile['specialMedicalNotes']?.toString() ?? '');
    final doctorController = TextEditingController(text: profile['primaryPhysicianName']?.toString() ?? '');
    final doctorPhoneController = TextEditingController(text: profile['primaryPhysicianPhone']?.toString() ?? '');
    final clinicController = TextEditingController(text: profile['hospitalOrClinic']?.toString() ?? '');
    final insuranceController = TextEditingController(text: profile['insuranceProvider']?.toString() ?? '');
    final policyController = TextEditingController(text: profile['insurancePolicyNumber']?.toString() ?? '');
    String selectedBloodType = profile['bloodType']?.toString() ?? 'Unknown';
    bool womensHealthEnabled = profile['womensHealthEnabled'] == true;
    bool emergencyAccessEnabled = profile['emergencyAccessEnabled'] != false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 22, right: 22, top: 22, bottom: MediaQuery.of(context).viewInsets.bottom + 22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Health Profile', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800))),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                    Text(_getFriendlyName(member), style: const TextStyle(color: textSecondary, fontSize: 13)),
                    const SizedBox(height: 22),
                    _modalSection('Personal Information'),
                    _inputField(dobController, 'Date of Birth', 'YYYY-MM-DD'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedBloodType,
                      decoration: _inputDecoration('Blood Type'),
                      items: ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setModalState(() => selectedBloodType = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _inputField(heightController, 'Height (cm)', 'e.g. 168', keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: _inputField(weightController, 'Weight (kg)', 'e.g. 62', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _modalSection('Medical Information'),
                    _inputField(allergiesController, 'Allergies', 'e.g. Penicillin, peanuts', maxLines: 2),
                    const SizedBox(height: 10),
                    _inputField(conditionsController, 'Known health conditions', 'e.g. Asthma, diabetes', maxLines: 2),
                    const SizedBox(height: 10),
                    _inputField(surgeryController, 'Previous surgeries', 'Optional', maxLines: 2),
                    const SizedBox(height: 10),
                    _inputField(hospitalizationController, 'Previous hospitalizations', 'Optional', maxLines: 2),
                    const SizedBox(height: 10),
                    _inputField(notesController, 'Special medical notes', 'Important information for emergencies', maxLines: 3),
                    const SizedBox(height: 20),
                    _modalSection('Primary Physician'),
                    _inputField(doctorController, 'Primary physician', 'Doctor name'),
                    const SizedBox(height: 10),
                    _inputField(doctorPhoneController, 'Physician phone', 'Phone number', keyboardType: TextInputType.phone),
                    const SizedBox(height: 10),
                    _inputField(clinicController, 'Hospital / Clinic', 'Hospital or clinic name'),
                    const SizedBox(height: 20),
                    _modalSection('Insurance'),
                    _inputField(insuranceController, 'Insurance provider', 'Provider name'),
                    const SizedBox(height: 10),
                    _inputField(policyController, 'Policy number', 'Policy number'),
                    const SizedBox(height: 20),
                    _modalSection('Privacy & Health Access'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Emergency access', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Allow permitted family members to access emergency health information.', style: TextStyle(fontSize: 11)),
                      value: emergencyAccessEnabled,
                      activeThumbColor: green,
                      onChanged: (value) => setModalState(() => emergencyAccessEnabled = value),
                    ),
                    if (_isFemaleMember(member))
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Women's Health", style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Enable private menstrual cycle and women’s health tracking.', style: TextStyle(fontSize: 11)),
                        value: womensHealthEnabled,
                        activeThumbColor: terracotta,
                        onChanged: (value) => setModalState(() => womensHealthEnabled = value),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                final updated = <String, dynamic>{
                                  'familyId': widget.familyId,
                                  'familyMemberId': _selectedMemberId,
                                  'dateOfBirth': dobController.text.trim(),
                                  'bloodType': selectedBloodType,
                                  'heightCm': double.tryParse(heightController.text.trim()),
                                  'weightKg': double.tryParse(weightController.text.trim()),
                                  'allergies': allergiesController.text.trim(),
                                  'knownConditions': conditionsController.text.trim(),
                                  'previousSurgeries': surgeryController.text.trim(),
                                  'previousHospitalizations': hospitalizationController.text.trim(),
                                  'specialMedicalNotes': notesController.text.trim(),
                                  'primaryPhysicianName': doctorController.text.trim(),
                                  'primaryPhysicianPhone': doctorPhoneController.text.trim(),
                                  'hospitalOrClinic': clinicController.text.trim(),
                                  'insuranceProvider': insuranceController.text.trim(),
                                  'insurancePolicyNumber': policyController.text.trim(),
                                  'womensHealthEnabled': womensHealthEnabled,
                                  'emergencyAccessEnabled': emergencyAccessEnabled,
                                };

                                try {
                                  await _updateProfile(updated);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  await _loadSelectedMember();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Health profile saved.')));
                                } catch (_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the health profile.')));
                                } finally {
                                  if (mounted) setState(() => _isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: forest,
                          foregroundColor: white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: white))
                            : const Text('Save health profile', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isFemaleMember(Map<String, dynamic> member) {
    final role = _getFriendlyRole(member).toLowerCase();
    return role.contains('mother') || role.contains('daughter') || role.contains('grandmother') || role.contains('female');
  }

  void _showAddMedicineModal({Map<String, dynamic>? existing}) {
    final nameController = TextEditingController(text: existing?['name']?.toString() ?? '');
    final dosageController = TextEditingController(text: existing?['dosage']?.toString() ?? '');
    final frequencyController = TextEditingController(text: existing?['frequency']?.toString() ?? '');
    final quantityController = TextEditingController(text: existing?['remainingQuantity']?.toString() ?? '');
    final refillController = TextEditingController(text: existing?['refillThreshold']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 22, right: 22, top: 22, bottom: MediaQuery.of(context).viewInsets.bottom + 22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Add Medicine' : 'Edit Medicine', style: const TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                _inputField(nameController, 'Medicine name', 'e.g. Metformin'),
                const SizedBox(height: 10),
                _inputField(dosageController, 'Dosage', 'e.g. 500 mg'),
                const SizedBox(height: 10),
                _inputField(frequencyController, 'Schedule', 'e.g. Morning after breakfast'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _inputField(quantityController, 'Remaining', 'e.g. 20', keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _inputField(refillController, 'Refill at', 'e.g. 5', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_selectedMemberId == null) return;
                      final url = existing == null
                          ? '$baseUrl/health/medicines/${widget.familyId}/$_selectedMemberId'
                          : '$baseUrl/health/medicines/${existing['id']}';

                      try {
                        final response = await (existing == null ? http.post : http.put)(
                          Uri.parse(url),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'name': nameController.text.trim(),
                            'dosage': dosageController.text.trim(),
                            'frequency': frequencyController.text.trim(),
                            'remainingQuantity': int.tryParse(quantityController.text.trim()),
                            'refillThreshold': int.tryParse(refillController.text.trim()),
                            'active': true,
                          }),
                        );
                        if (!mounted) return;
                        if (response.statusCode == 200 || response.statusCode == 201) {
                          Navigator.pop(context);
                          await _loadSelectedMember();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existing == null ? 'Medicine added.' : 'Medicine updated.')));
                        }
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save medicine.')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text(existing == null ? 'Save medicine' : 'Update medicine', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddAppointmentModal({Map<String, dynamic>? existing}) {
    final doctorController = TextEditingController(text: existing?['doctorName']?.toString() ?? '');
    final specialtyController = TextEditingController(text: existing?['specialty']?.toString() ?? '');
    final clinicController = TextEditingController(text: existing?['hospitalOrClinic']?.toString() ?? '');
    final reasonController = TextEditingController(text: existing?['reason']?.toString() ?? '');
    DateTime selectedDate = existing?['appointmentDateTime'] != null ? DateTime.parse(existing!['appointmentDateTime']) : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 22, right: 22, top: 22, bottom: MediaQuery.of(context).viewInsets.bottom + 22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing == null ? 'Add Appointment' : 'Edit Appointment', style: const TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    _inputField(doctorController, 'Doctor', 'Doctor name'),
                    const SizedBox(height: 10),
                    _inputField(specialtyController, 'Specialty', 'e.g. Physician'),
                    const SizedBox(height: 10),
                    _inputField(clinicController, 'Hospital / Clinic', 'Clinic name'),
                    const SizedBox(height: 10),
                    _inputField(reasonController, 'Reason', 'Why is this appointment?', maxLines: 2),
                    const SizedBox(height: 15),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined, color: green),
                      title: const Text('Appointment date'),
                      subtitle: Text(_formatDate(selectedDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(DateTime.now().year - 1),
                          lastDate: DateTime(DateTime.now().year + 3),
                        );
                        if (date != null) setModalState(() => selectedDate = date);
                      },
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_selectedMemberId == null) return;
                          final url = existing == null
                              ? '$baseUrl/health/appointments/${widget.familyId}/$_selectedMemberId'
                              : '$baseUrl/health/appointments/${existing['id']}';

                          try {
                            final response = await (existing == null ? http.post : http.put)(
                              Uri.parse(url),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'doctorName': doctorController.text.trim(),
                                'specialty': specialtyController.text.trim(),
                                'hospitalOrClinic': clinicController.text.trim(),
                                'appointmentDateTime': selectedDate.toIso8601String(),
                                'reason': reasonController.text.trim(),
                                'status': existing?['status'] ?? 'UPCOMING',
                              }),
                            );
                            if (!mounted) return;
                            if (response.statusCode == 200 || response.statusCode == 201) {
                              Navigator.pop(context);
                              await _loadSelectedMember();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existing == null ? 'Appointment added.' : 'Appointment updated.')));
                            }
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save appointment.')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(existing == null ? 'Save appointment' : 'Update appointment', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddRecordModal({Map<String, dynamic>? existing}) {
    final titleController = TextEditingController(text: existing?['title']?.toString() ?? '');
    final detailsController = TextEditingController(text: existing?['details']?.toString() ?? '');
    String category = existing?['category']?.toString() ?? 'Medical Record';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 22, right: 22, top: 22, bottom: MediaQuery.of(context).viewInsets.bottom + 22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing == null ? 'Add Health Record' : 'Edit Health Record', style: const TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    _inputField(titleController, 'Title', 'e.g. Blood Test'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: _inputDecoration('Category'),
                      items: ['Medical Record', 'Blood Report', 'Prescription', 'Diagnosis', 'Hospital Visit', 'Other']
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setModalState(() => category = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    _inputField(detailsController, 'Details', 'Add notes about this record', maxLines: 4),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) return;
                          final url = existing == null
                              ? '$baseUrl/health/records/${widget.familyId}/$_selectedMemberId'
                              : '$baseUrl/health/records/${existing['id']}';

                          try {
                            final response = await (existing == null ? http.post : http.put)(
                              Uri.parse(url),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'category': category,
                                'title': titleController.text.trim(),
                                'details': detailsController.text.trim(),
                                'recordDate': _formatDate(DateTime.now()),
                              }),
                            );
                            if (!mounted) return;
                            if (response.statusCode == 200 || response.statusCode == 201) {
                              Navigator.pop(context);
                              await _loadSelectedMember();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existing == null ? 'Health record saved.' : 'Health record updated.')));
                            }
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save health record.')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(existing == null ? 'Save record' : 'Update record', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDocumentMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Medical Documents'),
          content: const Text('The document upload UI can be connected to your file storage service here.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _showEmergencyDialog(Map<String, dynamic> member) {
    final name = _getFriendlyName(member);
    final profile = _profile ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: Color(0xFFFFE9E4), shape: BoxShape.circle),
                      child: const Icon(Icons.medical_information_outlined, color: terracotta),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Emergency Health View', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(name, style: const TextStyle(color: textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _emergencyRow('Blood Type', _value(profile['bloodType'])),
                _emergencyRow('Allergies', _value(profile['allergies'])),
                _emergencyRow('Conditions', _value(profile['knownConditions'])),
                _emergencyRow('Important Notes', _value(profile['specialMedicalNotes'])),
                _emergencyRow('Primary Physician', _value(profile['primaryPhysicianName'])),
                _emergencyRow('Physician Phone', _value(profile['primaryPhysicianPhone'])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emergencyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 125, child: Text(label, style: const TextStyle(color: muted, fontSize: 11))),
          Expanded(child: Text(value, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  void _showDateNoteDialog(DateTime date) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Note • ${_formatDate(date)}'),
          content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(hintText: 'Add a private note...')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
          ],
        );
      },
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
          BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), activeIcon: Icon(Icons.menu_rounded), label: 'More'),
        ],
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GlobalTasksScreen(
                  userEmail: widget.userEmail,
                  familyId: widget.familyId,
                ),
              ),
            );
          } else if (index == 4) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off_rounded, size: 54, color: muted),
        const SizedBox(height: 18),
        const Text('Could not load health information', textAlign: TextAlign.center, style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(_errorMessage ?? 'Please try again.', textAlign: TextAlign.center, style: const TextStyle(color: textSecondary, fontSize: 12)),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton(
            onPressed: _loadSelectedMember,
            style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white),
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: paleGreen, shape: BoxShape.circle),
            child: Icon(icon, color: forest, size: 27),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: textSecondary, fontSize: 11, height: 1.4)),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: Text(buttonText),
              style: OutlinedButton.styleFrom(foregroundColor: green, side: const BorderSide(color: green)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w800));
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: child,
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return _card(child: Column(children: children));
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: muted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 135, child: Text(label, style: const TextStyle(color: muted, fontSize: 11))),
          Expanded(child: Text(value, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _modalSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w800)),
    );
  }

  Widget _inputField(TextEditingController controller, String label, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: green)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }
}