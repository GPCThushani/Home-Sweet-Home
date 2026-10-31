import 'package:flutter/material.dart';
import '../../family/services/family_service.dart';
import '../../family/models/family_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/main_navigation_shell.dart'; // Import your correct navigation shell

class JoinFamilyBottomSheet extends StatefulWidget {
  final String userEmail;
  final FamilyService? familyService;

  const JoinFamilyBottomSheet({
    super.key,
    required this.userEmail,
    this.familyService,
  });

  @override
  State<JoinFamilyBottomSheet> createState() => _JoinFamilyBottomSheetState();
}

class _JoinFamilyBottomSheetState extends State<JoinFamilyBottomSheet> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  late final FamilyService _familyService =
      widget.familyService ?? FamilyService();
  FamilyInvitation? _invitation;
  String? _selectedProfileId;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter an invite code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_invitation == null) {
        final invitation = await _familyService.previewInvitation(code);
        if (!mounted || code != _codeController.text.trim()) return;
        setState(() {
          _invitation = invitation;
          _selectedProfileId = invitation.profiles.length == 1
              ? invitation.profiles.single.id
              : null;
          if (invitation.profiles.isEmpty) {
            _errorMessage =
                'No available household profile was found. Ask your family admin to check the roster.';
          }
        });
        return;
      }
      final profileId = _selectedProfileId;
      if (profileId == null) {
        setState(
          () => _errorMessage = 'Select your existing household profile.',
        );
        return;
      }
      final familyId = await _familyService.joinFamily(
        inviteCode: code,
        profileId: profileId,
        familyId: _invitation!.familyId,
        nickname: nickname,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_family', true);
      await prefs.setString('current_family_id', familyId);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationShell(
            userEmail: widget.userEmail,
            familyId: familyId,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    if (widget.familyService == null) _familyService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join an Existing Family',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF244032),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the invite code provided by your family admin.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              enabled: !_isLoading,
              onChanged: (_) => setState(() {
                _invitation = null;
                _selectedProfileId = null;
                _errorMessage = null;
              }),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Invite Code (e.g. HSH-12AB34)',
                filled: true,
                fillColor: const Color(0xFFF8FAF9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF4A8B71)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: 'Your Nickname in Family (Optional)',
                hintText: 'e.g. Uncle John, Mom, Alex',
                filled: true,
                fillColor: const Color(0xFFF8FAF9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF4A8B71)),
                ),
              ),
            ),
            if (_invitation != null && _invitation!.profiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_invitation!.familyId),
                initialValue: _selectedProfileId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Your household profile',
                ),
                items: _invitation!.profiles
                    .map(
                      (profile) => DropdownMenuItem(
                        value: profile.id,
                        child: Text(
                          [profile.name, profile.relationship].join(' - '),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _selectedProfileId = value),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinFamily,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A8B71),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _invitation == null ? 'Find Family' : 'Join Family Space',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
