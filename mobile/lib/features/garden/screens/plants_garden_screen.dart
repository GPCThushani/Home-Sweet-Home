import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/screens/global_tasks_screen.dart';

class PlantsGardenScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const PlantsGardenScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

  @override
  State<PlantsGardenScreen> createState() => _PlantsGardenScreenState();
}

class _PlantsGardenScreenState extends State<PlantsGardenScreen> {
  static const String baseUrl = 'http://localhost:8080/api';
  int _currentNavIndex = 4;

  static const Color ivory = Color(0xFFFAF8F3);
  static const Color white = Colors.white;
  static const Color forest = Color(0xFF355C4A);
  static const Color green = Color(0xFF4A8B71);
  static const Color paleGreen = Color(0xFFE5EEE7);
  static const Color textDark = Color(0xFF244032);
  static const Color textSecondary = Color(0xFF65716B);
  static const Color muted = Color(0xFF98A19C);
  static const Color border = Color(0xFFE5E1D9);
  static const Color peach = Color(0xFFF4DDD2);

  final Map<String, List<String>> _growingAtHome = {
    'Vegetables': [],
    'Fruits': [],
    'Flowers': [],
    'Herbs': [],
  };

  final List<Map<String, dynamic>> _routines = [
    {'title': 'Water the garden', 'frequency': 'Every 2 days • 7:00 AM', 'done': false},
    {'title': 'Weekly Garden Care (Weed, prune, clean)', 'frequency': 'Every Sunday • 8:00 AM', 'done': false},
    {'title': 'Fertilize plants with compost', 'frequency': 'Monthly', 'done': true},
  ];

  final List<Map<String, dynamic>> _quickCareActions = [
    {'action': 'Weed garden beds', 'done': false},
    {'action': 'Prune dead leaves & branches', 'done': false},
    {'action': 'Clean pots and plant racks', 'done': false},
    {'action': 'Check for pests / spray neem oil', 'done': false},
    {'action': 'Rearrange or move pots for sunlight', 'done': false},
  ];

  final List<String> _gardenNeeds = [
    'Potting soil bag (5kg)',
    'Organic compost fertilizer',
    'Medium terracotta plant pots (x3)',
  ];

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (jwtToken != null && jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: Column(
          children: [
            // Standard Page Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: paleGreen.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: green.withValues(alpha: 0.2), width: 1.5)),
                boxShadow: [
                  BoxShadow(color: green.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plants / Garden',
                          style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Help the family maintain the garden without remembering everything.',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Garden Conditions Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: peach.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wb_sunny_rounded, color: Color(0xFFD97736), size: 28),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Garden Conditions', style: TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Warm & sunny this week. Regular watering recommended.', style: TextStyle(color: textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section: Garden Care Routines
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Garden Care Routines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark)),
                      TextButton.icon(
                        onPressed: _showAddRoutineModal,
                        icon: const Icon(Icons.add, size: 16, color: green),
                        label: const Text('Add Routine', style: TextStyle(color: green, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._routines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final routine = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: CheckboxListTile(
                        title: Text(routine['title'], style: TextStyle(fontWeight: FontWeight.w700, color: textDark, decoration: routine['done'] ? TextDecoration.lineThrough : null)),
                        subtitle: Text(routine['frequency'], style: const TextStyle(fontSize: 11, color: textSecondary)),
                        value: routine['done'],
                        activeColor: green,
                        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        secondary: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: textSecondary, size: 18),
                          onSelected: (val) {
                            if (val == 'edit') _showEditRoutineModal(index);
                            if (val == 'delete') setState(() => _routines.removeAt(index));
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                        onChanged: (val) => setState(() => routine['done'] = val ?? false),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  // Section: While You're Here (Quick Care Actions)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("While You're Here...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark)),
                      TextButton.icon(
                        onPressed: _showAddQuickActionModal,
                        icon: const Icon(Icons.add, size: 16, color: green),
                        label: const Text('Add Action', style: TextStyle(color: green, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: _quickCareActions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final action = entry.value;
                        return CheckboxListTile(
                          dense: true,
                          title: Text(action['action'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark, decoration: action['done'] ? TextDecoration.lineThrough : null)),
                          value: action['done'],
                          activeColor: green,
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          secondary: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: textSecondary, size: 18),
                            onSelected: (val) {
                              if (val == 'edit') _showEditQuickActionModal(index);
                              if (val == 'delete') setState(() => _quickCareActions.removeAt(index));
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                          onChanged: (val) => setState(() => action['done'] = val ?? false),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 18),
                  // Section: Growing at Home (Simple Inventory Sections)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Growing at Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark)),
                      TextButton.icon(
                        onPressed: _showAddPlantModal,
                        icon: const Icon(Icons.add, size: 16, color: green),
                        label: const Text('Add Plant', style: TextStyle(color: green, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._growingAtHome.entries.map((entry) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w800, color: forest, fontSize: 13)),
                            const SizedBox(height: 8),
                            entry.value.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Text('No plants added here yet.', style: TextStyle(color: muted, fontSize: 12)),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: entry.value.map((plant) => Chip(
                                          label: Text(plant, style: const TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w600)),
                                          backgroundColor: paleGreen,
                                          side: BorderSide.none,
                                          deleteIcon: const Icon(Icons.close, size: 14),
                                          onDeleted: () {
                                            setState(() {
                                              _growingAtHome[entry.key]?.remove(plant);
                                            });
                                          },
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        )).toList(),
                                  ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 12),
                  // Section: Garden Needs (Connected to Shopping)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: paleGreen.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Garden Shopping Needs', style: TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 15)),
                            TextButton(
                              onPressed: _showAddGardenNeedModal,
                              child: const Text('+ Add Need', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ..._gardenNeeds.asMap().entries.map((entry) {
                          final index = entry.key;
                          final need = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_bag_outlined, size: 16, color: forest),
                                const SizedBox(width: 10),
                                Expanded(child: Text(need, style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w500))),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                  onPressed: () => setState(() => _gardenNeeds.removeAt(index)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Decorative Plant Image Banner Placeholder above Bottom Nav
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/garden/garden_banner.jpeg',
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: paleGreen.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border),
                        ),
                        child: const Center(
                          child: Icon(Icons.local_florist_rounded, color: forest, size: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
            BottomNavigationBarItem(icon: Icon(Icons.menu_outlined), activeIcon: Icon(Icons.menu_rounded), label: 'More'),
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
            } else if (index != 4) {
              Navigator.maybePop(context);
            }
          },
        ),
      ),
    );
  }

  void _showAddRoutineModal() {
    final titleController = TextEditingController();
    final freqController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Garden Routine', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              TextField(controller: titleController, decoration: _inputDecoration('Routine Title', hint: 'e.g. Add compost')),
              const SizedBox(height: 12),
              TextField(controller: freqController, decoration: _inputDecoration('Frequency', hint: 'e.g. Every Saturday • 9:00 AM')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      setState(() {
                        _routines.add({
                          'title': titleController.text.trim(),
                          'frequency': freqController.text.trim().isNotEmpty ? freqController.text.trim() : 'As needed',
                          'done': false,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Add Routine', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditRoutineModal(int index) {
    final routine = _routines[index];
    final titleController = TextEditingController(text: routine['title']);
    final freqController = TextEditingController(text: routine['frequency']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Garden Routine', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              TextField(controller: titleController, decoration: _inputDecoration('Routine Title')),
              const SizedBox(height: 12),
              TextField(controller: freqController, decoration: _inputDecoration('Frequency')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      routine['title'] = titleController.text.trim();
                      routine['frequency'] = freqController.text.trim();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddQuickActionModal() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Maintenance Action'),
          content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. Trim overgrown hedges')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() => _quickCareActions.add({'action': controller.text.trim(), 'done': false}));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditQuickActionModal(int index) {
    final action = _quickCareActions[index];
    final controller = TextEditingController(text: action['action']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Maintenance Action'),
          content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Action name')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() => action['action'] = controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPlantModal() {
    final controller = TextEditingController();
    String selectedCategory = 'Vegetables';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Plant to Garden', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: _inputDecoration('Category'),
                    items: ['Vegetables', 'Fruits', 'Flowers', 'Herbs'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setModalState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: controller, decoration: _inputDecoration('Plant Name', hint: 'e.g. Okra (Bandakka), Orchids')),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = controller.text.trim();
                        if (name.isNotEmpty) {
                          setState(() {
                            _growingAtHome[selectedCategory]?.add(name);
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Add Plant', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddGardenNeedModal() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Garden Shopping Need'),
          content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. Neem oil spray')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() => _gardenNeeds.add(text));

                  try {
                    final headers = await _headers();
                    await http.post(
                      Uri.parse('$baseUrl/shopping/${widget.familyId}'),
                      headers: headers,
                      body: jsonEncode({
                        'name': text,
                        'category': 'MONTHLY',
                        'subCategory': 'Household & Cleaning Supplies',
                        'quantity': '1',
                        'varietyNotes': 'Garden requirement',
                        'completed': false,
                      }),
                    );
                  } catch (_) {}

                  if (context.mounted) Navigator.pop(context);
                  _showMessage('Added to garden needs & synced to Shopping list.');
                }
              },
              child: const Text('Add & Sync'),
            ),
          ],
        );
      },
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}