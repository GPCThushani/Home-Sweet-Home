import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/screens/global_tasks_screen.dart';

class ShoppingScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const ShoppingScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  static const String baseUrl = 'http://localhost:8080/api';

  bool _isLoading = true;
  List<dynamic> _items = [];
  List<dynamic> _customSections = [];
  String? _activeSectionKey;
  String _selectedCategory = '';

  final Map<String, List<String>> builtInCategories = {
    'WEEKLY': ['Fresh Fruits & Vegetables', 'Meat & Seafood', 'Dairy & Refrigerated', 'Bakery & Bread', 'General / Other'],
    'MONTHLY': [
      'Pantry Staples & Grains',
      'Spices, Condiments & Baking',
      'Frozen & Long-Lasting Proteins',
      'Shelf-Stable & Canned Goods',
      'Household & Cleaning Supplies',
      'Personal Care & Toiletries'
    ],
    'LIFESTYLE': ['Clothes & Shoes', 'Makeup & Cosmetics', 'Stationery & Books', 'Game Equipment', 'Electronic Equipment'],
    'MEDICINE': [],
  };

  final Map<String, String> categoryDescriptions = {
    'Fresh Fruits & Vegetables': 'Fresh fruits, leafy greens, root vegetables and everyday produce.',
    'Meat & Seafood': 'Chicken, beef, pork, fish, seafood and other fresh proteins.',
    'Dairy & Refrigerated': 'Milk, butter, cheese, yogurt and eggs.',
    'Bakery & Bread': 'Bread, buns, cakes, bakery snacks and other fresh bakery goods.',
    'General / Other': 'Other fresh or weekly household items.',
    'Pantry Staples & Grains': 'Rice, flour, oats, noodles, pasta, lentils, dried beans, chickpeas and cooking oils.',
    'Spices, Condiments & Baking': 'Salt, sugar, turmeric, chili powder, sauces, vinegar, baking ingredients and more.',
    'Frozen & Long-Lasting Proteins': 'Frozen chicken, fish, seafood, minced meat, vegetables and long-lasting proteins.',
    'Shelf-Stable & Canned Goods': 'Canned fish, beans, tomato products, coconut milk and other shelf-stable goods.',
    'Household & Cleaning Supplies': 'Laundry detergent, dishwashing liquid, cleaners, trash bags, sponges and paper products.',
    'Personal Care & Toiletries': 'Shampoo, conditioner, soap, toothpaste, dental floss, deodorant and personal care products.',
    'Clothes & Shoes': 'Clothing, footwear and everyday personal accessories.',
    'Makeup & Cosmetics': 'Makeup, skincare and cosmetic products.',
    'Stationery & Books': 'Books, pens, notebooks, school and office stationery.',
    'Game Equipment': 'Board games, sports equipment and other recreational items.',
    'Electronic Equipment': 'Small electronics, accessories and household electronic equipment.',
  };

  final List<Map<String, dynamic>> standardCards = [
    {
      'key': 'WEEKLY',
      'title': 'Weekly Groceries',
      'subtitle': 'Fresh produce, milk, eggs & everyday perishables',
      'image': 'assets/images/shopping/weekly.jpg',
      'color': Color(0xFFE5EEE7),
      'imageOnRight': true,
    },
    {
      'key': 'MONTHLY',
      'title': 'Monthly Bulk & Staples',
      'subtitle': 'Rice, grains, cleaning supplies & monthly restocks',
      'image': 'assets/images/shopping/monthly.png',
      'color': Color(0xFFF4DDD2),
      'imageOnRight': false,
    },
    {
      'key': 'LIFESTYLE',
      'title': 'Personal & Lifestyle Goods',
      'subtitle': 'Clothes, cosmetics, stationery, games & electronics',
      'image': 'assets/images/shopping/common.png',
      'color': Color(0xFFF0E5EE),
      'imageOnRight': true,
    },
    {
      'key': 'MEDICINE',
      'title': 'Medicine & Pharmacy',
      'subtitle': 'Prescriptions, first aid, vitamins & pharmacy items',
      'image': 'assets/images/shopping/medicine.png',
      'color': Color(0xFFFFECE5),
      'imageOnRight': false,
    },
  ];

  List<dynamic> _history = [];
  int _currentNavIndex = 4;
  DateTime _previewDate = DateTime.now();

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
    _loadEverything();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (jwtToken != null && jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
    };
  }

  Future<void> _loadEverything() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.wait([
      _fetchItems(),
      _fetchCustomSections(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchItems() async {
    try {
      final headers = await _headers();
      final response = await http.get(Uri.parse('$baseUrl/shopping/${widget.familyId}'), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (mounted && decoded is List) setState(() => _items = decoded);
      }
    } catch (e) {
      debugPrint('Shopping items error: $e');
    }
  }

  Future<void> _fetchCustomSections() async {
    try {
      final headers = await _headers();
      final response = await http.get(Uri.parse('$baseUrl/shopping/sections/${widget.familyId}'), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (mounted && decoded is List) setState(() => _customSections = decoded);
      }
    } catch (e) {
      debugPrint('Shopping sections error: $e');
    }
  }

  Future<void> _createCustomSection() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Custom Section', style: TextStyle(color: Color(0xFF244032), fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Create another shopping space for something unique to your family.', style: TextStyle(color: Color(0xFF65716B), fontSize: 13, height: 1.4)),
                const SizedBox(height: 22),
                TextField(controller: titleController, decoration: _inputDecoration('Section Name', hint: 'e.g. Pet Care')),
                const SizedBox(height: 14),
                TextField(controller: descriptionController, maxLines: 2, decoration: _inputDecoration('Description', hint: 'e.g. Food, treats & grooming supplies')),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      try {
                        final headers = await _headers();
                        final response = await http.post(
                          Uri.parse('$baseUrl/shopping/sections/${widget.familyId}'),
                          headers: headers,
                          body: jsonEncode({
                            'title': title,
                            'description': descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : 'Custom family shopping items',
                            'categories': ['General Items'],
                          }),
                        );
                        if (response.statusCode == 200) {
                          if (context.mounted) Navigator.pop(context);
                          await _fetchCustomSections();
                          _showMessage('Custom section created.');
                        }
                      } catch (e) {
                        debugPrint('Create section error: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF355C4A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text('Create Section', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _editCustomSection(Map<String, dynamic> section) async {
    final titleController = TextEditingController(text: section['title']?.toString() ?? '');
    final descriptionController = TextEditingController(text: section['description']?.toString() ?? '');
    final id = section['id'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Section', style: TextStyle(color: Color(0xFF244032), fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextField(controller: titleController, decoration: _inputDecoration('Section Name')),
              const SizedBox(height: 14),
              TextField(controller: descriptionController, maxLines: 2, decoration: _inputDecoration('Description')),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final headers = await _headers();
                      final response = await http.put(
                        Uri.parse('$baseUrl/shopping/sections/${widget.familyId}/$id'),
                        headers: headers,
                        body: jsonEncode({
                          'title': titleController.text.trim(),
                          'description': descriptionController.text.trim(),
                        }),
                      );
                      if (response.statusCode == 200) {
                        if (context.mounted) Navigator.pop(context);
                        await _fetchCustomSections();
                        _showMessage('Section updated.');
                      }
                    } catch (e) {
                      debugPrint('Edit section error: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF355C4A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteCustomSection(Map<String, dynamic> section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete this section?'),
          content: Text('All shopping items belonging to "${section['title']}" will also be removed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), child: const Text('Delete')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final headers = await _headers();
      final response = await http.delete(Uri.parse('$baseUrl/shopping/sections/${widget.familyId}/${section['id']}'), headers: headers);
      if (response.statusCode == 204) {
        if (_activeSectionKey == section['sectionKey']) setState(() => _activeSectionKey = null);
        await _fetchCustomSections();
        await _fetchItems();
        _showMessage('Section deleted.');
      }
    } catch (e) {
      debugPrint('Delete section error: $e');
    }
  }

  Future<void> _addCategory(String sectionKey, {int? customSectionId}) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Topic'),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'e.g. Snacks, Beverages')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final category = controller.text.trim();
                if (category.isEmpty) return;

                if (customSectionId != null) {
                  try {
                    final headers = await _headers();
                    final response = await http.post(
                      Uri.parse('$baseUrl/shopping/sections/${widget.familyId}/$customSectionId/categories'),
                      headers: headers,
                      body: jsonEncode({'category': category}),
                    );
                    if (response.statusCode == 200) {
                      if (context.mounted) Navigator.pop(context);
                      await _fetchCustomSections();
                      setState(() => _selectedCategory = category);
                    }
                  } catch (e) {
                    debugPrint('Add category error: $e');
                  }
                } else {
                  if (context.mounted) Navigator.pop(context);
                  setState(() {
                    builtInCategories[sectionKey]?.add(category);
                    categoryDescriptions[category] = 'Family-created shopping topic.';
                    _selectedCategory = category;
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showAddItemModal({
    required String sectionKey,
    required String category,
    Map<String, dynamic>? existingItem,
  }) async {
    final isEditing = existingItem != null;
    final nameController = TextEditingController(text: existingItem?['name']?.toString() ?? '');
    final quantityController = TextEditingController(text: existingItem?['quantity']?.toString() ?? '');
    final notesController = TextEditingController(text: existingItem?['varietyNotes']?.toString() ?? '');
    DateTime selectedDate = _parseDate(existingItem?['shoppingDate']) ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? 'Edit Shopping Item' : 'Add Item', style: const TextStyle(color: Color(0xFF244032), fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(category, style: const TextStyle(color: Color(0xFF4A8B71), fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextField(controller: nameController, decoration: _inputDecoration('Item Name', hint: 'e.g. Milk, Bananas, Rice')),
                    const SizedBox(height: 14),
                    TextField(controller: quantityController, decoration: _inputDecoration('Quantity', hint: 'e.g. 2 packs, 5 kg')),
                    const SizedBox(height: 14),
                    TextField(controller: notesController, maxLines: 2, decoration: _inputDecoration('Brand / Variety / Notes', hint: 'e.g. Organic, Anchor, Size M')),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setModalState(() => selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAF9), borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: Color(0xFF4A8B71), size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Shopping date: ${_formatDate(selectedDate)}', style: const TextStyle(color: Color(0xFF244032), fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          final body = {
                            'name': name,
                            'category': sectionKey,
                            'subCategory': category,
                            'quantity': quantityController.text.trim(),
                            'varietyNotes': notesController.text.trim(),
                            'completed': existingItem?['completed'] == true,
                            'shoppingDate': _dateToString(selectedDate),
                          };

                          try {
                            final headers = await _headers();
                            late http.Response response;
                            if (isEditing) {
                              response = await http.put(
                                Uri.parse('$baseUrl/shopping/${widget.familyId}/item/${existingItem['id']}'),
                                headers: headers,
                                body: jsonEncode(body),
                              );
                            } else {
                              response = await http.post(
                                Uri.parse('$baseUrl/shopping/${widget.familyId}'),
                                headers: headers,
                                body: jsonEncode(body),
                              );
                            }

                            if (response.statusCode == 200 && context.mounted) {
                              Navigator.pop(context);
                              await _fetchItems();
                              _showMessage(isEditing ? 'Item updated.' : 'Item added to the list.');
                            }
                          } catch (e) {
                            debugPrint('Save item error: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF355C4A), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Text(isEditing ? 'Save Changes' : 'Add to List', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    quantityController.dispose();
    notesController.dispose();
  }

  Future<void> _toggleItem(Map<String, dynamic> item) async {
    final current = item['completed'] == true;
    try {
      final headers = await _headers();
      final response = await http.put(
        Uri.parse('$baseUrl/shopping/${widget.familyId}/item/${item['id']}'),
        headers: headers,
        body: jsonEncode({
          'name': item['name'],
          'category': item['category'],
          'subCategory': item['subCategory'],
          'quantity': item['quantity'],
          'varietyNotes': item['varietyNotes'],
          'completed': !current,
          'shoppingDate': item['shoppingDate'],
        }),
      );
      if (response.statusCode == 200) await _fetchItems();
    } catch (e) {
      debugPrint('Toggle item error: $e');
    }
  }

  Future<void> _deleteItem(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http.delete(Uri.parse('$baseUrl/shopping/${widget.familyId}/item/$id'), headers: headers);
      if (response.statusCode == 204) {
        await _fetchItems();
        _showMessage('Item removed.');
      }
    } catch (e) {
      debugPrint('Delete item error: $e');
    }
  }

  Future<void> _archiveBoughtItems() async {
    final boughtCount = _items.where((item) => item['completed'] == true).length;
    if (boughtCount == 0) {
      _showMessage('There are no bought items to archive.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start a new shopping list?'),
          content: Text('$boughtCount bought item${boughtCount == 1 ? '' : 's'} will move to shopping history.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF355C4A), foregroundColor: Colors.white), child: const Text('Start New List')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final headers = await _headers();
      final response = await http.post(Uri.parse('$baseUrl/shopping/archive/${widget.familyId}'), headers: headers);
      if (response.statusCode == 200) {
        await _fetchItems();
        _showMessage('Bought items archived. Your new list is ready.');
      }
    } catch (e) {
      debugPrint('Archive error: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final headers = await _headers();
      final response = await http.get(Uri.parse('$baseUrl/shopping/history/${widget.familyId}'), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (mounted && decoded is List) setState(() => _history = decoded);
      }
    } catch (e) {
      debugPrint('History error: $e');
    }
  }

  Future<void> _restoreLastList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore previous list?'),
          content: const Text('The latest completed shopping list will be added back as a fresh list.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF355C4A), foregroundColor: Colors.white), child: const Text('Restore List')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final headers = await _headers();
      final response = await http.post(Uri.parse('$baseUrl/shopping/restore-last/${widget.familyId}'), headers: headers);
      if (response.statusCode == 200) {
        final restored = jsonDecode(response.body);
        await _fetchItems();
        _showMessage(restored is List && restored.isNotEmpty ? '${restored.length} previous items restored.' : 'No previous shopping list found.');
      }
    } catch (e) {
      debugPrint('Restore error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : _activeSectionKey == null
                      ? _buildDashboard()
                      : _activeSectionKey == 'PREVIEW'
                          ? _buildPreview()
                          : _activeSectionKey == 'HISTORY'
                              ? _buildHistory()
                              : _buildSectionDetail(_activeSectionKey!),
            ),
          ],
        ),
      ),
      floatingActionButton: _activeSectionKey == null
          ? FloatingActionButton(
              backgroundColor: forest,
              foregroundColor: white,
              tooltip: 'Add Custom Section',
              onPressed: _createCustomSection,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    final title = _activeSectionKey == null
        ? 'Family Shopping'
        : _activeSectionKey == 'PREVIEW'
            ? 'Shopping Preview'
            : _activeSectionKey == 'HISTORY'
                ? 'Shopping History'
                : _getSectionTitle(_activeSectionKey!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: paleGreen.withValues(alpha: 0.72),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        border: Border(bottom: BorderSide(color: green.withValues(alpha: 0.18))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
            onPressed: () {
              if (_activeSectionKey != null) {
                setState(() => _activeSectionKey = null);
              } else {
                Navigator.maybePop(context);
              }
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(_activeSectionKey == null ? 'Everything your family plans to buy, together.' : 'Keep this list simple and easy to shop.', style: const TextStyle(color: textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    List<dynamic> formattedCustomSections = _customSections.map((s) {
      final map = Map<String, dynamic>.from(s);
      return {
        'key': map['sectionKey'],
        'title': map['title'],
        'subtitle': map['description'] ?? 'Custom family shopping section',
        'image': 'assets/images/shopping/option.png',
        'color': white,
        'imageOnRight': true,
        'isCustom': true,
        'raw': map,
      };
    }).toList();

    final allCards = [
      ...standardCards,
      ...formattedCustomSections,
      {
        'key': 'PREVIEW',
        'title': 'Master Preview & History',
        'subtitle': 'View aggregated checklist & archive completed trips',
        'image': 'assets/images/shopping/preview.png',
        'color': paleGreen,
        'imageOnRight': true,
        'isCustom': false,
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: allCards.length,
      itemBuilder: (context, index) {
        final card = allCards[index];
        final bool imageOnRight = card['imageOnRight'] as bool;
        final String key = card['key'] as String;
        final bool isCustom = card['isCustom'] == true;

        return GestureDetector(
          onTap: () => _openSection(key),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 116,
            decoration: BoxDecoration(
              color: card['color'] as Color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: imageOnRight ? 12 : null,
                  left: imageOnRight ? null : 12,
                  top: 12,
                  bottom: 12,
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      card['image'] as String,
                      width: 100,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: forest.withValues(alpha: 0.12), child: const Icon(Icons.shopping_basket_outlined, color: forest, size: 32)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: imageOnRight ? 18 : 114,
                    right: imageOnRight ? (isCustom ? 54 : 114) : 18,
                    top: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card['title'].toString(), style: const TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(card['subtitle'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: textSecondary, fontSize: 11, height: 1.3)),
                    ],
                  ),
                ),
                if (isCustom)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: textSecondary, size: 20),
                      onSelected: (value) {
                        if (value == 'edit') _editCustomSection(card['raw']);
                        if (value == 'delete') _deleteCustomSection(card['raw']);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSection(String key) {
    if (key == 'PREVIEW') {
      setState(() => _activeSectionKey = 'PREVIEW');
      return;
    }
    final categories = _getCategories(key);
    setState(() {
      _activeSectionKey = key;
      _selectedCategory = categories.isNotEmpty ? categories.first : '';
    });
  }

  List<String> _getCategories(String key) {
    if (key.startsWith('CUSTOM_')) {
      final section = _customSections.firstWhere((s) => s['sectionKey']?.toString() == key, orElse: () => {});
      if (section.isNotEmpty && section['categories'] is List) {
        return List<String>.from(section['categories']);
      }
      return [];
    }
    return builtInCategories[key] ?? [];
  }

  int? _getCustomSectionId(String key) {
    if (!key.startsWith('CUSTOM_')) return null;
    final section = _customSections.firstWhere((s) => s['sectionKey']?.toString() == key, orElse: () => {});
    return section.isNotEmpty ? section['id'] : null;
  }

  String _getSectionTitle(String key) {
    switch (key) {
      case 'WEEKLY': return 'Weekly Groceries';
      case 'MONTHLY': return 'Monthly Bulk & Staples';
      case 'LIFESTYLE': return 'Personal & Lifestyle';
      case 'MEDICINE': return 'Medicine & Pharmacy';
      case 'PREVIEW': return 'Shopping Preview';
      case 'HISTORY': return 'Shopping History';
    }
    final section = _customSections.firstWhere((s) => s['sectionKey']?.toString() == key, orElse: () => {});
    return section.isNotEmpty ? (section['title']?.toString() ?? 'Shopping') : 'Shopping';
  }

  Widget _buildSectionDetail(String key) {
    final categories = _getCategories(key);

    return Column(
      children: [
        const SizedBox(height: 10),
        if (categories.isNotEmpty)
          SizedBox(
            height: 54,
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final selected = category == _selectedCategory;
                      return ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: forest,
                        backgroundColor: white,
                        side: BorderSide(color: selected ? forest : border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        labelStyle: TextStyle(color: selected ? white : textDark, fontSize: 12, fontWeight: FontWeight.w700),
                        onSelected: (_) => setState(() => _selectedCategory = category),
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    tooltip: 'Add topic',
                    onPressed: () => _addCategory(key, customSectionId: _getCustomSectionId(key)),
                    icon: const Icon(Icons.add_circle_outline_rounded, color: green, size: 27),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildEmptyCategoryState(key),
          ),
        if (categories.isNotEmpty) const SizedBox(height: 10),
        Expanded(
          child: categories.isEmpty ? const SizedBox() : _buildCategoryItems(key, _selectedCategory),
        ),
      ],
    );
  }

  Widget _buildEmptyCategoryState(String sectionKey) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(
        children: [
          const Icon(Icons.playlist_add_rounded, color: green, size: 38),
          const SizedBox(height: 10),
          const Text('Start by creating a topic', style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 5),
          const Text('Create your own category and then add the items your family needs.', textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _addCategory(sectionKey, customSectionId: _getCustomSectionId(sectionKey)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Topic'),
            style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItems(String sectionKey, String category) {
    final items = _items.where((item) {
      return item['category']?.toString() == sectionKey && item['subCategory']?.toString() == category;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: paleGreen.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category, style: const TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(categoryDescriptions[category] ?? 'Add the items your family needs here.', style: const TextStyle(color: textSecondary, fontSize: 11, height: 1.35)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddItemModal(sectionKey: sectionKey, category: category),
                  icon: const Icon(Icons.add_circle_rounded, color: green, size: 28),
                  tooltip: 'Add item',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? _buildNoItemsState(sectionKey, category)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildItemTile(items[index], sectionKey, category);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoItemsState(String sectionKey, String category) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 42, color: muted.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            const Text('Nothing on the list yet', style: TextStyle(color: textDark, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text('Add something your family needs to buy.', style: TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _showAddItemModal(sectionKey: sectionKey, category: category),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
              style: OutlinedButton.styleFrom(foregroundColor: forest, side: const BorderSide(color: forest), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(dynamic rawItem, String sectionKey, String category) {
    final item = Map<String, dynamic>.from(rawItem);
    final completed = item['completed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(
          value: completed,
          activeColor: green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          onChanged: (_) => _toggleItem(item),
        ),
        title: Text(item['name']?.toString() ?? '', style: TextStyle(color: textDark, fontWeight: FontWeight.w700, decoration: completed ? TextDecoration.lineThrough : null, decorationColor: muted)),
        subtitle: _buildItemSubtitle(item, completed),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddItemModal(sectionKey: sectionKey, category: category, existingItem: item);
            } else if (value == 'delete') {
              _deleteItem(item['id']);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Edit')])),
            PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18), SizedBox(width: 10), Text('Delete')])),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSubtitle(Map<String, dynamic> item, bool completed) {
    final quantity = item['quantity']?.toString() ?? '';
    final notes = item['varietyNotes']?.toString() ?? '';
    final parts = <String>[];
    if (quantity.isNotEmpty) parts.add(quantity);
    if (notes.isNotEmpty) parts.add(notes);

    return Text(parts.isEmpty ? 'No quantity or notes added' : parts.join(' • '), style: const TextStyle(color: textSecondary, fontSize: 11));
  }

  Widget _buildPreview() {
    final dateItems = _items.where((item) {
      final date = _parseDate(item['shoppingDate']);
      return date != null && _sameDay(date, _previewDate);
    }).toList();

    final grouped = <String, List<dynamic>>{};
    for (final item in dateItems) {
      final category = item['category']?.toString() ?? 'OTHER';
      grouped.putIfAbsent(category, () => []).add(item);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _dateArrow(Icons.chevron_left_rounded, () => setState(() => _previewDate = _previewDate.subtract(const Duration(days: 1)))),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                  child: Column(
                    children: [
                      const Text('Shopping List', style: TextStyle(color: textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(_formatLongDate(_previewDate), style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              _dateArrow(Icons.chevron_right_rounded, () => setState(() => _previewDate = _previewDate.add(const Duration(days: 1)))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _archiveBoughtItems,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Bought All / New List'),
                  style: OutlinedButton.styleFrom(foregroundColor: forest, side: const BorderSide(color: forest), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Shopping history',
                onPressed: () async {
                  await _loadHistory();
                  if (mounted) setState(() => _activeSectionKey = 'HISTORY');
                },
                icon: const Icon(Icons.history_rounded, color: forest),
              ),
              IconButton(
                tooltip: 'Restore last list',
                onPressed: _restoreLastList,
                icon: const Icon(Icons.restore_rounded, color: green),
              ),
            ],
          ),
        ),
        Expanded(
          child: dateItems.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_rounded, color: muted, size: 44),
                        SizedBox(height: 12),
                        Text('Nothing planned for this day.', style: TextStyle(color: textDark, fontWeight: FontWeight.w700)),
                        SizedBox(height: 5),
                        Text('Add items to a shopping list and they will appear here.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: grouped.entries.map((entry) => _buildPreviewGroup(entry.key, entry.value)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildPreviewGroup(String sectionKey, List<dynamic> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(child: Text(_getSectionTitle(sectionKey), style: const TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 15))),
                Text('${items.length} item${items.length == 1 ? '' : 's'}', style: const TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          const Divider(height: 1, color: border),
          ...items.map((raw) {
            final item = Map<String, dynamic>.from(raw);
            final completed = item['completed'] == true;
            return CheckboxListTile(
              value: completed,
              activeColor: green,
              dense: true,
              title: Text(item['name']?.toString() ?? '', style: TextStyle(color: textDark, fontWeight: FontWeight.w600, decoration: completed ? TextDecoration.lineThrough : null)),
              subtitle: Text('${item['subCategory'] ?? ''}${item['quantity']?.toString().isNotEmpty == true ? ' • ${item['quantity']}' : ''}', style: const TextStyle(fontSize: 10, color: muted)),
              onChanged: (_) => _toggleItem(item),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, color: muted, size: 46),
            const SizedBox(height: 12),
            const Text('No shopping history yet.', style: TextStyle(color: textDark, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Bought lists will appear here after you start a new list.', style: TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 18),
            ElevatedButton.icon(onPressed: _restoreLastList, icon: const Icon(Icons.restore_rounded), label: const Text('Restore Previous List'), style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white)),
          ],
        ),
      );
    }

    final grouped = <String, List<dynamic>>{};
    for (final item in _history) {
      final batch = item['archiveBatchId']?.toString() ?? 'UNKNOWN';
      grouped.putIfAbsent(batch, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Row(
          children: [
            const Expanded(child: Text('Previous Shopping Lists', style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 16))),
            TextButton.icon(onPressed: _restoreLastList, icon: const Icon(Icons.restore_rounded, size: 17), label: const Text('Restore Latest')),
          ],
        ),
        const SizedBox(height: 10),
        ...grouped.entries.map((entry) {
          final items = entry.value;
          final date = _parseDateTime(items.first['archivedAt']);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
            child: ExpansionTile(
              title: Text(date != null ? 'Shopping on ${_formatDate(date)}' : 'Previous Shopping List', style: const TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: Text('${items.length} purchased item${items.length == 1 ? '' : 's'}', style: const TextStyle(color: muted, fontSize: 11)),
              children: items.map((raw) {
                final item = Map<String, dynamic>.from(raw);
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline_rounded, color: green, size: 20),
                  title: Text(item['name']?.toString() ?? ''),
                  subtitle: Text('${item['subCategory'] ?? ''} • ${item['quantity'] ?? ''}'),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(color: white, border: Border(top: BorderSide(color: border))),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: white,
        selectedItemColor: green,
        unselectedItemColor: Colors.grey,
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
    );
  }


  Widget _dateArrow(IconData icon, VoidCallback onTap) {
    return IconButton(onPressed: onTap, icon: Icon(icon, color: forest));
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatLongDate(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: green)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}