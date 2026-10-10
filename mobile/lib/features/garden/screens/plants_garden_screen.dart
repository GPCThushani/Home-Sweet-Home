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
  static const String baseUrl = 'http://localhost:8080/api/garden';
  int _currentNavIndex = 4;

  bool _isLoading = true;

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

  Map<String, List<Map<String, dynamic>>> _growingAtHome = {
    'Vegetables': [],
    'Fruits': [],
    'Flowers': [],
    'Herbs': [],
  };

  List<Map<String, dynamic>> _routines = [];
  List<Map<String, dynamic>> _quickCareActions = [];
  List<Map<String, dynamic>> _gardenNeeds = [];

  @override
  void initState() {
    super.initState();
    _loadGardenData();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (jwtToken != null && jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
    };
  }

  Future<void> _loadGardenData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final headers = await _headers();
      
      // 1. Fetch Plants
      final plantsRes = await http.get(Uri.parse('$baseUrl/plants/${widget.familyId}'), headers: headers);
      Map<String, List<Map<String, dynamic>>> loadedPlants = {
        'Vegetables': [],
        'Fruits': [],
        'Flowers': [],
        'Herbs': [],
      };
      if (plantsRes.statusCode == 200) {
        final List decoded = jsonDecode(plantsRes.body);
        for (var p in decoded) {
          final cat = p['category'] ?? 'Vegetables';
          if (loadedPlants.containsKey(cat)) {
            loadedPlants[cat]!.add({'id': p['id'], 'name': p['name']});
          }
        }
      }

      // 2. Fetch Garden Care Routines (quickAction = false)
      final routinesRes = await http.get(
        Uri.parse('$baseUrl/routines/${widget.familyId}?quickAction=false'),
        headers: headers,
      );
      List<Map<String, dynamic>> loadedRoutines = [];

      if (routinesRes.statusCode == 200) {
        final List decoded = jsonDecode(routinesRes.body);
        for (final r in decoded) {
          loadedRoutines.add({
            'id': r['id'],
            'title': r['title'],
            'frequency': r['frequencyType'] == 'EVERY_N_DAYS' ? 'Every ${r['intervalDays']} days' : r['frequencyType'],
            'done': r['completedForCurrentOccurrence'],
          });
        }
      }

      // 3. Fetch Quick Actions (quickAction = true)
      final actionsRes = await http.get(
        Uri.parse('$baseUrl/routines/${widget.familyId}?quickAction=true'),
        headers: headers,
      );
      List<Map<String, dynamic>> loadedActions = [];

      if (actionsRes.statusCode == 200) {
        final List decoded = jsonDecode(actionsRes.body);
        for (final a in decoded) {
          loadedActions.add({
            'id': a['id'],
            'action': a['title'],
            'done': a['completedForCurrentOccurrence'],
          });
        }
      }

      // 4. Fetch Garden Shopping Needs
      final shoppingRes = await http.get(
        Uri.parse('http://localhost:8080/api/shopping/${widget.familyId}'),
        headers: headers,
      );
      List<Map<String, dynamic>> loadedNeeds = [];

      if (shoppingRes.statusCode == 200) {
        final List decoded = jsonDecode(shoppingRes.body);
        for (var item in decoded) {
          if (item['varietyNotes'] == 'Garden requirement') {
            loadedNeeds.add({'id': item['id'], 'name': item['name']});
          }
        }
      }

      if (loadedNeeds.isEmpty) {
        final defaultNeeds = [
          'Potting soil bag (5kg)',
          'Organic compost fertilizer',
        ];

        for (final name in defaultNeeds) {
          try {
            final postRes = await http.post(
              Uri.parse('http://localhost:8080/api/shopping/${widget.familyId}'),
              headers: headers,
              body: jsonEncode({
                'name': name,
                'category': 'MONTHLY',
                'subCategory': 'Household & Cleaning Supplies',
                'quantity': '1',
                'varietyNotes': 'Garden requirement',
                'completed': false,
              }),
            );

            if (postRes.statusCode == 200 || postRes.statusCode == 201) {
              final saved = jsonDecode(postRes.body);
              loadedNeeds.add({
                'id': saved['id'],
                'name': saved['name'],
              });
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _growingAtHome = loadedPlants;
          _routines = loadedRoutines;
          _quickCareActions = loadedActions;
          _gardenNeeds = loadedNeeds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading garden data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : ListView(
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
                                  if (val == 'delete') _deleteRoutine(routine['id'], index);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                              onChanged: (val) => _toggleRoutineCompletion(routine, val ?? false),
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
                                    if (val == 'delete') _deleteQuickAction(action['id'], index);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                                onChanged: (val) => _toggleQuickActionCompletion(action, val ?? false),
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
                                          children: entry.value.map((plantMap) => Chip(
                                                label: Text(plantMap['name'], style: const TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w600)),
                                                backgroundColor: paleGreen,
                                                side: BorderSide.none,
                                                deleteIcon: const Icon(Icons.close, size: 14),
                                                onDeleted: () => _deletePlant(plantMap['id']),
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
                                final needMap = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.shopping_bag_outlined, size: 16, color: forest),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(needMap['name'], style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w500))),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                        onPressed: () => _deleteGardenNeed(needMap['id'], index),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        // Decorative Plant Image Banner above Bottom Nav
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

  // Safe API Handlers with Rollback and Scheduled Occurrence Endpoints
  Future<void> _toggleRoutineCompletion(Map<String, dynamic> routine, bool done) async {
    final oldValue = routine['done'] == true;
    setState(() => routine['done'] = done);

    try {
      final headers = await _headers();
      final endpoint = done ? 'complete' : 'completion';
      final response = await http.post(
        Uri.parse('$baseUrl/routines/${widget.familyId}/${routine['id']}/$endpoint'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update routine status');
      }
      await _loadGardenData();
    } catch (e) {
      setState(() => routine['done'] = oldValue);
      _showMessage('Could not update routine occurrence.');
    }
  }

  Future<void> _toggleQuickActionCompletion(Map<String, dynamic> action, bool done) async {
    final oldValue = action['done'] == true;
    setState(() => action['done'] = done);

    try {
      final headers = await _headers();
      final endpoint = done ? 'complete' : 'completion';
      final response = await http.post(
        Uri.parse('$baseUrl/routines/${widget.familyId}/${action['id']}/$endpoint'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update quick action status');
      }
      await _loadGardenData();
    } catch (e) {
      setState(() => action['done'] = oldValue);
      _showMessage('Could not update quick action status.');
    }
  }

  Future<void> _deleteRoutine(dynamic id, int index) async {
    setState(() => _routines.removeAt(index));
    try {
      final headers = await _headers();
      await http.delete(Uri.parse('$baseUrl/routines/${widget.familyId}/$id'), headers: headers);
    } catch (_) {}
  }

  Future<void> _deleteQuickAction(dynamic id, int index) async {
    setState(() => _quickCareActions.removeAt(index));
    try {
      final headers = await _headers();
      await http.delete(Uri.parse('$baseUrl/routines/${widget.familyId}/$id'), headers: headers);
    } catch (_) {}
  }

  Future<void> _deletePlant(dynamic id) async {
    try {
      final headers = await _headers();
      await http.delete(Uri.parse('$baseUrl/plants/${widget.familyId}/$id'), headers: headers);
      _loadGardenData();
    } catch (_) {}
  }

  Future<void> _deleteGardenNeed(dynamic id, int index) async {
    setState(() => _gardenNeeds.removeAt(index));
    if (id != null) {
      try {
        final headers = await _headers();
        await http.delete(Uri.parse('http://localhost:8080/api/shopping/${widget.familyId}/item/$id'), headers: headers);
      } catch (_) {}
    }
  }

  void _showAddRoutineModal() {
    final titleController = TextEditingController();
    String freqType = 'EVERY_N_DAYS';
    final intervalController = TextEditingController(text: '2');

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
                  const Text('Add Garden Routine', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  TextField(controller: titleController, decoration: _inputDecoration('Routine Title', hint: 'e.g. Add compost')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: freqType,
                    decoration: _inputDecoration('Frequency Type'),
                    items: const [
                      DropdownMenuItem(value: 'EVERY_N_DAYS', child: Text('Every N Days')),
                      DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                      DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                    ],
                    onChanged: (val) => setModalState(() => freqType = val!),
                  ),
                  if (freqType == 'EVERY_N_DAYS') ...[
                    const SizedBox(height: 12),
                    TextField(controller: intervalController, keyboardType: TextInputType.number, decoration: _inputDecoration('Interval Days')),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isNotEmpty) {
                          try {
                            final headers = await _headers();
                            final res = await http.post(
                              Uri.parse('$baseUrl/routines/${widget.familyId}'),
                              headers: headers,
                              body: jsonEncode({
                                'title': title,
                                'frequencyType': freqType,
                                'intervalDays': freqType == 'EVERY_N_DAYS' ? int.tryParse(intervalController.text) ?? 2 : null,
                                'dayOfWeek': 'SUNDAY',
                                'dayOfMonth': 1,
                                'isQuickAction': false,
                              }),
                            );
                            if (res.statusCode == 200 || res.statusCode == 201) {
                              if (context.mounted) Navigator.pop(context);
                              _loadGardenData();
                            }
                          } catch (_) {}
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
      },
    );
  }

  void _showEditRoutineModal(int index) {
    final routine = _routines[index];
    final titleController = TextEditingController(text: routine['title']);

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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final headers = await _headers();
                      await http.put(
                        Uri.parse('$baseUrl/routines/${widget.familyId}/${routine['id']}'),
                        headers: headers,
                        body: jsonEncode({
                          'title': titleController.text.trim(),
                          'frequencyType': 'EVERY_N_DAYS',
                          'intervalDays': 2,
                          'isQuickAction': false,
                        }),
                      );
                      if (context.mounted) Navigator.pop(context);
                      _loadGardenData();
                    } catch (_) {}
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
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                try {
                  final headers = await _headers();
                  final res = await http.post(
                    Uri.parse('$baseUrl/routines/${widget.familyId}'),
                    headers: headers,
                    body: jsonEncode({
                      'title': text,
                      'frequencyType': 'AS_NEEDED',
                      'isQuickAction': true,
                    }),
                  );

                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (context.mounted) Navigator.pop(context);
                    await _loadGardenData();
                    _showMessage('Maintenance action added successfully.');
                  } else {
                    _showMessage('Failed to save maintenance action.');
                  }
                } catch (_) {
                  _showMessage('Could not save maintenance action.');
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
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                try {
                  final headers = await _headers();
                  final res = await http.put(
                    Uri.parse('$baseUrl/routines/${widget.familyId}/${action['id']}'),
                    headers: headers,
                    body: jsonEncode({
                      'title': text,
                      'frequencyType': 'AS_NEEDED',
                      'isQuickAction': true,
                    }),
                  );

                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (context.mounted) Navigator.pop(context);
                    await _loadGardenData();
                    _showMessage('Maintenance action updated.');
                  } else {
                    _showMessage('Failed to update maintenance action.');
                  }
                } catch (_) {
                  _showMessage('Could not update maintenance action.');
                }
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
                      onPressed: () async {
                        final name = controller.text.trim();
                        if (name.isNotEmpty) {
                          try {
                            final headers = await _headers();
                            final res = await http.post(
                              Uri.parse('$baseUrl/plants/${widget.familyId}'),
                              headers: headers,
                              body: jsonEncode({
                                'name': name,
                                'category': selectedCategory,
                              }),
                            );
                            if (res.statusCode == 200 || res.statusCode == 201) {
                              if (context.mounted) Navigator.pop(context);
                              _loadGardenData();
                            }
                          } catch (_) {}
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
                if (text.isEmpty) return;

                try {
                  final headers = await _headers();
                  final res = await http.post(
                    Uri.parse('http://localhost:8080/api/shopping/${widget.familyId}'),
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

                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (context.mounted) Navigator.pop(context);
                    await _loadGardenData();
                    _showMessage('Added to garden needs & synced to Shopping list.');
                  } else {
                    _showMessage('Could not save garden shopping need.');
                  }
                } catch (_) {
                  _showMessage('Could not connect to Shopping service.');
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