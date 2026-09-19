import 'package:flutter/material.dart';
import 'home_ready_screen.dart';

class HomeFeatureItem {
  final String title;
  bool isSelected;

  HomeFeatureItem({required this.title, this.isSelected = true});
}

class HomeFeaturesScreen extends StatefulWidget {
  final String familyName;
  final String familyMotto;
  final String? customAvatarPath;
  final int? presetAvatarIndex;
  final int memberCount;
  final String userEmail;

  const HomeFeaturesScreen({
    super.key,
    required this.familyName,
    required this.familyMotto,
    this.customAvatarPath,
    this.presetAvatarIndex,
    required this.memberCount,
    required this.userEmail,
  });

  @override
  State<HomeFeaturesScreen> createState() => _HomeFeaturesScreenState();
}

class _HomeFeaturesScreenState extends State<HomeFeaturesScreen> {
  final List<HomeFeatureItem> _features = [
    HomeFeatureItem(title: 'Children / Study'),
    HomeFeatureItem(title: 'Pets'),
    HomeFeatureItem(title: 'Plants / Garden'),
    HomeFeatureItem(title: 'Household Finances'),
    HomeFeatureItem(title: 'Health & Medicine'),
    HomeFeatureItem(title: 'Shopping'),
    HomeFeatureItem(title: 'Home Maintenance'),
    HomeFeatureItem(title: 'Family Activities'),
  ];

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What's part of your home?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF244032),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    final feature = _features[index];
                    return CheckboxListTile(
                      title: Text(
                        feature.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF244032),
                        ),
                      ),
                      value: feature.isSelected,
                      activeColor: const Color(0xFF4A8B71),
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: const BorderSide(
                        color: Color(0xFF4A8B71),
                        width: 1.5,
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          feature.isSelected = value ?? true;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // PASSES EVERYTHING ONWARD TO HOMEREADYSCREEN
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeReadyScreen(
                        familyName: widget.familyName,
                        familyMotto: widget.familyMotto,
                        customAvatarPath: widget.customAvatarPath,
                        presetAvatarIndex: widget.presetAvatarIndex,
                        memberCount: widget.memberCount,
                        userEmail: widget.userEmail,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A8B71),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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