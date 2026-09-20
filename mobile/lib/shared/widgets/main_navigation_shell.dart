import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/tasks/screens/global_tasks_screen.dart'; 

class MainNavigationShell extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const MainNavigationShell({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(userEmail: widget.userEmail),
          // Placeholder for Family Screen until fully implemented
          const Center(child: Text("Family Screen (Coming Soon)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF244032)))),
          // Placeholder for Calendar Screen until fully implemented
          const Center(child: Text("Calendar Screen (Coming Soon)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF244032)))),
          GlobalTasksScreen(userEmail: widget.userEmail, familyId: widget.familyId),
          // Placeholder for More Screen until fully implemented
          const Center(child: Text("More Screen (Coming Soon)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF244032)))),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.5)),
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
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4A8B71),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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