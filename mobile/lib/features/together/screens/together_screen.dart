import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/screens/global_tasks_screen.dart';

class TogetherScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const TogetherScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

  @override
  State<TogetherScreen> createState() => _TogetherScreenState();
}

class _TogetherScreenState extends State<TogetherScreen> {
  static const String baseUrl = 'http://localhost:8080/api/together';
  static const String serverOrigin = 'http://localhost:8080';
  int _currentNavIndex = 4;
  final List<TextEditingController> _modalControllers = [];

  @override
  void dispose() {
    for (final controller in _modalControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isLoading = true;
  List<dynamic> _memories = [];
  List<dynamic> _comingTogether = [];

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
    _loadTogetherData();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (jwtToken != null && jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
    };
  }

  Future<void> _loadTogetherData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final headers = await _headers();

      final memRes = await http.get(Uri.parse('$baseUrl/memories/${widget.familyId}'), headers: headers);
      final scheduledRes = await http.get(Uri.parse('$baseUrl/activities/${widget.familyId}?scheduled=true'), headers: headers);

      if (mounted) {
        setState(() {
          _memories = memRes.statusCode == 200 ? jsonDecode(memRes.body) : [];
          _comingTogether = scheduledRes.statusCode == 200 ? jsonDecode(scheduledRes.body) : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Together data: $e');
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
            // Header with Green Shadow Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: paleGreen.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: green.withValues(alpha: 0.2), width: 1.5)),
                boxShadow: [
                  BoxShadow(color: green.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
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
                          'Together',
                          style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'The little things make a beautiful life.',
                          style: TextStyle(color: textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // --- COMING TOGETHER SECTION ---
                        const Text(
                          'Coming Together',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark),
                        ),
                        const SizedBox(height: 10),
                        _comingTogether.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                child: const Center(child: Text('No upcoming family plans right now. Choose an adventure below!', style: TextStyle(color: muted, fontSize: 12))),
                              )
                            : Column(
                                children: _comingTogether.map((activity) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: border),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: SizedBox(
                                            width: 64, height: 64,
                                            child: (activity['imageUrl'] ?? '').toString().startsWith('assets/')
                                                ? Image.asset(activity['imageUrl'], fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => _buildPlaceholderImage())
                                                : _buildPlaceholderImage(),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(activity['title'], style: const TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 14)),
                                              const SizedBox(height: 2),
                                              Text('${activity['scheduledDate'] ?? ''} • ${activity['scheduledTime'] ?? ''}', style: const TextStyle(fontSize: 11, color: textSecondary)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                          onPressed: () => _deleteActivity(activity['id']),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 20),

                        // --- OUR LITTLE MOMENTS (SCRAPBOOK) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Our Little Moments',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark),
                            ),
                            TextButton.icon(
                              onPressed: _showAddMemoryModal,
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: green),
                              label: const Text('Add Memory', style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _memories.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                child: const Center(child: Text('Your family scrapbook is empty. Add your first memory!', style: TextStyle(color: muted, fontSize: 12))),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _memories.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                                itemBuilder: (context, index) {
                                  final m = _memories[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: border),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3))],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                            child: m['imageUrl'] != null && m['imageUrl'].toString().isNotEmpty
                                                ? FutureBuilder<Map<String, String>>(
                                                    future: _headers(),
                                                    builder: (context, snapshot) => snapshot.hasData
                                                        ? Image.network(
                                                            _imageUrl(m['imageUrl'].toString()),
                                                            headers: snapshot.data,
                                                            fit: BoxFit.cover,
                                                            width: double.infinity,
                                                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                                                          )
                                                        : _buildPlaceholderImage(),
                                                  )
                                                : _buildPlaceholderImage(),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(m['caption'] ?? 'Family memory', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: textDark)),
                                              const SizedBox(height: 2),
                                              Text(m['memoryDate'] ?? '', style: const TextStyle(fontSize: 10, color: muted)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 20),

                        // --- ADVENTURE FLOWER SECTION (Normal Scrollable) ---
                        _buildScrollableAdventureFlower(),
                        const SizedBox(height: 40),
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

  String _imageUrl(String value) => value.startsWith('/') ? '$serverOrigin$value' : value;

  Widget _buildPlaceholderImage() {
    return Container(
      color: paleGreen,
      child: const Center(child: Icon(Icons.image_rounded, color: green, size: 28)),
    );
  }

  Widget _buildScrollableAdventureFlower() {
    const entries = [
      ('Movie', 'movie.jpg', 'Cozy up, grab some snacks, and enjoy a movie together.'),
      ('Picnic', 'picnic.jpg', 'Sunshine, tasty treats, and beautiful family moments.'),
      ('Trip', 'trip.jpg', 'A little adventure and memories along the way.'),
      ('Other', 'other.jpg', 'Every little idea can become something special.'),
      ('Dinner', 'dinner.jpg', 'Good food, warm conversations, and time together.'),
      ('Bake', 'bake.jpg', 'A little mixing, a little mess, and lots of love.'),
      ('Games', 'game.jpg', 'Play, laugh, and enjoy a little friendly competition.'), 
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('What shall we do together?',
              style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          const Text('Choose a little adventure', style: TextStyle(color: textSecondary, fontSize: 11)),
          const SizedBox(height: 14),
          SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < entries.length; i++)
                  Positioned(
                    left: 160 + 115 * _cosForPetal(i) - 34,
                    top: 160 + 115 * _sinForPetal(i) - 34,
                    child: _buildFlowerPetal(
                      entries[i].$1,
                      'assets/images/together/adventure/${entries[i].$2}',
                      entries[i].$3,
                      68,
                    ),
                  ),
                Positioned(
                  child: InkWell(
                    onTap: _showFlowerChooserModal,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: forest,
                        border: Border.all(color: white, width: 3.5),
                        boxShadow: [BoxShadow(color: forest.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Let's plan", style: TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w800)),
                          Text('something', style: TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Icon(Icons.favorite_rounded, color: Color(0xFFF4B8AA), size: 19),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _cosForPetal(int i) => _petalCos[i];
  double _sinForPetal(int i) => _petalSin[i];
  static const _petalCos = [0.0, 0.781831, 0.974928, 0.433884, -0.433884, -0.974928, -0.781831];
  static const _petalSin = [-1.0, -0.62349, 0.222521, 0.900969, 0.900969, 0.222521, -0.62349];

  Widget _buildFlowerPetal(String title, String assetPath, String subtitle, double size) {
    return Tooltip(
      message: title,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _showPlanActivityModal(title, subtitle, assetPath),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: white, width: 3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 7, offset: const Offset(0, 2))],
          ),
          child: ClipOval(
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: paleGreen,
                alignment: Alignment.center,
                child: Text(title, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: forest, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPlanActivityModal(String category, String description, String adventureAsset) async {
    final titleController = TextEditingController(text: category == 'Other' ? '' : category);
    _modalControllers.add(titleController);

    final placeController = TextEditingController();
    _modalControllers.add(placeController);

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 16, minute: 0);

    bool saving = false;
    bool didClose = false;

    final eventAsset = adventureAsset.replaceFirst('/adventure/', '/event/');

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 18, 22, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(8)))),
              const SizedBox(height: 20),
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(eventAsset,
                  width: 100, height: 100, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 100, height: 100, color: paleGreen,
                    alignment: Alignment.center, child: const Text('Event image', style: TextStyle(color: forest))))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(category == 'Other' ? 'Our next adventure' : 'A little ${category.toLowerCase()} ${category == 'Picnic' ? '🧺' : '♡'}',
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: textDark)),
                  const SizedBox(height: 6),
                  Text(description, style: const TextStyle(fontSize: 13, color: textSecondary)),
                ])),
              ]),
              const SizedBox(height: 22), const Divider(color: border), const SizedBox(height: 12),
              const Text('Activity', style: TextStyle(fontWeight: FontWeight.w700, color: textDark)),
              const SizedBox(height: 7),
              TextField(controller: titleController, decoration: _inputDecoration('Activity', hint: 'What shall we do?')),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  onPressed: () async {
                    final picked = await showDatePicker(context: sheetContext, initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime(2100));
                    if (picked != null) update(() => selectedDate = picked);
                  },
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule_outlined, size: 18),
                  label: Text(selectedTime.format(sheetContext)),
                  onPressed: () async {
                    final picked = await showTimePicker(context: sheetContext, initialTime: selectedTime);
                    if (picked != null) update(() => selectedTime = picked);
                  },
                )),
              ]),
              const SizedBox(height: 14),
              const Text('Where? (optional)', style: TextStyle(fontWeight: FontWeight.w700, color: textDark)),
              const SizedBox(height: 7),
              TextField(controller: placeController, decoration: _inputDecoration('Place', hint: 'Beach, garden, park...')),
              const SizedBox(height: 22),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                onPressed: saving ? null : () async {
                  if (titleController.text.trim().isEmpty) { _showMessage('Enter an activity name.'); return; }
                  update(() => saving = true);
                  try {
                    final date = '${selectedDate.year.toString().padLeft(4,'0')}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}';
                    final time = '${selectedTime.hour.toString().padLeft(2,'0')}:${selectedTime.minute.toString().padLeft(2,'0')}:00';
                    final response = await http.post(Uri.parse('$baseUrl/activities/${widget.familyId}'),
                      headers: await _headers(), body: jsonEncode({
                        'title': titleController.text.trim(), 'description': placeController.text.trim().isEmpty ? description : placeController.text.trim(),
                        'imageUrl': eventAsset, 'scheduled': true, 'scheduledDate': date, 'scheduledTime': time,
                      }));
                    if (response.statusCode != 200 && response.statusCode != 201) throw Exception('HTTP ${response.statusCode}: ${response.body}');

                    if (sheetContext.mounted) { didClose = true; Navigator.pop(sheetContext); }
                    await _loadTogetherData();
                    _showMessage('Added to Coming Together!');
                  } catch (e) {
                    _showMessage('Could not save event: $e');
                  } finally { if (!didClose && sheetContext.mounted) update(() => saving = false); }
                },
                child: Text(saving ? 'Saving...' : 'Plan this together', style: const TextStyle(fontWeight: FontWeight.w800)),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  void _showFlowerChooserModal() {
    _showPlanActivityModal('Other', 'Custom family adventure', 'assets/images/together/adventure/other.jpg');
  }

  Future<void> _showAddMemoryModal() async {
    final captionController = TextEditingController();
    _modalControllers.add(captionController);

    final urlController = TextEditingController();
    _modalControllers.add(urlController);

    XFile? selectedPhoto;

    bool saving = false;
    bool didClose = false;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, update) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, 20, 22, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Capture a Little Moment', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 6),
            const Text('A photo, a few words, a memory for everyone at home.', style: TextStyle(color: textSecondary)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(selectedPhoto == null ? 'Choose from phone gallery' : 'Photo selected: ${selectedPhoto!.name}'),
              onPressed: () async {
                try {
                  final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1800);
                  if (image != null) update(() => selectedPhoto = image);
                } catch (e) { _showMessage('Could not open gallery: $e'); }
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: urlController, keyboardType: TextInputType.url,
              decoration: _inputDecoration('Or use a photo URL', hint: 'https://example.com/photo.jpg')),
            const SizedBox(height: 14),
            TextField(controller: captionController, maxLines: 3,
              decoration: _inputDecoration('Our memory', hint: 'What made this moment special?')),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: white),
              onPressed: saving ? null : () async {
                final caption = captionController.text.trim();
                if (caption.isEmpty && selectedPhoto == null && urlController.text.trim().isEmpty) {
                  _showMessage('Add a photo or a memory note.'); return;
                }
                final url = urlController.text.trim();
                if (selectedPhoto == null && url.isNotEmpty && !(Uri.tryParse(url)?.hasScheme == true && (url.startsWith('https://') || url.startsWith('http://')))) {
                  _showMessage('Please enter a valid http or https photo URL.'); return;
                }
                update(() => saving = true);
                try {
                  String imageUrl = url;
                  if (selectedPhoto != null) {
                    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/memories/${widget.familyId}/photo'));
                    request.headers.addAll(await _headers()..remove('Content-Type'));
                    
                    final bytes = await selectedPhoto!.readAsBytes();
                    request.files.add(http.MultipartFile.fromBytes(
                      'file',
                      bytes,
                      filename: selectedPhoto!.name.isNotEmpty ? selectedPhoto!.name : 'memory.jpg',
                    ));

                    final streamedResponse = await request.send();
                    final upload = await http.Response.fromStream(streamedResponse);
                    if (upload.statusCode != 200 && upload.statusCode != 201) {
                      throw Exception('Photo upload failed (${upload.statusCode}): ${upload.body}');
                    }
                    imageUrl = jsonDecode(upload.body)['imageUrl'] as String;
                  }
                  final response = await http.post(Uri.parse('$baseUrl/memories/${widget.familyId}'),
                    headers: await _headers(), body: jsonEncode({'caption': caption, 'imageUrl': imageUrl}));
                  if (response.statusCode != 200 && response.statusCode != 201) throw Exception('Save failed (${response.statusCode}): ${response.body}');

                  if (sheetContext.mounted) { didClose = true; Navigator.pop(sheetContext); }
                  await _loadTogetherData();
                  _showMessage('Memory added to your family scrapbook!');
                } catch (e) { _showMessage('Could not save memory: $e'); }
                finally { if (!didClose && sheetContext.mounted) update(() => saving = false); }
              },
              child: Text(saving ? 'Saving memory...' : 'Save family memory'),
            )),
          ]),
        ),
      )),
    );
  }

  Future<void> _deleteActivity(dynamic id) async {
    try {
      final headers = await _headers();
      await http.delete(Uri.parse('$baseUrl/activities/${widget.familyId}/$id'), headers: headers);
      _loadTogetherData();
    } catch (_) {}
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