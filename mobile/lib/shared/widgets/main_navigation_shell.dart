import 'package:flutter/material.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/family/screens/family_screen.dart';
import '../../features/tasks/screens/global_tasks_screen.dart';
import '../../features/more/screens/more_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final String userEmail;
  final String familyId;
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    required this.userEmail,
    required this.familyId,
    this.initialIndex = 0,
  });

  static void navigate(
    BuildContext context, {
    required String userEmail,
    required String familyId,
    required int index,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigationShell(
          userEmail: userEmail,
          familyId: familyId,
          initialIndex: index,
        ),
      ),
      (_) => false,
    );
  }

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(userEmail: widget.userEmail, familyId: widget.familyId),

          FamilyScreen(userEmail: widget.userEmail, familyId: widget.familyId),

          const Center(
            child: Text(
              'Calendar Screen (Coming Soon)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF244032),
              ),
            ),
          ),

          GlobalTasksScreen(
            embedded: true,
            userEmail: widget.userEmail,
            familyId: widget.familyId,
          ),

          MoreScreen(userEmail: widget.userEmail, familyId: widget.familyId),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4A8B71),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Family',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_outlined),
              activeIcon: Icon(Icons.task_alt_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              activeIcon: Icon(Icons.menu_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
