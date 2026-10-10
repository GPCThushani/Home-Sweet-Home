import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/screens/global_tasks_screen.dart';

class HomeMaintenanceScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const HomeMaintenanceScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

  @override
  State<HomeMaintenanceScreen> createState() => _HomeMaintenanceScreenState();
}

class _HomeMaintenanceScreenState extends State<HomeMaintenanceScreen> with SingleTickerProviderStateMixin {
  static const String baseUrl = 'http://localhost:8080/api/maintenance';
  int _currentNavIndex = 4;
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _providers = [];

  static const Color ivory = Color(0xFFFAF8F3);
  static const Color white = Colors.white;
  static const Color forest = Color(0xFF355C4A);
  static const Color green = Color(0xFF4A8B71);
  static const Color paleGreen = Color(0xFFE5EEE7);
  static const Color textDark = Color(0xFF244032);
  static const Color textSecondary = Color(0xFF65716B);
  static const Color muted = Color(0xFF98A19C);
  static const Color border = Color(0xFFE5E1D9);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMaintenanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (jwtToken != null && jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
    };
  }

  Future<void> _loadMaintenanceData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final headers = await _headers();
      
      final itemsRes = await http.get(Uri.parse('$baseUrl/items/${widget.familyId}'), headers: headers);
      final providersRes = await http.get(Uri.parse('$baseUrl/providers/${widget.familyId}'), headers: headers);

      List<Map<String, dynamic>> loadedItems = [];
      if (itemsRes.statusCode == 200) {
        final List decoded = jsonDecode(itemsRes.body);
        for (var item in decoded) {
          loadedItems.add({
            'id': item['id'],
            'title': item['title'],
            'category': item['category'] ?? 'APPLIANCE',
            'nextDueDate': item['nextDueDate'],
            'lastServicedDate': item['lastServicedDate'],
            'intervalDays': item['intervalDays'],
            'providerId': item['providerId'],
          });
        }
      }

      List<Map<String, dynamic>> loadedProviders = [];
      if (providersRes.statusCode == 200) {
        final List decoded = jsonDecode(providersRes.body);
        for (var p in decoded) {
          loadedProviders.add({
            'id': p['id'],
            'name': p['providerName'],
            'phone': p['phoneNumber'],
            'address': p['address'],
            'notes': p['notes'],
          });
        }
      }

      if (mounted) {
        setState(() {
          _items = loadedItems;
          _providers = loadedProviders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading maintenance data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalCount => _items.length;
  int get _dueSoonCount {
    final now = DateTime.now();
    return _items.where((i) {
      if (i['nextDueDate'] == null) return false;
      final due = DateTime.parse(i['nextDueDate']);
      final diff = due.difference(now).inDays;
      return diff >= 0 && diff <= 15;
    }).length;
  }

  int get _overdueCount {
    final now = DateTime.now();
    return _items.where((i) {
      if (i['nextDueDate'] == null) return false;
      final due = DateTime.parse(i['nextDueDate']);
      return due.isBefore(now);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final appliances = _items.where((i) => i['category'] == 'APPLIANCE').toList();
    final services = _items.where((i) => i['category'] == 'SERVICE').toList();

    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                          'Home Maintenance',
                          style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Keep your home running smoothly with ease.',
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
                        // Summary Dashboard Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryStat('Total Items', '$_totalCount', textDark),
                              Container(height: 30, width: 1, color: border),
                              _buildSummaryStat('Due Soon', '$_dueSoonCount', Colors.orange.shade800),
                              Container(height: 30, width: 1, color: border),
                              _buildSummaryStat('Overdue', '$_overdueCount', Colors.redAccent),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab Bar Header (Fully stretched)
                        Container(
                          decoration: BoxDecoration(
                            color: paleGreen.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: false,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: white,
                            unselectedLabelColor: textDark,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            tabs: const [
                              Tab(text: 'Appliances'),
                              Tab(text: 'Home Services'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab Views Content
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildItemList(appliances),
                              _buildItemList(services),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddOrEditMaintenanceModal(null),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: forest,
                                  foregroundColor: white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showManageProvidersModal,
                                icon: const Icon(Icons.contacts_rounded, size: 18, color: green),
                                label: const Text('Service Contacts', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: green),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildItemList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items added here yet.', style: TextStyle(color: muted, fontSize: 13)));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final nextDue = item['nextDueDate'] ?? 'Not scheduled';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showHistoryModal(item['id'], item['title']),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Next service: $nextDue', style: const TextStyle(fontSize: 11, color: textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded, color: green, size: 22),
                    tooltip: 'Mark Complete',
                    onPressed: () => _confirmCompleteService(item['id'], item['title']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: forest, size: 20),
                    tooltip: 'Edit Schedule',
                    onPressed: () => _showAddOrEditMaintenanceModal(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteItem(item['id']),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmCompleteService(dynamic id, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Complete $title?'),
          content: const Text('Are you sure you want to mark this service as completed? This will automatically advance the next due date.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white),
              onPressed: () {
                Navigator.pop(context);
                _completeService(id);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeService(dynamic id) async {
    try {
      final headers = await _headers();
      final res = await http.post(Uri.parse('$baseUrl/items/${widget.familyId}/$id/complete'), headers: headers);
      if (res.statusCode == 200 || res.statusCode == 201) {
        _loadMaintenanceData();
        _showMessage('Service marked as completed!');
      }
    } catch (_) {}
  }

  Future<void> _deleteItem(dynamic id) async {
    try {
      final headers = await _headers();
      await http.delete(Uri.parse('$baseUrl/items/${widget.familyId}/$id'), headers: headers);
      _loadMaintenanceData();
    } catch (_) {}
  }

  Future<void> _showHistoryModal(dynamic itemId, String itemName) async {
    List<dynamic> history = [];
    try {
      final headers = await _headers();
      final res = await http.get(Uri.parse('$baseUrl/items/${widget.familyId}/$itemId/history'), headers: headers);
      if (res.statusCode == 200) {
        history = jsonDecode(res.body);
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service History: $itemName', style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: history.isEmpty
                    ? const Center(child: Text('No service history recorded yet.', style: TextStyle(color: muted)))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final h = history[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.history_rounded, color: green, size: 18),
                            title: Text('Serviced on: ${h['serviceDate']}', style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                            subtitle: Text('Completed by: ${h['completedBy'] ?? 'Family member'}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOrEditMaintenanceModal(Map<String, dynamic>? itemToEdit) {
    final isEditing = itemToEdit != null;
    final titleController = TextEditingController(text: isEditing ? itemToEdit['title'] : '');
    String category = isEditing ? itemToEdit['category'] : 'APPLIANCE';

    int initialDays = isEditing ? (itemToEdit['intervalDays'] ?? 180) : 180;
    int years = initialDays ~/ 365;
    int months = (initialDays % 365) ~/ 30;
    int days = (initialDays % 365) % 30;

    final yearsController = TextEditingController(text: years.toString());
    final monthsController = TextEditingController(text: months.toString());
    final daysController = TextEditingController(text: days.toString());

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
                  Text(isEditing ? 'Edit Maintenance Item' : 'Add Maintenance Item', style: const TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  TextField(controller: titleController, decoration: _inputDecoration('Item Name', hint: 'e.g. AC Servicing')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: _inputDecoration('Category'),
                    items: const [
                      DropdownMenuItem(value: 'APPLIANCE', child: Text('Appliance / Equipment')),
                      DropdownMenuItem(value: 'SERVICE', child: Text('Home Service')),
                    ],
                    onChanged: (val) => setModalState(() => category = val!),
                  ),
                  const SizedBox(height: 12),
                  const Text('Service Interval Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: yearsController, keyboardType: TextInputType.number, decoration: _inputDecoration('Years'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: monthsController, keyboardType: TextInputType.number, decoration: _inputDecoration('Months'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: daysController, keyboardType: TextInputType.number, decoration: _inputDecoration('Days'))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isNotEmpty) {
                          int totalDays = (int.tryParse(yearsController.text) ?? 0) * 365 +
                              (int.tryParse(monthsController.text) ?? 0) * 30 +
                              (int.tryParse(daysController.text) ?? 0);
                          if (totalDays <= 0) totalDays = 30;

                          try {
                            final headers = await _headers();
                            if (isEditing) {
                              await http.put(
                                Uri.parse('$baseUrl/items/${widget.familyId}/${itemToEdit['id']}'),
                                headers: headers,
                                body: jsonEncode({
                                  'title': title,
                                  'category': category,
                                  'intervalDays': totalDays,
                                }),
                              );
                            } else {
                              await http.post(
                                Uri.parse('$baseUrl/items/${widget.familyId}'),
                                headers: headers,
                                body: jsonEncode({
                                  'title': title,
                                  'category': category,
                                  'intervalDays': totalDays,
                                }),
                              );
                            }
                            if (context.mounted) Navigator.pop(context);
                            _loadMaintenanceData();
                          } catch (_) {}
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text(isEditing ? 'Save Changes' : 'Save Item', style: const TextStyle(fontWeight: FontWeight.w800)),
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

  void _showManageProvidersModal() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

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
                  const Text('Trusted Service Contacts', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: _providers.isEmpty
                        ? const Center(child: Text('No contacts saved yet.', style: TextStyle(color: muted)))
                        : ListView.builder(
                            itemCount: _providers.length,
                            itemBuilder: (context, index) {
                              final p = _providers[index];
                              return ListTile(
                                dense: true,
                                title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                                subtitle: Text('${p['phone'] ?? 'No phone'} • ${p['address'] ?? ''}'),
                                trailing: const Icon(Icons.phone_rounded, color: green, size: 18),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  const Text('Add New Contact', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(controller: nameController, decoration: _inputDecoration('Provider Name (e.g. Kamal AC Tech)')),
                  const SizedBox(height: 8),
                  TextField(controller: phoneController, decoration: _inputDecoration('Phone Number')),
                  const SizedBox(height: 8),
                  TextField(controller: addressController, decoration: _inputDecoration('Location / Address')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        try {
                          final headers = await _headers();
                          await http.post(
                            Uri.parse('$baseUrl/providers/${widget.familyId}'),
                            headers: headers,
                            body: jsonEncode({
                              'providerName': name,
                              'phoneNumber': phoneController.text.trim(),
                              'address': addressController.text.trim(),
                            }),
                          );
                          if (context.mounted) Navigator.pop(context);
                          _loadMaintenanceData();
                          _showMessage('Service contact saved!');
                        } catch (_) {}
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, minimumSize: const Size(double.infinity, 45)),
                    child: const Text('Save Contact'),
                  ),
                ],
              ),
            );
          },
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