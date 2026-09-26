import 'package:flutter/material.dart';

class HealthScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const HealthScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  String _selectedMember = 'Me (Father)';
  int _selectedTab = 0; // 0: Overview, 1: Medicines, 2: Profile & Vitals, 3: Appointments

  // Mock data for family members including full comprehensive health records
  final List<Map<String, dynamic>> _familyMembers = [
    {
      'name': 'Me (Father)',
      'role': 'Parent',
      'avatar': Icons.person_rounded,
      'bloodType': 'O+',
      'age': 42,
      'dob': '14 Mar 1984',
      'height': '178 cm',
      'weight': '76 kg',
      'allergies': 'Penicillin, Peanuts',
      'conditions': 'Hypertension',
      'physician': 'Dr. Rohan Silva (077 123 4567)',
      'insurance': 'AIA Health Platinum (#AIA-987654)',
    },
    {
      'name': 'Daughter',
      'role': 'Teen/Student',
      'avatar': Icons.face_3_rounded,
      'bloodType': 'A+',
      'age': 16,
      'dob': '22 Jul 2010',
      'height': '162 cm',
      'weight': '50 kg',
      'allergies': 'None Known',
      'conditions': 'Asthma (Mild)',
      'physician': 'Dr. Nimal Perera (011 234 5678)',
      'insurance': 'Sri Lanka Insurance (#SLI-112233)',
    },
    {
      'name': 'Grandmother Chandra',
      'role': 'Grandparent',
      'avatar': Icons.elderly_rounded,
      'bloodType': 'B+',
      'age': 74,
      'dob': '05 Nov 1951',
      'height': '150 cm',
      'weight': '58 kg',
      'allergies': 'Aspirin',
      'conditions': 'High Blood Pressure, Mild Arthritis',
      'physician': 'Dr. Wijesinghe (033 456 7890)',
      'insurance': 'Ceylinco Healthcare (#CEY-554433)',
    },
  ];

  Map<String, dynamic> get _currentMemberData {
    return _familyMembers.firstWhere(
      (m) => m['name'] == _selectedMember,
      orElse: () => _familyMembers[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = _currentMemberData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Health & Medicine',
          style: TextStyle(
            color: Color(0xFF244032),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4A8B71), size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add health record / medicine modal coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MEMBER SELECTOR (Everyone's profile visible for emergency / transparency) ---
            SizedBox(
              height: 55,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _familyMembers.length,
                itemBuilder: (context, index) {
                  final m = _familyMembers[index];
                  final isSelected = _selectedMember == m['name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Text(m['name']),
                      avatar: Icon(
                        m['avatar'],
                        size: 18,
                        color: isSelected ? Colors.white : const Color(0xFF4A8B71),
                      ),
                      selectedColor: const Color(0xFF4A8B71),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF244032),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF4A8B71) : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedMember = m['name']);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // --- TAB VIEWS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton('Overview', 0),
                    const SizedBox(width: 8),
                    _buildTabButton('Medicines', 1),
                    const SizedBox(width: 8),
                    _buildTabButton('Profile & Vitals', 2),
                    const SizedBox(width: 8),
                    _buildTabButton('Appointments', 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- TAB CONTENT ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                children: [
                  // Emergency Quick Header Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD0E0D8), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF4A8B71),
                          child: Icon(Icons.medical_services_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Viewing Health Profile for:',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${member['name']} (${member['role']})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
                              ),
                            ],
                          ),
                        ),
                        // Emergency badge indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.emergency_outlined, size: 14, color: Colors.red.shade800),
                              const SizedBox(width: 4),
                              Text('SOS Ready', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CONDITIONAL RENDERING BASED ON SELECTED TAB
                  if (_selectedTab == 0 || _selectedTab == 1) ...[
                    // Medicines Section
                    const Text(
                      'Scheduled Medicines',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
                    ),
                    const SizedBox(height: 10),
                    _buildMedicineCard(
                      title: member['name'] == 'Grandmother Chandra' ? 'Blood Pressure Pill' : 'Daily Vitamin & Supplement',
                      time: '8:00 AM',
                      dosage: '1 tablet',
                      accentColor: Colors.teal,
                      isTaken: true,
                    ),
                    const SizedBox(height: 12),
                    _buildMedicineCard(
                      title: member['name'] == 'Grandmother Chandra' ? 'Arthritis Relief' : 'General Maintenance Med',
                      time: '8:00 PM',
                      dosage: '1 tablet',
                      accentColor: Colors.deepPurple,
                      isTaken: false,
                    ),
                    const SizedBox(height: 16),
                    // Refill alert
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 26),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Refill needed soon',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Only 5 tablets left for ${member['name']}',
                                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_selectedTab == 2) ...[
                    // COMPREHENSIVE PROFILE & VITALS SECTION
                    const Text(
                      'Confidential Health Record & Vitals',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildVitalBox('Blood Type', member['bloodType'], Icons.bloodtype_outlined, Colors.red),
                              _buildVitalBox('Age / DOB', '${member['age']} yrs', Icons.cake_outlined, Colors.orange),
                              _buildVitalBox('Height / Wt', '${member['height']}\n${member['weight']}', Icons.monitor_weight_outlined, Colors.teal),
                            ],
                          ),
                          const Divider(height: 30, thickness: 1),
                          _buildProfileRow('Date of Birth', member['dob']),
                          _buildProfileRow('Known Allergies', member['allergies'], isHighlighted: true),
                          _buildProfileRow('Health Conditions', member['conditions']),
                          _buildProfileRow('Primary Physician', member['physician']),
                          _buildProfileRow('Insurance Details', member['insurance']),
                        ],
                      ),
                    ),
                  ],

                  if (_selectedTab == 3) ...[
                    // Appointments Section
                    const Text(
                      'Upcoming Doctor Visits',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F2ED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF4A8B71), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'General Health Checkup',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dr. Silva • Next Monday, 10:30 AM',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF244032) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF244032) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildVitalBox(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF244032))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildProfileRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.red.shade700 : const Color(0xFF244032),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard({
    required String title,
    required String time,
    required String dosage,
    required Color accentColor,
    required bool isTaken,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF244032),
                            ),
                          ),
                          Text(
                            dosage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isTaken ? const Color(0xFFE8F2ED) : const Color(0xFF4A8B71),
                            foregroundColor: isTaken ? const Color(0xFF4A8B71) : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(isTaken ? Icons.check_rounded : Icons.task_alt_rounded, size: 18),
                          label: Text(
                            isTaken ? 'Taken Today' : 'Mark as taken',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}