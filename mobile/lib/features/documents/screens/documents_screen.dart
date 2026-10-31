import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../tasks/screens/global_tasks_screen.dart';
import '../../family/models/family_profile.dart';
import '../../family/services/family_service.dart';
import '../services/family_document_api.dart';

class DocumentsScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;
  final List<FamilyProfile> familyMembers;

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
  static const categories = ['Personal', 'Education', 'Financial', 'Property', 'Vehicle', 'Insurance', 'Other'];

  static const Color ivory = Color(0xFFFAF8F3);
  static const Color white = Colors.white;
  static const Color forest = Color(0xFF355C4A);
  static const Color green = Color(0xFF4A8B71);
  static const Color paleGreen = Color(0xFFE5EEE7);
  static const Color textDark = Color(0xFF244032);
  static const Color textSecondary = Color(0xFF65716B);
  static const Color muted = Color(0xFF98A19C);
  static const Color border = Color(0xFFE5E1D9);
  static const Color terracotta = Color(0xFFC98268);

  final TextEditingController _searchController = TextEditingController();
  final FamilyDocumentApi _api = FamilyDocumentApi();
  final FamilyService _familyApi = FamilyService();

  bool _isLoading = true;
  String? _errorMessage;
  int _currentNavIndex = 4;

  List<Map<String, dynamic>> _documents = [];
  List<FamilyProfile> _profiles = [];
  String? _selectedCategory;
  String? _selectedMemberProfileId; // null means 'All members'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _api.close();
    _familyApi.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await Future.wait([
        _api.list(widget.familyId),
        _familyApi.getFamilyProfiles(widget.familyId),
      ]);

      if (mounted) {
        setState(() {
          _documents = List<Map<String, dynamic>>.from(
            (data[0] as List).map((item) => Map<String, dynamic>.from(item as Map)),
          );
          _profiles = List<FamilyProfile>.from(data[1] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
        });
      }
    }
  }

  List<Map<String, dynamic>> get _visibleDocuments {
    final query = _searchController.text.trim().toLowerCase();
    return _documents.where((d) {
      final categoryMatch = _selectedCategory == null || d['category'] == _selectedCategory;

      bool memberMatch = true;
      if (_selectedMemberProfileId != null) {
        final docProfileId = d['familyProfileId']?.toString();
        memberMatch = docProfileId == _selectedMemberProfileId;
      }

      final textMatch = query.isEmpty ||
          [d['title'], d['fileName'], d['familyProfileName']]
              .whereType<String>()
              .any((v) => v.toLowerCase().contains(query));

      return categoryMatch && memberMatch && textMatch;
    }).toList();
  }

  int get _expiringSoonCount {
    final now = DateTime.now();
    return _documents.where((d) {
      final expiryStr = d['expiryDate']?.toString();
      if (expiryStr == null || expiryStr.isEmpty) return false;
      try {
        final expiryDate = DateTime.parse(expiryStr);
        final difference = expiryDate.difference(now).inDays;
        return difference >= 0 && difference <= 30;
      } catch (_) {
        return false;
      }
    }).length;
  }

  String _getFriendlyName(FamilyProfile profile) {
    final name = profile.name.trim();
    if (name.isNotEmpty && name.toLowerCase() != 'null') return name;
    return profile.relationship.isNotEmpty ? profile.relationship : 'Member';
  }

  String _getFriendlyRole(FamilyProfile profile) {
    final role = profile.relationship.trim();
    if (role.isNotEmpty && role.toLowerCase() != 'null') {
      return role[0].toUpperCase() + role.substring(1);
    }
    return 'Member';
  }

  String? _getAvatarUrl(FamilyProfile profile) {
    final role = profile.relationship.toLowerCase().trim();
    final gender = profile.gender?.toLowerCase().trim();

    if (role.contains('grandfather') || role.contains('grandpa')) {
      return 'assets/images/family_members/grandfather.jpg';
    }
    if (role.contains('grandmother') || role.contains('grandma')) {
      return 'assets/images/family_members/grandmother.jpg';
    }
    if (role.contains('father') || role.contains('dad')) {
      return 'assets/images/family_members/father.jpg';
    }
    if (role.contains('mother') || role.contains('mom')) {
      return 'assets/images/family_members/mother.jpg';
    }
    if (role.contains('son') || role.contains('boy')) {
      return 'assets/images/family_members/son.jpg';
    }
    if (role.contains('daughter') || role.contains('girl')) {
      return 'assets/images/family_members/daughter.jpg';
    }
    if (gender == 'female') {
      return 'assets/images/family_members/female.jpg';
    }
    return 'assets/images/family_members/male.jpg';
  }

  Widget _buildAvatar(FamilyProfile profile, {double radius = 28}) {
    final path = _getAvatarUrl(profile);
    if (path != null && path.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: paleGreen,
        backgroundImage: AssetImage(path),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: paleGreen,
      child: Text(
        _getInitials(_getFriendlyName(profile)),
        style: TextStyle(fontSize: radius * 0.52, fontWeight: FontWeight.w800, color: forest),
      ),
    );
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final activeProfiles = _profiles.isNotEmpty ? _profiles : widget.familyMembers;

    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
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

            // --- HORIZONTAL MEMBER SELECTOR (Like HealthScreen) ---
            if (activeProfiles.isNotEmpty)
              Container(
                height: 110,
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activeProfiles.length + 1, // +1 for "All" option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final selected = _selectedMemberProfileId == null;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMemberProfileId = null),
                        child: SizedBox(
                          width: 80,
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: selected ? green : Colors.transparent, width: 2.5),
                                    ),
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: forest,
                                      child: const Icon(Icons.folder_shared_rounded, color: white, size: 24),
                                    ),
                                  ),
                                  if (selected)
                                    Positioned(
                                      right: -1,
                                      bottom: -1,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(color: green, shape: BoxShape.circle),
                                        child: const Icon(Icons.check_rounded, size: 12, color: white),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All Files',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected ? textDark : textSecondary,
                                  fontSize: 11,
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final profile = activeProfiles[index - 1];
                    final selected = _selectedMemberProfileId == profile.id;
                    final name = _getFriendlyName(profile);
                    final relationship = _getFriendlyRole(profile);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedMemberProfileId = selected ? null : profile.id),
                      child: SizedBox(
                        width: 80,
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: selected ? green : Colors.transparent, width: 2.5),
                                  ),
                                  child: _buildAvatar(profile, radius: 26),
                                ),
                                if (selected)
                                  Positioned(
                                    right: -1,
                                    bottom: -1,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(color: green, shape: BoxShape.circle),
                                      child: const Icon(Icons.check_rounded, size: 12, color: white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? textDark : textSecondary,
                                fontSize: 11,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              relationship,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: muted, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          color: green,
                          onRefresh: _loadData,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // --- SPACE OVERVIEW BANNER ---
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: paleGreen.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Your family's document space", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                                        const Icon(Icons.lock_outline_rounded, size: 16, color: forest),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: const [
                                        Text('All in one place', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                                        SizedBox(width: 6),
                                        Text('💚', style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${_documents.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textDark)),
                                                const SizedBox(height: 2),
                                                const Text('Documents', style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('$_expiringSoonCount', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _expiringSoonCount > 0 ? terracotta : textDark)),
                                                const SizedBox(height: 2),
                                                const Text('Expiring soon', style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // --- SEARCH BAR ---
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search your family documents...',
                                  hintStyle: const TextStyle(color: muted, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search_rounded, color: green),
                                  filled: true,
                                  fillColor: white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: green)),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // --- CATEGORY CHIPS ---
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildCategoryChip(null, 'All Categories'),
                                    ...categories.map((c) => _buildCategoryChip(c, c)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // --- DOCUMENTS LIST TITLE ---
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_selectedCategory != null ? '$_selectedCategory Documents' : 'Documents', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
                                  Text('${_visibleDocuments.length} shown', style: const TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // --- DOCUMENTS CARDS ---
                              _visibleDocuments.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(28),
                                      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                      child: const Center(
                                        child: Text('No documents found for this selection.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
                                      ),
                                    )
                                  : Column(
                                      children: _visibleDocuments.map(_buildDocumentCard).toList(),
                                    ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCategoryChip(String? value, String text) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        selectedColor: paleGreen,
        backgroundColor: white,
        labelStyle: TextStyle(color: selected ? textDark : textSecondary, fontWeight: FontWeight.w700, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: selected ? green : border)),
        onSelected: (_) => setState(() => _selectedCategory = value),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final type = doc['fileType']?.toString() ?? '';
    final size = (doc['fileSize'] as num?)?.toInt() ?? 0;
    final assigned = doc['familyProfileName']?.toString() ?? doc['belongsTo']?.toString() ?? 'Shared family';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: paleGreen, borderRadius: BorderRadius.circular(12)),
            child: Icon(
              type == 'application/pdf' ? Icons.picture_as_pdf_rounded : type.startsWith('image/') ? Icons.image_rounded : Icons.description_rounded,
              color: forest,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['title']?.toString() ?? 'Untitled document', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 14)),
                const SizedBox(height: 2),
                Text(doc['fileName']?.toString() ?? 'Legacy document', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _tag(doc['category']?.toString() ?? 'Other'),
                    _tag(assigned),
                    _tag('${_typeLabel(type)} • ${_formatSize(size)}'),
                  ],
                ),
                if (doc['expiryDate'] != null && doc['expiryDate'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Expires: ${doc['expiryDate']}', style: const TextStyle(fontSize: 10, color: terracotta, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: muted, size: 20),
            onSelected: (val) {
              if (val == 'download') _downloadDocument(doc);
              if (val == 'delete') _deleteDocument(doc);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'download', child: Text('Open / download', style: TextStyle(fontSize: 12))),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: ivory, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
      child: Text(value, style: const TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  String _typeLabel(String v) => v == 'application/pdf' ? 'PDF' : v == 'image/png' ? 'PNG' : v == 'image/jpeg' ? 'JPG' : v.contains('wordprocessingml') ? 'DOCX' : 'File';
  String _formatSize(int v) => v < 1024 * 1024 ? '${(v / 1024).toStringAsFixed(0)} KB' : '${(v / (1024 * 1024)).toStringAsFixed(1)} MB';

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: textSecondary)),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: forest),
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _downloadDocument(Map<String, dynamic> doc) async {
    try {
      final bytes = await _api.download(doc['id'].toString());
      final fileName = doc['fileName']?.toString() ?? 'document';
      final picker = (FilePicker as dynamic).platform;
      if (picker == null) {
        _showMessage('Direct download not supported on this platform.');
        return;
      }
      await picker.saveFile(fileName: fileName, bytes: bytes);
      _showMessage('Document download is ready.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''));
    }
  }

  Future<void> _deleteDocument(Map<String, dynamic> doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Are you sure you want to delete "${doc['title'] ?? 'this document'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.delete(doc['id'].toString());
      await _loadData();
      _showMessage('Document deleted.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''));
    }
  }


  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Widget _buildBottomNavigation() {
    return Container(
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
          } else if (index == 4) {
            Navigator.maybePop(context);
          }
        },
      ),
    );
  }
}