import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/pet_care_api.dart';
import '../widgets/pet_section_scaffold.dart';

List<Map<String, dynamic>> filterPetDocuments(
  List<Map<String, dynamic>> documents, {
  String query = '',
  String? category,
}) {
  final text = query.trim().toLowerCase();
  return documents
      .where(
        (doc) =>
            (category == null || doc['category'] == category) &&
            (text.isEmpty ||
                doc['title']?.toString().toLowerCase().contains(text) == true ||
                doc['fileName']?.toString().toLowerCase().contains(text) ==
                    true),
      )
      .toList();
}

class PetDocumentsScreen extends StatefulWidget {
  final String petId, petName;
  const PetDocumentsScreen({
    super.key,
    required this.petId,
    required this.petName,
  });
  @override
  State<PetDocumentsScreen> createState() => _PetDocumentsScreenState();
}

class _PetDocumentsScreenState extends State<PetDocumentsScreen> {
  static const categories = [
    'Vaccination Certificates',
    'Prescriptions',
    'Medical Reports',
    'Laboratory Results',
    'Registration Documents',
    'Insurance Documents',
    'Other',
  ];
  final api = PetCareApi();
  final search = TextEditingController();
  List<Map<String, dynamic>> documents = [];
  String? category, error;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  @override
  void dispose() {
    search.dispose();
    api.close();
    super.dispose();
  }

  void message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final items = await api.documents(widget.petId);
      if (mounted) {
        setState(() {
          documents = items;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get visible {
    return filterPetDocuments(
      documents,
      query: search.text,
      category: category,
    );
  }

  @override
  Widget build(BuildContext context) => PetSectionScaffold(
    title: '${widget.petName} · Pet Documents',
    onAdd: loading || error != null ? null : upload,
    addLabel: 'Upload Document',
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? PetSectionError(message: error!, retry: load)
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Text(
                  '${documents.length} ${documents.length == 1 ? 'document' : 'documents'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    labelText: 'Search pet documents',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: category == null,
                          onSelected: (_) => setState(() => category = null),
                        ),
                      ),
                      for (final value in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text(value),
                            selected: category == value,
                            onSelected: (_) => setState(() => category = value),
                          ),
                        ),
                    ],
                  ),
                ),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('No documents found.')),
                  ),
                ...visible.map(
                  (doc) => Card(
                    color: Colors.white,
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(
                        Icons.description_rounded,
                        color: Color(0xFF355C4A),
                      ),
                      title: Text(
                        doc['title']?.toString() ?? 'Document',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${doc['category']} · ${doc['fileName']}\n${doc['uploadedAt'] ?? ''} · ${((doc['fileSize'] as num?)?.toDouble() ?? 0) / 1024 ~/ 1} KB',
                      ),
                      isThreeLine: true,
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (dialog) => AlertDialog(
                          title: Text(doc['title']?.toString() ?? 'Document'),
                          content: Text(
                            'Category: ${doc['category']}\nFile: ${doc['fileName']}\nType: ${doc['contentType']}\nUploaded: ${doc['uploadedAt']}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialog),
                              child: const Text('Close'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialog);
                                download(doc);
                              },
                              child: const Text('Download'),
                            ),
                          ],
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'download') download(doc);
                          if (action == 'delete') remove(doc);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'download',
                            child: Text('Open / download'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
  Future<void> download(Map<String, dynamic> doc) async {
    try {
      final bytes = await api.documentBytes(widget.petId, doc['id'].toString());
      final saved = await FilePicker.saveFile(
        fileName: doc['fileName']?.toString() ?? 'document',
        bytes: bytes,
      );
      if (kIsWeb || saved != null) message('Document download is ready.');
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> remove(Map<String, dynamic> doc) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete pet document?'),
        content: Text('Delete ${doc['title']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    try {
      await api.deleteDocument(widget.petId, doc['id'].toString());
      await load();
      message('Document deleted.');
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> upload() async {
    final title = TextEditingController();
    PlatformFile? file;
    String chosenCategory = categories.first;
    bool saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF8F3),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(sheet).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Pet Document',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final choice = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            withData: true,
                          );
                          final selected = choice?.files.single;
                          if (selected == null) return;
                          if (selected.bytes == null ||
                              selected.size == 0 ||
                              selected.size > 10 * 1024 * 1024) {
                            message('Choose a file between 1 byte and 10 MB.');
                            return;
                          }
                          update(() {
                            file = selected;
                            if (title.text.isEmpty) title.text = selected.name;
                          });
                        },
                  icon: const Icon(Icons.attach_file),
                  label: Text(file?.name ?? 'Choose PDF, JPG or PNG'),
                ),
                TextField(
                  controller: title,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Document title *',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: chosenCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => update(() => chosenCategory = value!),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (file == null || title.text.trim().isEmpty) {
                              message('Choose a file and enter a title.');
                              return;
                            }
                            update(() => saving = true);
                            try {
                              await api.uploadDocument(
                                widget.petId,
                                bytes: file!.bytes!,
                                fileName: file!.name,
                                title: title.text.trim(),
                                category: chosenCategory,
                              );
                              if (sheet.mounted) Navigator.pop(sheet);
                              await load();
                              message('Pet document uploaded.');
                            } catch (e) {
                              message(e.toString());
                            } finally {
                              if (sheet.mounted) update(() => saving = false);
                            }
                          },
                    child: Text(saving ? 'Uploading…' : 'Upload'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    title.dispose();
  }
}
