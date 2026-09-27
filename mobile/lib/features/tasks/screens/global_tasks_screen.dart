import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GlobalTasksScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;
  const GlobalTasksScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

  @override
  State<GlobalTasksScreen> createState() => _GlobalTasksScreenState();
}

class _GlobalTasksScreenState extends State<GlobalTasksScreen> {
  static const String _baseUrl = 'http://localhost:8080';
  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _familyMembers = [];
  int _currentNavIndex = 3; // Tasks tab index

  static const Color ivory = Color(0xFFFAF8F3);
  static const Color white = Colors.white;
  static const Color forest = Color(0xFF355C4A);
  static const Color green = Color(0xFF4A8B71);
  static const Color paleGreen = Color(0xFFE5EEE7);
  static const Color textDark = Color(0xFF244032);
  static const Color textSecondary = Color(0xFF65716B);
  static const Color border = Color(0xFFE5E1D9);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchFamilyTasks(),
      _fetchFamilyMembers(),
    ]);
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (jwtToken != null && jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
    };
  }

  Future<void> _fetchFamilyTasks() async {
    try {
      final headers = await _headers();
      final url = Uri.parse('$_baseUrl/api/tasks/family/${widget.familyId}');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && mounted) {
          setState(() {
            _tasks = decoded.map<Map<String, dynamic>>((t) => Map<String, dynamic>.from(t)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching family tasks: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFamilyMembers() async {
    try {
      final headers = await _headers();
      final url = Uri.parse('$_baseUrl/api/families/${widget.familyId}/members');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && mounted) {
          setState(() {
            _familyMembers = decoded.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("ERROR fetching family members: $e");
    }
  }

  Future<void> _completeTask(String taskId) async {
    try {
      final headers = await _headers();
      final url = Uri.parse('$_baseUrl/api/tasks/$taskId/complete');
      final response = await http.put(url, headers: headers);
      if (response.statusCode == 200) {
        await _fetchFamilyTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task moved to completed!'), backgroundColor: green),
          );
        }
      }
    } catch (e) {
      debugPrint("Error completing task: $e");
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final headers = await _headers();
      final url = Uri.parse('$_baseUrl/api/tasks/$taskId');
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchFamilyTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task deleted successfully"), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting task: $e");
    }
  }

  String _getFriendlyName(dynamic memberData) {
    if (memberData == null) {
      return widget.userEmail.toLowerCase().contains('perera') ? 'Father' : 'Daughter';
    }
    final userMap = memberData is Map && memberData.containsKey('user') ? memberData['user'] : null;
    if (userMap is Map) {
      final email = (userMap['email'] ?? '').toString().toLowerCase();
      if (email == 'perera@gmail.com') {
        return 'Father';
      }
    }

    if (memberData is Map) {
      final email = (memberData['email'] ?? '').toString().toLowerCase();
      final nickname = (memberData['nickname'] ?? memberData['name'] ?? '').toString().toLowerCase();
      final role = (memberData['role'] ?? '').toString().toUpperCase();

      if (email == 'perera@gmail.com' || nickname == 'admin' || role == 'PARENT') {
        return 'Father';
      }
    }

    return 'Daughter';
  }

  Color _getModuleColor(String module) {
    switch (module.toUpperCase()) {
      case 'HEALTH':
        return Colors.red.shade700;
      case 'FINANCE':
        return Colors.purple.shade700;
      case 'SHOPPING':
        return Colors.orange.shade700;
      case 'PETS':
        return Colors.teal.shade700;
      case 'OTHER':
        return Colors.blueGrey.shade600;
      case 'CHORES':
      default:
        return green;
    }
  }

  IconData _getModuleIcon(String module) {
    switch (module.toUpperCase()) {
      case 'HEALTH':
        return Icons.medical_services_outlined;
      case 'FINANCE':
        return Icons.attach_money_rounded;
      case 'SHOPPING':
        return Icons.shopping_bag_outlined;
      case 'PETS':
        return Icons.pets_rounded;
      case 'OTHER':
        return Icons.category_rounded;
      case 'CHORES':
      default:
        return Icons.task_alt_rounded;
    }
  }

  List<Map<String, dynamic>> _filterTasks(int tabIndex) {
    if (tabIndex == 1) {
      return _tasks.where((t) {
        if ((t['status'] ?? '').toString().toUpperCase() == 'COMPLETED') return false;
        final assignee = t['assignedTo'];
        if (assignee is Map) {
          return assignee['user']?['email'] == widget.userEmail || assignee['email'] == widget.userEmail;
        }
        return false;
      }).toList();
    } else if (tabIndex == 2) {
      return _tasks.where((t) => (t['status'] ?? '').toString().toUpperCase() == 'COMPLETED').toList();
    }
    return _tasks.where((t) => (t['status'] ?? '').toString().toUpperCase() != 'COMPLETED').toList();
  }

  void _openCreateTaskBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskBottomSheet(
        familyId: widget.familyId,
        familyMembers: _familyMembers,
        onTaskCreated: _loadData,
        getFriendlyName: _getFriendlyName,
      ),
    );
  }

  void _openEditTaskBottomSheet(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTaskBottomSheet(
        familyId: widget.familyId,
        familyMembers: _familyMembers,
        task: task,
        onTaskUpdated: _loadData,
        getFriendlyName: _getFriendlyName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: paleGreen.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: green.withValues(alpha: 0.2), width: 1.5)),
                  boxShadow: [
                    BoxShadow(
                      color: green.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Household Tasks',
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('Manage and assign family responsibilities.', style: TextStyle(color: textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: TabBar(
                    isScrollable: false, // Ensures tabs evenly stretch across container width
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: forest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: white,
                    unselectedLabelColor: textSecondary,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    tabs: const [
                      Tab(text: 'All Tasks'),
                      Tab(text: 'My Tasks'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : TabBarView(
                        children: List.generate(3, (tabIndex) {
                          final tasks = _filterTasks(tabIndex);
                          if (tasks.isEmpty) {
                            return Center(
                              child: Text(
                                tabIndex == 2 ? 'No completed tasks yet.' : 'No tasks found in this view.',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              final String title = task['title'] ?? 'Untitled';
                              final String description = task['description'] ?? '';
                              final String module = task['originModule'] ?? 'CHORES';
                              final String taskId = task['id'].toString();
                              final String status = task['status'] ?? 'PENDING';
                              final bool isCompleted = status.toUpperCase() == 'COMPLETED';
                              final iconColor = _getModuleColor(module);
                              
                              final assigneeObj = task['assignedTo'];
                              String assigneeName = _getFriendlyName(assigneeObj);

                              String dueDateStr = '';
                              if (task['dueDate'] != null) {
                                try {
                                  final dueDt = DateTime.parse(task['dueDate'].toString()).toLocal();
                                  final day = dueDt.day.toString().padLeft(2, '0');
                                  final month = dueDt.month.toString().padLeft(2, '0');
                                  final year = dueDt.year;
                                  final hour = dueDt.hour.toString().padLeft(2, '0');
                                  final minute = dueDt.minute.toString().padLeft(2, '0');
                                  dueDateStr = 'Due: $day/$month/$year at $hour:$minute';
                                } catch (_) {}
                              }

                              String completedText = 'Completed';
                              if (isCompleted) {
                                String timeStr = '';
                                if (task['completedAt'] != null) {
                                  try {
                                    final localDt = DateTime.parse(task['completedAt'].toString()).toLocal();
                                    final hour = localDt.hour.toString().padLeft(2, '0');
                                    final minute = localDt.minute.toString().padLeft(2, '0');
                                    timeStr = ' ($hour:$minute)';
                                  } catch (_) {}
                                }

                                final completerObj = task['completedBy'];
                                final completerName = _getFriendlyName(completerObj);

                                completedText = 'Assigned: $assigneeName | Done: $completerName$timeStr';
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: border, width: 1.5),
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
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: iconColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(_getModuleIcon(module), color: iconColor, size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: textDark,
                                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _openEditTaskBottomSheet(task),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _deleteTask(taskId),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          module,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                        ),
                                        if (dueDateStr.isNotEmpty)
                                          Text(
                                            dueDateStr,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                          ),
                                      ],
                                    ),
                                    if (description.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        description,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: paleGreen,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isCompleted ? completedText : assigneeName,
                                              style: const TextStyle(fontSize: 11, color: green, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!isCompleted)
                                          InkWell(
                                            onTap: () => _completeTask(taskId),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: green.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: green),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle_outline_rounded, size: 14, color: green),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Mark Done',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Completed',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: forest,
        foregroundColor: white,
        onPressed: _openCreateTaskBottomSheet,
        child: const Icon(Icons.add),
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
            if (index == 0 || index == 1 || index == 2 || index == 4) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}

class CreateTaskBottomSheet extends StatefulWidget {
  final String familyId;
  final List<Map<String, dynamic>> familyMembers;
  final VoidCallback onTaskCreated;
  final String Function(dynamic) getFriendlyName;
  const CreateTaskBottomSheet({
    super.key,
    required this.familyId,
    required this.familyMembers,
    required this.onTaskCreated,
    required this.getFriendlyName,
  });
  @override
  State<CreateTaskBottomSheet> createState() => _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends State<CreateTaskBottomSheet> {
  static const String _baseUrl = 'http://localhost:8080';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedModule = 'SHOPPING';
  String? _selectedAssigneeId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  final List<String> _modules = ['SHOPPING', 'CHORES', 'HEALTH', 'PETS', 'FINANCE', 'OTHER'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String? _buildDueDate() {
    if (_selectedDate == null) return null;
    final date = _selectedDate!;
    final time = _selectedTime ?? const TimeOfDay(hour: 23, minute: 59);
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return combined.toUtc().toIso8601String();
  }

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a task title."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final headers = await _headers();
      final url = Uri.parse('$_baseUrl/api/tasks');
      final body = {
        'familyId': widget.familyId,
        'title': title,
        'description': description,
        'originModule': _selectedModule,
        'assignedToMemberId': _selectedAssigneeId,
        'dueDate': _buildDueDate(),
      };

      final response = await http.post(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          widget.onTaskCreated();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task created successfully!"), backgroundColor: Color(0xFF4A8B71)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to create task (${response.statusCode})."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint("Error creating task: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TaskFormContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF244032))),
          const SizedBox(height: 18),
          _buildTextField(controller: _titleController, hint: 'Task Title (e.g., Buy eggs)'),
          const SizedBox(height: 12),
          _buildTextField(controller: _descriptionController, hint: 'Description or Quantity (e.g., 2 cartons)', maxLines: 3),
          const SizedBox(height: 16),
          const Text('Category Module', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF244032))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedModule,
            items: _modules.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() => _selectedModule = val!),
            decoration: _dropdownDecoration(),
          ),
          const SizedBox(height: 16),
          const Text('Assign To Member', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF244032))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedAssigneeId,
            hint: Text(widget.familyMembers.isEmpty ? 'No family members available' : 'Select family member'),
            items: widget.familyMembers
                .where((member) => member['id'] != null)
                .map<DropdownMenuItem<String>>((member) {
              final id = member['id'].toString();
              final displayName = widget.getFriendlyName(member);
              return DropdownMenuItem<String>(value: id, child: Text(displayName));
            }).toList(),
            onChanged: widget.familyMembers.isEmpty ? null : (val) => setState(() => _selectedAssigneeId = val),
            decoration: _dropdownDecoration(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDateField()),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeField()),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submitTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A8B71),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Save Task', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF8FAF9),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4A8B71), width: 1.5)),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }

  Widget _buildDateField() {
    final text = _selectedDate == null ? 'Select date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    return InkWell(
      onTap: _pickDueDate,
      child: InputDecorator(decoration: _dropdownDecoration().copyWith(labelText: 'Due Date'), child: Text(text)),
    );
  }

  Widget _buildTimeField() {
    final text = _selectedTime == null ? 'Select time' : _selectedTime!.format(context);
    return InkWell(
      onTap: _pickTime,
      child: InputDecorator(decoration: _dropdownDecoration().copyWith(labelText: 'Time (Optional)'), child: Text(text)),
    );
  }
}

class EditTaskBottomSheet extends StatefulWidget {
  final String familyId;
  final List<Map<String, dynamic>> familyMembers;
  final Map<String, dynamic> task;
  final VoidCallback onTaskUpdated;
  final String Function(dynamic) getFriendlyName;
  const EditTaskBottomSheet({
    super.key,
    required this.familyId,
    required this.familyMembers,
    required this.task,
    required this.onTaskUpdated,
    required this.getFriendlyName,
  });
  @override
  State<EditTaskBottomSheet> createState() => _EditTaskBottomSheetState();
}

class _EditTaskBottomSheetState extends State<EditTaskBottomSheet> {
  static const String _baseUrl = 'http://localhost:8080';
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedModule;
  String? _selectedAssigneeId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  final List<String> _modules = ['SHOPPING', 'CHORES', 'HEALTH', 'PETS', 'FINANCE', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.task['description'] ?? '');
    _selectedModule = widget.task['originModule'] ?? 'OTHER';
    final assignedTo = widget.task['assignedTo'];
    if (assignedTo is Map) {
      _selectedAssigneeId = assignedTo['id']?.toString();
    }

    if (widget.task['dueDate'] != null) {
      try {
        final dt = DateTime.parse(widget.task['dueDate'].toString()).toLocal();
        _selectedDate = DateTime(dt.year, dt.month, dt.day);
        _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String? _buildDueDate() {
    if (_selectedDate == null) return null;
    final date = _selectedDate!;
    final time = _selectedTime ?? const TimeOfDay(hour: 23, minute: 59);
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return combined.toUtc().toIso8601String();
  }

  Future<void> _updateTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a task title."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final headers = await _headers();
      final taskId = widget.task['id'].toString();
      final url = Uri.parse('$_baseUrl/api/tasks/$taskId');
      final body = {
        'title': title,
        'description': description,
        'originModule': _selectedModule,
        'assignedToMemberId': _selectedAssigneeId,
        'dueDate': _buildDueDate(),
      };

      final response = await http.put(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          widget.onTaskUpdated();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task updated successfully!"), backgroundColor: Color(0xFF4A8B71)),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating task: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TaskFormContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF244032))),
          const SizedBox(height: 18),
          _buildTextField(controller: _titleController, hint: 'Task Title'),
          const SizedBox(height: 12),
          _buildTextField(controller: _descriptionController, hint: 'Description or Quantity', maxLines: 3),
          const SizedBox(height: 16),
          const Text('Category Module', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF244032))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _modules.contains(_selectedModule) ? _selectedModule : 'OTHER',
            items: _modules.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() => _selectedModule = val!),
            decoration: _dropdownDecoration(),
          ),
          const SizedBox(height: 16),
          const Text('Assign To Member', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF244032))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: widget.familyMembers.any((m) => m['id']?.toString() == _selectedAssigneeId) ? _selectedAssigneeId : null,
            hint: Text(widget.familyMembers.isEmpty ? 'No family members' : 'Select family member'),
            items: widget.familyMembers
                .where((member) => member['id'] != null)
                .map<DropdownMenuItem<String>>((member) {
              final id = member['id'].toString();
              final displayName = widget.getFriendlyName(member);
              return DropdownMenuItem<String>(value: id, child: Text(displayName));
            }).toList(),
            onChanged: widget.familyMembers.isEmpty ? null : (val) => setState(() => _selectedAssigneeId = val),
            decoration: _dropdownDecoration(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDateField()),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeField()),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _updateTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A8B71),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Update Task', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF8FAF9),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4A8B71), width: 1.5)),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }

  Widget _buildDateField() {
    final text = _selectedDate == null ? 'Select date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    return InkWell(
      onTap: _pickDueDate,
      child: InputDecorator(decoration: _dropdownDecoration().copyWith(labelText: 'Due Date'), child: Text(text)),
    );
  }

  Widget _buildTimeField() {
    final text = _selectedTime == null ? 'Select time' : _selectedTime!.format(context);
    return InkWell(
      onTap: _pickTime,
      child: InputDecorator(decoration: _dropdownDecoration().copyWith(labelText: 'Time (Optional)'), child: Text(text)),
    );
  }
}

class TaskFormContainer extends StatelessWidget {
  final Widget child;
  const TaskFormContainer({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}