import 'package:mobile/core/services/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile/core/services/authenticated_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DocumentsScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;
  final List<Map<String, dynamic>> familyMembers;

  const DocumentsScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
    required this.familyMembers,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static final String baseUrl = '${ApiConfig.baseUrl}/documents';
  final List<TextEditingController> _modalControllers = [];

  bool _isLoading = true;
  List<dynamic> _documents = [];
  List<dynamic> _profiles = [];
  String _searchQuery = '';
  String? _selectedCategoryFilter;

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
    _loadDocuments();
  }

  @override
  void dispose() {
    for (final c in _modalControllers) {
      c.dispose();
    }
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

  Future<void> _loadDocuments() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final headers = await _headers();
      final docRes = await http.get(Uri.parse('$baseUrl/${widget.familyId}'), headers: headers);
      final profRes = await http.get(Uri.parse('$baseUrl/../families/${widget.familyId}/profiles'), headers: headers);

      if (mounted) {
        setState(() {
          _documents = docRes.statusCode == 200 ? jsonDecode(docRes.body) : [];
          _profiles = profRes.statusCode == 200 ? jsonDecode(profRes.body) : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading documents/profiles: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredDocuments {
    var list = _documents;
    if (_selectedCategoryFilter != null) {
      list = list.where((d) => d['category'] == _selectedCategoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((d) {
        final title = (d['title'] ?? '').toString().toLowerCase();
        final category = (d['category'] ?? '').toString().toLowerCase();
        final belongsTo = (d['belongsTo'] ?? '').toString().toLowerCase();
        return title.contains(query) || category.contains(query) || belongsTo.contains(query);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: paleGreen.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: green.withValues(alpha: 0.2), width: 1.5)),
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
                        Text('Family Documents', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Everything important, in one safe place.', style: TextStyle(color: textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search family documents...',
                            prefixIcon: const Icon(Icons.search_rounded, color: green),
                            filled: true,
                            fillColor: white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Documents', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
                        const SizedBox(height: 10),
                        _filteredDocuments.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                child: const Center(child: Text('No documents found.', style: TextStyle(color: muted))),
                              )
                            : Column(
                                children: _filteredDocuments.map((doc) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.description_rounded, color: green, size: 22),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(doc['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w800, color: textDark)),
                                              Text('${doc['category']} • ${doc['belongsTo'] ?? 'Family'}', style: const TextStyle(fontSize: 11, color: textSecondary)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: ivory, border: Border(top: BorderSide(color: border))),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _showAddDocumentModal,
              style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Add New Document', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDocumentModal() async {
    final titleController = TextEditingController();
    _modalControllers.add(titleController);

    String selectedCategory = 'Personal & IDs';
    
    final memberLabels = _profiles.map((p) {
      final name = p['name']?.toString() ?? '';
      final role = p['role']?.toString() ?? '';
      return name.isNotEmpty ? '$name ($role)' : role;
    }).toList();

    if (memberLabels.isEmpty) memberLabels.add('Family');

    String selectedBelongsTo = memberLabels.first;
    bool saving = false;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 20, 22, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add a Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark)),
                const SizedBox(height: 16),
                const Text('Document Name', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(controller: titleController, decoration: _inputDecoration('e.g. Birth certificate')),
                const SizedBox(height: 12),
                const Text('Belongs to (Member / Child)', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedBelongsTo,
                  dropdownColor: white,
                  decoration: _inputDecoration('Select family member'),
                  items: memberLabels.map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                  onChanged: (val) {
                    if (val != null) update(() => selectedBelongsTo = val);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: saving ? null : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      update(() => saving = true);
                      try {
                        final body = {
                          'title': title,
                          'category': selectedCategory,
                          'belongsTo': selectedBelongsTo,
                        };

                        final saveRes = await http.post(
                          Uri.parse('$baseUrl/${widget.familyId}'),
                          headers: await _headers(),
                          body: jsonEncode(body),
                        );

                        if (saveRes.statusCode == 200 || saveRes.statusCode == 201) {
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          _loadDocuments();
                          _showMessage('Document saved successfully!');
                        }
                      } catch (e) {
                        _showMessage('Error saving document: $e');
                      } finally {
                        if (sheetContext.mounted) update(() => saving = false);
                      }
                    },
                    child: Text(saving ? 'Saving...' : 'Save Document', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
    );
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}