import 'package:flutter/material.dart';
import '../../health/screens/health_screen.dart';
import '../../shopping/screens/shopping_screens.dart';
import '../../garden/screens/plants_garden_screen.dart';
import '../../maintenance/screens/home_maintenance_screen.dart';
import '../../together/screens/together_screen.dart';
import '../../documents/screens/documents_screen.dart';

class MoreScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const MoreScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'More / Settings',
          style: TextStyle(
            color: Color(0xFF244032),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
          children: [
            const Text(
              'Available for your family',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // --- MODULES SECTION ---
            _buildSectionContainer([
              _buildMenuItem(
                icon: Icons.medical_services_outlined,
                iconColor: Colors.red.shade700,
                title: 'Health',
                onTap: () => _navigateToHealth(context),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.shopping_bag_outlined,
                iconColor: Colors.orange.shade700,
                title: 'Shopping',
                onTap: () => _navigateToShopping(context),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.grass_rounded,
                iconColor: Colors.green.shade700,
                title: 'Plants / Garden',
                onTap: () => _navigateToGarden(context),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.home_repair_service_outlined,
                iconColor: Colors.brown.shade400,
                title: 'Home Maintenance',
                onTap: () => _navigateToMaintenance(context),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.group_rounded,
                iconColor: Colors.purple.shade600,
                title: 'Together',
                onTap: () => _navigateToTogether(context),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.folder_open_rounded,
                iconColor: Colors.blue.shade600,
                title: 'Documents',
                onTap: () => _navigateToDocuments(context),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.emergency_outlined,
                iconColor: Colors.red.shade600,
                title: 'Emergency Contacts',
                onTap: () => _navigateTo(context, 'Emergency Contacts'),
              ),
            ]),

            const SizedBox(height: 24),
            const Text(
              'Preferences & App',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // --- SYSTEM / SETTINGS SECTION ---
            _buildSectionContainer([
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFF4A8B71),
                title: 'Notifications',
                onTap: () => _navigateTo(context, 'Notifications'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFF4A8B71),
                title: 'Privacy & Permissions',
                onTap: () => _navigateTo(context, 'Privacy & Permissions'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                iconColor: const Color(0xFF4A8B71),
                title: 'Settings',
                onTap: () => _navigateTo(context, 'Settings'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToHealth(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthScreen(
          userEmail: widget.userEmail,
          familyId: widget.familyId,
          initialFamilyMembers: const [],
        ),
      ),
    );
  }

  void _navigateToShopping(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingScreen(
          userEmail: widget.userEmail,
          familyId: widget.familyId,
        ),
      ),
    );
  }

  void _navigateToGarden(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantsGardenScreen(
          userEmail: widget.userEmail,
          familyId: widget.familyId,
        ),
      ),
    );
  }

  void _navigateToMaintenance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeMaintenanceScreen(
          userEmail: widget.userEmail,
          familyId: widget.familyId,
        ),
      ),
    );
  }

  void _navigateToTogether(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TogetherScreen(
          userEmail: widget.userEmail,
          familyId: widget.familyId,
        ),
      ),
    );
  }

  void _navigateToDocuments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentsScreen(
          userEmail: widget.userEmail,
          familyId: widget.familyId, familyMembers: [],
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
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
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF244032),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 60,
    );
  }

  void _navigateTo(BuildContext context, String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$moduleName module coming soon!'),
        backgroundColor: const Color(0xFF4A8B71),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// --- FINALIZED DOCUMENTS SCREEN ---
// ignore: unused_element
class _LegacyDocumentsPlaceholder extends StatelessWidget {
  final String userEmail;
  final String familyId;

  const _LegacyDocumentsPlaceholder({
    required this.userEmail,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF244032)),
        title: const Text(
          'Family Documents',
          style: TextStyle(
            color: Color(0xFF244032),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EEE7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4A8B71).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_shared_rounded, color: Color(0xFF355C4A), size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Secure Family Vault',
                            style: TextStyle(
                              color: Color(0xFF244032),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Store important deeds, insurance policies, IDs, and records safely.',
                            style: TextStyle(color: Color(0xFF65716B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Categories',
                style: TextStyle(
                  color: Color(0xFF244032),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _docCategoryCard(context, 'Legal & Deeds', Icons.gavel_rounded, Colors.indigo),
                    _docCategoryCard(context, 'Insurance', Icons.security_rounded, Colors.teal),
                    _docCategoryCard(context, 'Identities & Passports', Icons.badge_rounded, Colors.amber.shade800),
                    _docCategoryCard(context, 'Warranties & Manuals', Icons.book_rounded, Colors.brown),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF355C4A),
        foregroundColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document upload dialog coming soon!')),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _docCategoryCard(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF244032),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
