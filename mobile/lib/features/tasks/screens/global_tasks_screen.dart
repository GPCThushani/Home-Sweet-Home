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
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  List<dynamic> _familyMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchFamilyTasks();
    _fetchFamilyMembers();
  }

  Future<void> _fetchFamilyTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      final url = Uri.parse('http://10.0.2.2:8080/api/tasks/family/${widget.familyId}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _tasks = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching family tasks: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFamilyMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      final url = Uri.parse('http://10.0.2.2:8080/api/families/user?email=${widget.userEmail}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> families = jsonDecode(response.body);
        if (families.isNotEmpty) {
          final familyId = families[0]['id'];
          final membersUrl = Uri.parse('http://10.0.2.2:8080/api/families/$familyId/members');
          final memberResponse = await http.get(
            membersUrl,
            headers: {
              'Content-Type': 'application/json',
              if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
            },
          );
          if (memberResponse.statusCode == 200) {
            setState(() {
              _familyMembers = jsonDecode(memberResponse.body);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching members: $e");
    }
  }

  Future<void> _completeTask(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      final url = Uri.parse('http://10.0.2.2:8080/api/tasks/$taskId/complete');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        _fetchFamilyTasks();
      }
    } catch (e) {
      debugPrint("Error completing task: $e");
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      final url = Uri.parse('http://10.0.2.2:8080/api/tasks/$taskId');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchFamilyTasks();
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

  Color _getModuleColor(String module) {
    switch ((module).toUpperCase()) {
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
      default:
        return const Color(0xFF4A8B71);
    }
  }

  IconData _getModuleIcon(String module) {
    switch ((module).toUpperCase()) {
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
      default:
        return Icons.task_alt_rounded;
    }
  }

  List<dynamic> _filterTasks(int tabIndex) {
    if (tabIndex == 1) {
      return _tasks.where((t) {
        final assignee = t['assignedTo'];
        if (assignee is Map) {
          return assignee['user']?['email'] == widget.userEmail || assignee['email'] == widget.userEmail;
        }
        return false;
      }).toList();
    } else if (tabIndex == 2) {
      return _tasks.where((t) => t['status'] == 'COMPLETED').toList();
    }
    return _tasks.where((t) => t['status'] != 'COMPLETED').toList();
  }

  void _openCreateTaskBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskBottomSheetUi(
        familyId: widget.familyId,
        familyMembers: _familyMembers,
        onTaskCreated: _fetchFamilyTasks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          Container(
            color: const Color(0xFFF8FAF9),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Household Tasks',
                          style: TextStyle(
                            color: Color(0xFF244032),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const TabBar(
                          isScrollable: true,
                          labelColor: Color(0xFF4A8B71),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Color(0xFF4A8B71),
                          indicatorWeight: 3,
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          tabs: [
                            Tab(text: 'All'),
                            Tab(text: 'My Tasks'),
                            Tab(text: 'Completed'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A8B71)))
                        : TabBarView(
                            children: List.generate(3, (tabIndex) {
                              final tasks = _filterTasks(tabIndex);
                              if (tasks.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No tasks found in this view.',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  final String title = task['title'] ?? 'Untitled';
                                  final String module = task['originModule'] ?? 'CHORES';
                                  final String taskId = task['id'];
                                  final String status = task['status'] ?? 'PENDING';
                                  final bool isCompleted = status == 'COMPLETED';
                                  final iconColor = _getModuleColor(module);

                                  String assigneeName = 'Unassigned';
                                  final assigneeObj = task['assignedTo'];
                                  if (assigneeObj is Map) {
                                    assigneeName = assigneeObj['name'] ?? assigneeObj['nickname'] ?? 'Family Member';
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
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
                                                  color: const Color(0xFF244032),
                                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Editing: $title")),
                                                );
                                              },
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
                                        Text(
                                          module,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F2ED),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isCompleted && task['completedAt'] != null
                                                    ? 'Done (${task['completedAt'].toString().substring(11, 16)})'
                                                    : assigneeName,
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF4A8B71), fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _completeTask(taskId),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isCompleted ? Colors.grey.shade200 : const Color(0xFF4A8B71).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isCompleted ? Colors.grey.shade400 : const Color(0xFF4A8B71),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                                                      size: 14,
                                                      color: isCompleted ? Colors.grey.shade700 : const Color(0xFF4A8B71),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      isCompleted ? 'Completed' : 'Mark Done',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: isCompleted ? Colors.grey.shade700 : const Color(0xFF4A8B71),
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF4A8B71),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: _openCreateTaskBottomSheet,
            ),
          ),
        ],
      ),
    );
  }
}

// --- CREATE TASK BOTTOM SHEET ---
class CreateTaskBottomSheetUi extends StatefulWidget {
  final String familyId;
  final List<dynamic> familyMembers;
  final VoidCallback onTaskCreated;

  const CreateTaskBottomSheetUi({
    super.key,
    required this.familyId,
    required this.familyMembers,
    required this.onTaskCreated,
  });

  @override
  State<CreateTaskBottomSheetUi> createState() => _CreateTaskBottomSheetUiState();
}

class _CreateTaskBottomSheetUiState extends State<CreateTaskBottomSheetUi> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedModule = 'SHOPPING';
  String? _selectedAssigneeId;
  String _selectedDateLabel = 'Today';
  TimeOfDay? _selectedTime;

  final List<String> _modules = ['SHOPPING', 'CHORES', 'HEALTH', 'PETS', 'FINANCE', 'OTHER'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateLabel = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a task title."), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      final url = Uri.parse('http://10.0.2.2:8080/api/tasks');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'familyId': widget.familyId,
          'title': title,
          'originModule': _selectedModule,
          'assignedToMemberId': _selectedAssigneeId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          widget.onTaskCreated();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task created successfully!"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint("Error creating task: $e");
    }
  }

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Task',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Task Title (e.g., Buy eggs)',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8FAF9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Description or Quantity (e.g., 2 cartons)',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8FAF9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Category Module', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF244032))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedModule,
              items: _modules.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _selectedModule = val!),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAF9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Assign To Member', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF244032))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedAssigneeId,
              hint: const Text('Select family member'),
              items: widget.familyMembers.map<DropdownMenuItem<String>>((member) {
                return DropdownMenuItem<String>(
                  value: member['id'],
                  child: Text(member['name'] ?? member['nickname'] ?? 'Member'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAssigneeId = val),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAF9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDueDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Date',
                        filled: true,
                        fillColor: const Color(0xFFF8FAF9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Text(_selectedDateLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Time (Optional)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAF9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Text(_selectedTime != null ? _selectedTime!.format(context) : 'Select time'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A8B71),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Task', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}