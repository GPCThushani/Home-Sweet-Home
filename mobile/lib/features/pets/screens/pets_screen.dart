import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../tasks/screens/global_tasks_screen.dart';
import '../../../core/services/auth_session.dart';
import '../services/pet_api.dart';
import 'vaccinations_screen.dart';
import 'pet_health_screen.dart';
import 'care_schedules_screen.dart';
import 'daily_care_screen.dart';
import 'vet_visits_screen.dart';
import 'pet_documents_screen.dart';

String petAge(String? dateOfBirth) {
  final birth = DateTime.tryParse(dateOfBirth ?? '');
  if (birth == null) return 'Age not recorded';
  final now = DateTime.now();
  if (birth.isAfter(now)) return 'Age not recorded';
  var months = (now.year - birth.year) * 12 + now.month - birth.month;
  if (now.day < birth.day) months--;
  final years = months ~/ 12;
  final remaining = months % 12;
  if (years == 0) {
    return remaining == 1 ? '1 month old' : '$remaining months old';
  }
  if (remaining == 0) return years == 1 ? '1 year old' : '$years years old';
  return '${years == 1 ? '1 year' : '$years years'}, ${remaining == 1 ? '1 month' : '$remaining months'} old';
}

class PetPhotoImage extends StatefulWidget {
  final String? petId;
  final String? photoUrl;
  final String fallbackAsset;
  const PetPhotoImage({
    super.key,
    required this.petId,
    required this.photoUrl,
    required this.fallbackAsset,
  });
  @override
  State<PetPhotoImage> createState() => _PetPhotoImageState();
}

class _PetPhotoImageState extends State<PetPhotoImage> {
  final PetApi _api = PetApi();
  Future<Uint8List>? _photo;
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(PetPhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.petId != widget.petId ||
        oldWidget.photoUrl != widget.photoUrl) {
      _prepare();
    }
  }

  void _prepare() {
    _photo =
        widget.petId != null &&
            widget.photoUrl == '/api/pets/${widget.petId}/photo'
        ? _api.photo(widget.petId!)
        : null;
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(widget.fallbackAsset, fit: BoxFit.cover);
    if (widget.photoUrl?.startsWith('assets/') == true) {
      return Image.asset(
        widget.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (_photo != null) {
      return FutureBuilder<Uint8List>(
        future: _photo,
        builder: (_, snapshot) => snapshot.hasData
            ? Image.memory(snapshot.data!, fit: BoxFit.cover)
            : fallback,
      );
    }
    if (widget.photoUrl?.startsWith('https://') == true) {
      return Image.network(
        widget.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
  }
}

class PetsScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;

  const PetsScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
  });

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  final PetApi _api = PetApi();

  static const Color ivory = Color(0xFFFAF8F3);
  static const Color white = Colors.white;
  static const Color forest = Color(0xFF355C4A);
  static const Color green = Color(0xFF4A8B71);
  static const Color paleGreen = Color(0xFFE5EEE7);
  static const Color textDark = Color(0xFF244032);
  static const Color textSecondary = Color(0xFF65716B);
  static const Color muted = Color(0xFF98A19C);
  static const Color border = Color(0xFFE5E1D9);

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _pets = [];
  int _currentNavIndex = 4;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _loadPets() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pets = await _api.list(widget.familyId);
      if (mounted) {
        setState(() {
          _pets = pets;
          _isLoading = false;
        });
      }
    } on AuthenticationException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Your session has expired. Please sign in again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getPlaceholderAsset(String type) {
    final t = type.toLowerCase();
    if (t.contains('cat')) return 'assets/images/pets/cat.jpg';
    if (t.contains('bird') || t.contains('parrot')) {
      return 'assets/images/pets/parrot.jpg';
    }
    if (t.contains('rabbit')) return 'assets/images/pets/rabbit.jpg';
    if (t.contains('fish')) return 'assets/images/pets/fish.jpg';
    if (t.contains('guinea') || t.contains('guinea pigs')) {
      return 'assets/images/pets/guineapig.jpg';
    }
    if (t.contains('turtle')) return 'assets/images/pets/turtle.jpg';
    if (t.contains('other')) return 'assets/images/pets/other.jpg';
    return 'assets/images/pets/dog.jpg';
  }

  @override
  Widget build(BuildContext context) {
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
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: green.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textDark,
                      size: 20,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Pets',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Your family's furry companions",
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTENT AREA ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _pets.isEmpty
                  ? _buildEmptyWelcomeState()
                  : RefreshIndicator(
                      color: green,
                      backgroundColor: white,
                      onRefresh: _loadPets,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text(
                            'My Pets',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Your family's furry companions",
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._pets.map(_buildPetCard),
                          const SizedBox(height: 16),
                          _buildAddPetCardButton(),
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

  // --- EMPTY WELCOME STATE WITH IMAGE BANNER ---
  Widget _buildEmptyWelcomeState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: forest.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/pets/pets.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: paleGreen,
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 64,
                        color: forest,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Add your pet to start',
              style: TextStyle(
                color: textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create profiles for your dogs, cats, or other furry family members to track their health, schedules, and care routines.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showAddPetModal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: forest,
                  foregroundColor: white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Add New Pet',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final name = pet['name']?.toString() ?? 'Pet';
    final type = pet['type']?.toString() ?? 'Dog';
    final breed = pet['breed']?.toString() ?? 'Mixed breed';
    final dob = pet['dateOfBirth']?.toString();
    final age = petAge(dob);
    final photoUrl = pet['photoUrl']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PetDetailScreen(
                  userEmail: widget.userEmail,
                  familyId: widget.familyId,
                  pet: pet,
                ),
              ),
            );
            _loadPets();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: PetPhotoImage(
                      petId: pet['id']?.toString(),
                      photoUrl: photoUrl,
                      fallbackAsset: _getPlaceholderAsset(type),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$type · $breed',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        age,
                        style: const TextStyle(
                          color: green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPetCardButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: InkWell(
        onTap: () => _showAddPetModal(),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: paleGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: forest, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Pet',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Create a profile for another family pet',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPetModal({Map<String, dynamic>? existingPet}) async {
    final isEditing = existingPet != null;
    final nameController = TextEditingController(
      text: existingPet?['name']?.toString() ?? '',
    );
    final breedController = TextEditingController(
      text: existingPet?['breed']?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: existingPet?['weightKg']?.toString() ?? '',
    );
    final colorController = TextEditingController(
      text: existingPet?['color']?.toString() ?? '',
    );
    final microchipController = TextEditingController(
      text: existingPet?['microchipId']?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: existingPet?['specialNotes']?.toString() ?? '',
    );
    final dobController = TextEditingController(
      text: existingPet?['dateOfBirth']?.toString() ?? '',
    );

    final initialType = existingPet?['type']?.toString() ?? 'Dog';
    final isStandardType = [
      'Dog',
      'Cat',
      'Bird',
      'Fish',
      'Rabbit',
      'Parrot',
      'Guinea Pigs',
      'Turtle',
    ].contains(initialType);

    String selectedType = isStandardType ? initialType : 'Other';
    final customTypeController = TextEditingController(
      text: isStandardType ? '' : initialType,
    );
    String selectedGender = existingPet?['gender']?.toString() ?? 'Male';
    String? selectedPhotoAsset =
        existingPet?['photoUrl']?.toString() ?? 'assets/images/pets/dog.jpg';
    PlatformFile? uploadedImage;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              20,
              22,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Pet Details' : 'Add Pet Details',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // --- PHOTO PICKER & LIBRARY SELECTOR ---
                Center(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          final picked = await FilePicker.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (picked != null &&
                              picked.files.single.bytes != null) {
                            final image = picked.files.single;
                            final extension = image.extension?.toLowerCase();
                            if (image.size == 0 ||
                                image.size > 5 * 1024 * 1024 ||
                                !['jpg', 'jpeg', 'png'].contains(extension)) {
                              _showMessage(
                                'Choose a JPG or PNG photo under 5 MB.',
                              );
                              return;
                            }
                            setModalState(() {
                              uploadedImage = image;
                              selectedPhotoAsset = null;
                            });
                          }
                        },
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: paleGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: border, width: 2),
                          ),
                          child: uploadedImage != null
                              ? ClipOval(
                                  child: Image.memory(
                                    uploadedImage!.bytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : selectedPhotoAsset != null &&
                                    selectedPhotoAsset!.startsWith('assets/')
                              ? ClipOval(
                                  child: Image.asset(
                                    selectedPhotoAsset!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      color: forest,
                                      size: 24,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        color: forest,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose library preset or upload file',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          children:
                              [
                                'assets/images/pets/dog.jpg',
                                'assets/images/pets/cat.jpg',
                                'assets/images/pets/rabbit.jpg',
                                'assets/images/pets/parrot.jpg',
                                'assets/images/pets/fish.jpg',
                                'assets/images/pets/guineapig.jpg',
                                'assets/images/pets/turtle.jpg',
                                'assets/images/pets/other.jpg',
                              ].map((assetPath) {
                                final isChosen =
                                    selectedPhotoAsset == assetPath;
                                return GestureDetector(
                                  onTap: () => setModalState(() {
                                    selectedPhotoAsset = assetPath;
                                    uploadedImage = null;
                                  }),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.all(isChosen ? 2 : 0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isChosen
                                            ? green
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundImage: AssetImage(assetPath),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Pet Name *',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: _inputDecoration('e.g. Buddy, Luna'),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pet Type',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            dropdownColor: white,
                            decoration: _inputDecoration('Type'),
                            items:
                                [
                                      'Dog',
                                      'Cat',
                                      'Bird',
                                      'Fish',
                                      'Rabbit',
                                      'Parrot',
                                      'Guinea Pigs',
                                      'Turtle',
                                      'Other',
                                    ]
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          t,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedType = val;
                                  if (uploadedImage == null && val != 'Other') {
                                    selectedPhotoAsset = _getPlaceholderAsset(
                                      val,
                                    );
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gender',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedGender,
                            dropdownColor: white,
                            decoration: _inputDecoration('Gender'),
                            items: ['Male', 'Female', 'Unknown']
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      g,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedGender = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (selectedType == 'Other') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Specify Pet Type *',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: customTypeController,
                    decoration: _inputDecoration('e.g. Hamster, Ferret'),
                  ),
                ],
                const SizedBox(height: 12),

                const Text(
                  'Breed',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: breedController,
                  decoration: _inputDecoration(
                    'e.g. Golden Retriever, Persian',
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: dobController,
                            readOnly: true,
                            decoration: _inputDecoration('YYYY-MM-DD').copyWith(
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: muted,
                              ),
                            ),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) {
                                dobController.text =
                                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weight (kg)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration('e.g. 14.5'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Color (Optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: colorController,
                            decoration: _inputDecoration('e.g. Golden / White'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Microchip ID (Opt.)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: microchipController,
                            decoration: _inputDecoration('Optional ID'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text(
                  'Special Notes / Allergies',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: _inputDecoration(
                    'Allergies or care instructions',
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: forest,
                      foregroundColor: white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              _showMessage('Please enter a pet name.');
                              return;
                            }
                            final finalType =
                                selectedType == 'Other' &&
                                    customTypeController.text.trim().isNotEmpty
                                ? customTypeController.text.trim()
                                : selectedType;
                            if (selectedType == 'Other' &&
                                customTypeController.text.trim().isEmpty) {
                              _showMessage('Specify the pet type.');
                              return;
                            }
                            final weightText = weightController.text.trim();
                            final weight = weightText.isEmpty
                                ? null
                                : double.tryParse(weightText);
                            if (weightText.isNotEmpty &&
                                (weight == null ||
                                    weight <= 0 ||
                                    !weight.isFinite)) {
                              _showMessage('Enter a positive weight.');
                              return;
                            }
                            if (uploadedImage != null &&
                                (uploadedImage!.bytes == null ||
                                    uploadedImage!.size > 5 * 1024 * 1024)) {
                              _showMessage('Choose a photo under 5 MB.');
                              return;
                            }

                            setModalState(() => saving = true);
                            try {
                              final body = {
                                'name': name,
                                'type': finalType,
                                'breed': breedController.text.trim().isNotEmpty
                                    ? breedController.text.trim()
                                    : 'Mixed',
                                'gender': selectedGender,
                                'dateOfBirth':
                                    dobController.text.trim().isNotEmpty
                                    ? dobController.text.trim()
                                    : null,
                                'weightKg': weight,
                                'color': colorController.text.trim().isNotEmpty
                                    ? colorController.text.trim()
                                    : null,
                                'microchipId':
                                    microchipController.text.trim().isNotEmpty
                                    ? microchipController.text.trim()
                                    : null,
                                'specialNotes':
                                    notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : null,
                                'photoUrl': selectedPhotoAsset,
                              };

                              final saved = await _api.save(
                                widget.familyId,
                                body,
                                petId: isEditing
                                    ? existingPet['id']?.toString()
                                    : null,
                              );
                              if (uploadedImage != null) {
                                await _api.uploadPhoto(
                                  saved['id'].toString(),
                                  uploadedImage!.bytes!,
                                  uploadedImage!.name,
                                );
                              }
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                              await _loadPets();
                              _showMessage(
                                isEditing
                                    ? 'Pet profile updated successfully!'
                                    : 'Pet registered successfully!',
                              );
                            } catch (e) {
                              _showMessage('Error: $e');
                            } finally {
                              if (sheetContext.mounted) {
                                setModalState(() => saving = false);
                              }
                            }
                          },
                    child: Text(
                      saving ? 'Saving...' : 'Save Pet Profile',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
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
      hintStyle: const TextStyle(color: muted, fontSize: 12),
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green),
      ),
    );
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Could not load pets. Please check connection.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPets,
              style: ElevatedButton.styleFrom(
                backgroundColor: forest,
                foregroundColor: white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: white,
        border: Border(top: BorderSide(color: border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: white,
        selectedItemColor: green,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group_rounded),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_outlined),
            activeIcon: Icon(Icons.menu_rounded),
            label: 'More',
          ),
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

// --- PET DETAIL PROFILE SCREEN (6 Core Sections, Standard Theme & Bottom Nav) ---
class PetDetailScreen extends StatefulWidget {
  final String userEmail;
  final String familyId;
  final Map<String, dynamic> pet;

  const PetDetailScreen({
    super.key,
    required this.userEmail,
    required this.familyId,
    required this.pet,
  });

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late Map<String, dynamic> _pet;
  final PetApi _api = PetApi();
  int _currentNavIndex = 4;

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
    _pet = widget.pet;
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  String _getPlaceholderAsset(String type) {
    final t = type.toLowerCase();
    if (t.contains('cat')) return 'assets/images/pets/cat.jpg';
    if (t.contains('bird') || t.contains('parrot')) {
      return 'assets/images/pets/parrot.jpg';
    }
    if (t.contains('rabbit')) return 'assets/images/pets/rabbit.jpg';
    if (t.contains('fish')) return 'assets/images/pets/fish.jpg';
    if (t.contains('guinea')) return 'assets/images/pets/guineapig.jpg';
    if (t.contains('turtle')) return 'assets/images/pets/turtle.jpg';
    return 'assets/images/pets/dog.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final name = _pet['name']?.toString() ?? 'Pet';
    final type = _pet['type']?.toString() ?? 'Pet';
    final breed = _pet['breed']?.toString() ?? 'Mixed';
    final gender = _pet['gender']?.toString() ?? 'Unknown';
    final weight = _pet['weightKg']?.toString();
    final dob = _pet['dateOfBirth']?.toString();
    final age = petAge(dob);
    final photoUrl = _pet['photoUrl']?.toString();

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
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: green.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textDark,
                      size: 20,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$type · $breed',
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: textDark),
                    onSelected: (val) {
                      if (val == 'edit') _editPet(context);
                      if (val == 'delete') _deletePet(context);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit pet profile',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete pet',
                          style: TextStyle(fontSize: 13, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- CONTENT ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- PROFILE CARD ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: PetPhotoImage(
                              petId: _pet['id']?.toString(),
                              photoUrl: photoUrl,
                              fallbackAsset: _getPlaceholderAsset(type),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: textDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$breed · $gender',
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  age,
                                  if (weight != null) 'Weight: $weight kg',
                                ].join(' • '),
                                style: const TextStyle(
                                  color: green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 6 CORE MANAGEMENT CARDS ---
                  const Text(
                    'Pet Care & Records',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildSectionCard(
                        context,
                        'Vaccinations',
                        'Track vaccine records',
                        Icons.medical_services_outlined,
                        () => _openSection(context, 'Vaccinations'),
                      ),
                      _buildSectionCard(
                        context,
                        'Health Records',
                        'Medical history',
                        Icons.favorite_border_rounded,
                        () => _openSection(context, 'Health Records'),
                      ),
                      _buildSectionCard(
                        context,
                        'Care Schedules',
                        'Upcoming activities',
                        Icons.alarm_rounded,
                        () => _openSection(context, 'Care Schedules'),
                      ),
                      _buildSectionCard(
                        context,
                        'Daily Care',
                        'Feeding and routines',
                        Icons.restaurant_menu_rounded,
                        () => _openSection(context, 'Daily Care'),
                      ),
                      _buildSectionCard(
                        context,
                        'Vet Visits',
                        'Appointments',
                        Icons.local_hospital_outlined,
                        () => _openSection(context, 'Vet Visits'),
                      ),
                      _buildSectionCard(
                        context,
                        'Pet Documents',
                        'Important files',
                        Icons.folder_open_rounded,
                        () => _openSection(context, 'Pet Documents'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: forest, size: 22),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSection(BuildContext context, String sectionName) {
    final petId = _pet['id']?.toString();
    if (petId == null) return;
    final petName = _pet['name']?.toString() ?? 'Pet';
    final Widget screen = switch (sectionName) {
      'Vaccinations' => VaccinationsScreen(
        petId: petId,
        familyId: widget.familyId,
        petName: petName,
      ),
      'Health Records' => PetHealthScreen(
        petId: petId,
        familyId: widget.familyId,
        petName: petName,
      ),
      'Care Schedules' => CareSchedulesScreen(
        petId: petId,
        familyId: widget.familyId,
        petName: petName,
      ),
      'Daily Care' => DailyCareScreen(petId: petId, petName: petName),
      'Vet Visits' => VetVisitsScreen(
        petId: petId,
        familyId: widget.familyId,
        petName: petName,
      ),
      'Pet Documents' => PetDocumentsScreen(petId: petId, petName: petName),
      _ => const SizedBox.shrink(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Future<void> _editPet(BuildContext context) async {
    final parentState = context.findAncestorStateOfType<_PetsScreenState>();
    if (parentState != null) {
      Navigator.pop(context);
      parentState._showAddPetModal(existingPet: _pet);
    }
  }

  Future<void> _deletePet(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete pet profile?'),
        content: Text('Are you sure you want to delete ${_pet['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.delete(_pet['id'].toString());
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet deleted successfully.')),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: white,
        border: Border(top: BorderSide(color: border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: white,
        selectedItemColor: green,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group_rounded),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_outlined),
            activeIcon: Icon(Icons.menu_rounded),
            label: 'More',
          ),
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
