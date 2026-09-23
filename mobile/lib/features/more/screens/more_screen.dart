import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoreScreen extends StatelessWidget {
  final String userEmail;
  final String familyId;

  const MoreScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

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
                onTap: () => _navigateTo(context, 'Health'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.shopping_bag_outlined,
                iconColor: Colors.orange.shade700,
                title: 'Shopping',
                onTap: () => _navigateTo(context, 'Shopping'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.grass_rounded,
                iconColor: Colors.green.shade700,
                title: 'Plants / Garden',
                onTap: () => _navigateTo(context, 'Plants / Garden'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.home_repair_service_outlined,
                iconColor: Colors.brown.shade400,
                title: 'Home Maintenance',
                onTap: () => _navigateTo(context, 'Home Maintenance'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.group_rounded,
                iconColor: Colors.purple.shade600,
                title: 'Together',
                onTap: () => _navigateTo(context, 'Together'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.folder_open_rounded,
                iconColor: Colors.blue.shade600,
                title: 'Documents',
                onTap: () => _navigateTo(context, 'Documents'),
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