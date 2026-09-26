import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateTaskBottomSheet extends StatefulWidget {
  final String familyId;
  final List<Map<String, dynamic>> familyMembers;
  final VoidCallback onTaskCreated;

  const CreateTaskBottomSheet({
    super.key,
    required this.familyId,
    required this.familyMembers,
    required this.onTaskCreated,
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
          const Text(
            'Create New Task',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
          ),
          const SizedBox(height: 18),
          _buildTextField(controller: _titleController, hint: 'Task Title (e.g., Buy eggs)'),
          const SizedBox(height: 12),
          _buildTextField(controller: _descriptionController, hint: 'Description or Quantity (e.g., 2 cartons)', maxLines: 3),
          const SizedBox(height: 16),
          const Text('Category Module', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF244032))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedModule,
            items: _modules.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() => _selectedModule = val!),
            decoration: _dropdownDecoration(),
          ),
          const SizedBox(height: 16),
          const Text('Assign To Member', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF244032))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedAssigneeId,
            hint: Text(widget.familyMembers.isEmpty ? 'No family members available' : 'Select family member'),
            items: widget.familyMembers
                .where((member) => member['id'] != null)
                .map<DropdownMenuItem<String>>((member) {
              final id = member['id'].toString();
              
              // Extract properties safely
              final userObj = member['user'];
              final userEmail = userObj is Map ? userObj['email']?.toString().toLowerCase() : '';
              final nickname = member['nickname']?.toString() ?? '';
              final role = member['role']?.toString()?.toUpperCase() ?? '';

              // Explicit display name override logic
              String displayName;
              if (userEmail == 'perera@gmail.com' || nickname.toLowerCase() == 'admin') {
                displayName = 'Father';
              } else if (role == 'MEMBER' || role == 'CHILD') {
                displayName = 'Daughter';
              } else {
                displayName = nickname.isNotEmpty ? nickname : 'Family Member';
              }

              return DropdownMenuItem<String>(
                value: id, 
                child: Text(displayName),
              );
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