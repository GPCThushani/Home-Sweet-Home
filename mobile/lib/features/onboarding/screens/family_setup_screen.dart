import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'add_family_members_screen.dart'; // Import Step 5 screen

class FamilySetupScreen extends StatefulWidget {
  final String userEmail;

  const FamilySetupScreen({super.key, required this.userEmail});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _familyNameController = TextEditingController();
  final _familyMottoController = TextEditingController();
  final _locationController = TextEditingController();
  final _timezoneController = TextEditingController();

  int? _selectedPresetIndex;
  File? _customImageFile;
  bool _isAutoDetectingLocation = false;

  final List<String> _presetAvatars = [
    'assets/images/family_avatars/avatar_1.png',
    'assets/images/family_avatars/avatar_2.jpg',
    'assets/images/family_avatars/avatar_3.jpg',
    'assets/images/family_avatars/avatar_4.jpg',
    'assets/images/family_avatars/avatar_5.jpg',
    'assets/images/family_avatars/avatar_6.jpg',
    'assets/images/family_avatars/avatar_7.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _autoDetectTimezone();
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _familyMottoController.dispose();
    _locationController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _autoDetectTimezone() {
    final currentTimeZone = DateTime.now().timeZoneName;
    final timeZoneOffset = DateTime.now().timeZoneOffset;
    final hours = timeZoneOffset.inHours;
    final minutes = (timeZoneOffset.inMinutes % 60).abs();
    final sign = hours >= 0 ? '+' : '-';
    
    _timezoneController.text = 'UTC$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} ($currentTimeZone)';
  }

  void _autoDetectLocation() async {
    setState(() => _isAutoDetectingLocation = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _locationController.text = "Panadura, Western Province, Sri Lanka";
      _isAutoDetectingLocation = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location detected successfully!"), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _pickCustomImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _customImageFile = File(pickedFile.path);
        _selectedPresetIndex = null; 
      });
    }
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Tell us about your family',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF244032),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Personalize your family space and identity',
                style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose Family Logo or Photo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: _pickCustomImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _customImageFile != null ? const Color(0xFF4A8B71) : Colors.grey.shade300,
                            width: _customImageFile != null ? 2.5 : 1.5,
                          ),
                        ),
                        child: _customImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(_customImageFile!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF4A8B71), size: 28),
                                  SizedBox(height: 4),
                                  Text('Upload', style: TextStyle(fontSize: 11, color: Color(0xFF4A8B71), fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                    ...List.generate(_presetAvatars.length, (index) {
                      final isSelected = _selectedPresetIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPresetIndex = index;
                            _customImageFile = null;
                          });
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2ED),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF4A8B71) : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              _presetAvatars[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.face_rounded,
                                color: Color(0xFF4A8B71),
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabeledField(
                label: 'Family Name',
                hint: 'e.g. The Perera Family',
                icon: Icons.home_work_outlined,
                controller: _familyNameController,
              ),
              const SizedBox(height: 16),
              _buildLabeledField(
                label: 'Family Motto (Optional)',
                hint: 'e.g. Together Always',
                icon: Icons.format_quote_rounded,
                controller: _familyMottoController,
              ),
              const SizedBox(height: 16),
              _buildLabeledField(
                label: 'Location',
                hint: 'Tap Detect to fetch location',
                icon: Icons.location_on_outlined,
                controller: _locationController,
                suffixWidget: TextButton.icon(
                  onPressed: _isAutoDetectingLocation ? null : _autoDetectLocation,
                  icon: _isAutoDetectingLocation 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A8B71)))
                      : const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF4A8B71)),
                  label: const Text('Detect', style: TextStyle(fontSize: 12, color: Color(0xFF4A8B71), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabeledField(
                label: 'Timezone',
                hint: 'Auto-detected timezone',
                icon: Icons.access_time_rounded,
                controller: _timezoneController,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_familyNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter your family name."), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  // PASSING CUSTOM IMAGE PATH AND PRESET INDEX FORWARD
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddFamilyMembersScreen(
                        familyName: _familyNameController.text.trim(),
                        familyMotto: _familyMottoController.text.trim(),
                        customAvatarPath: _customImageFile?.path,
                        presetAvatarIndex: _selectedPresetIndex,
                        userEmail: widget.userEmail,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A8B71),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    Widget? suffixWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF244032),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey.shade400),
            suffixIcon: suffixWidget,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4A8B71), width: 1.5)),
          ),
        ),
      ],
    );
  }
}