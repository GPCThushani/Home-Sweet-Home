import 'package:flutter/material.dart';

import '../services/family_service.dart';
import '../models/family_profile.dart';

class FamilyScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;
  final FamilyService? familyService;

  const FamilyScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
    this.familyService,
  });

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  late final FamilyService _familyService =
      widget.familyService ?? FamilyService();

  List<FamilyProfile> _members = [];

  bool _isLoading = true;
  String? _errorMessage;

  static const Color forest = Color(0xFF244032);
  static const Color green = Color(0xFF4A8B71);
  static const Color background = Color(0xFFF8FAF9);

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void didUpdateWidget(covariant FamilyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.familyId != widget.familyId) {
      _loadMembers();
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final requestedFamilyId = widget.familyId;
    try {
      final members = await _familyService.getFamilyProfiles(requestedFamilyId);

      if (!mounted || requestedFamilyId != widget.familyId) return;

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestedFamilyId != widget.familyId) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    if (widget.familyService == null) _familyService.close();
    super.dispose();
  }

  Future<void> _linkProfile(FamilyProfile profile) async {
    final familyId = widget.familyId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Is this your household profile?'),
        content: Text([profile.name, profile.relationship].join(' - ')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Link my account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || familyId != widget.familyId) return;
    setState(() => _isLoading = true);
    try {
      await _familyService.linkSelf(familyId, profile.id);
      if (mounted && familyId == widget.familyId) await _loadMembers();
    } catch (e) {
      if (!mounted || familyId != widget.familyId) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _avatarAsset(FamilyProfile member) {
    final role = member.relationship.toString().toLowerCase();

    final gender = (member.gender ?? '').toString().toLowerCase();

    if (role.contains('grandfather') || role.contains('grandpa')) {
      return 'assets/images/family_members/grandfather.jpg';
    }

    if (role.contains('grandmother') || role.contains('grandma')) {
      return 'assets/images/family_members/grandmother.jpg';
    }

    if (role.contains('father') || role.contains('dad')) {
      return 'assets/images/family_members/father.jpg';
    }

    if (role.contains('mother') || role.contains('mom')) {
      return 'assets/images/family_members/mother.jpg';
    }

    if (role.contains('daughter')) {
      return 'assets/images/family_members/daughter.jpg';
    }

    if (role.contains('son')) {
      return 'assets/images/family_members/son.jpg';
    }

    return gender == 'female'
        ? 'assets/images/family_members/female.jpg'
        : 'assets/images/family_members/male.jpg';
  }

  Widget _buildMemberCard(FamilyProfile member) {
    final name = member.name;
    final role = member.relationship;
    final hasAccount = member.hasAccount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECE7)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: const Color(0xFFE8F2ED),
            child: ClipOval(
              child: Image.asset(
                _avatarAsset(member),
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_rounded, color: green, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: forest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: hasAccount
                        ? const Color(0xFFE8F2ED)
                        : const Color(0xFFF1F3F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasAccount
                        ? (member.isSelf
                              ? 'Account linked (you)'
                              : 'Account linked')
                        : 'Not joined yet',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasAccount ? green : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!member.hasAccount && !_members.any((profile) => profile.isSelf))
            IconButton(
              tooltip: 'This is me - link my account',
              onPressed: () => _linkProfile(member),
              icon: const Icon(Icons.person_add_alt_1, color: green),
            )
          else
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9BAFA4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Our Family',
          style: TextStyle(color: forest, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loadMembers,
            tooltip: 'Refresh family members',
            icon: const Icon(Icons.refresh_rounded, color: green),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: green))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 42,
                      color: green,
                    ),
                    const SizedBox(height: 12),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadMembers,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMembers,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  const Text(
                    'Everyone belongs here',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: forest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All household members appear here, '
                    'whether they have joined the app or not.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2ED),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.family_restroom_rounded,
                          color: green,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_members.length} Family Members',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: forest,
                              ),
                            ),
                            const Text(
                              'Your complete family roster',
                              style: TextStyle(fontSize: 12, color: green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No family profiles have been added yet.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._members.map(_buildMemberCard),
                ],
              ),
            ),
    );
  }
}
