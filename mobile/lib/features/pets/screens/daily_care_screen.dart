import 'package:flutter/material.dart';
import '../services/pet_care_api.dart';
import '../widgets/pet_section_scaffold.dart';

class DailyCareScreen extends StatefulWidget {
  final String petId, petName;
  const DailyCareScreen({
    super.key,
    required this.petId,
    required this.petName,
  });
  @override
  State<DailyCareScreen> createState() => _DailyCareScreenState();
}

class _DailyCareScreenState extends State<DailyCareScreen> {
  final api = PetCareApi();
  Map<String, dynamic> instructions = {};
  List<Map<String, dynamic>> history = [];
  String? error;
  bool loading = true;
  static const fields = {
    'foodType': 'Food type',
    'foodBrand': 'Food brand',
    'portionSize': 'Portion size',
    'feedingInstructions': 'Feeding instructions',
    'dietaryNotes': 'Special dietary notes',
    'exerciseInstructions': 'Exercise instructions',
    'walkingMinutes': 'Walking duration (minutes)',
    'groomingInstructions': 'Grooming instructions',
    'bathingInstructions': 'Bathing instructions',
    'generalInstructions': 'General care instructions',
    'handlingInstructions': 'Special handling instructions',
  };
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final info = await api.instructions(widget.petId);
      final completed = await api.history(widget.petId);
      if (mounted) {
        setState(() {
          instructions = info;
          history = completed;
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

  @override
  Widget build(BuildContext context) => PetSectionScaffold(
    title: '${widget.petName} · Daily Care',
    onAdd: loading || error != null ? null : edit,
    addLabel: 'Edit Care Info',
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? PetSectionError(message: error!, retry: load)
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                const Text(
                  'Feeding Information',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                ...section([
                  'foodType',
                  'foodBrand',
                  'portionSize',
                  'feedingInstructions',
                  'dietaryNotes',
                ]),
                const SizedBox(height: 16),
                const Text(
                  'Exercise & Grooming',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                ...section([
                  'exerciseInstructions',
                  'walkingMinutes',
                  'groomingInstructions',
                  'bathingInstructions',
                ]),
                const SizedBox(height: 16),
                const Text(
                  'Additional Care Notes',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                ...section(['generalInstructions', 'handlingInstructions']),
                const SizedBox(height: 20),
                const Text(
                  'Recent Care History',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Complete care tasks in Global Tasks. This history is read-only.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF65716B)),
                ),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No completed pet-care tasks yet.'),
                  ),
                ...history.map(
                  (task) => Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: const Icon(
                        Icons.task_alt,
                        color: Color(0xFF4A8B71),
                      ),
                      title: Text(task['title']?.toString() ?? 'Care activity'),
                      subtitle: Text(
                        'Completed ${task['completedAt'] ?? ''}\nBy ${task['completedBy']?['nickname'] ?? task['completedBy']?['user']?['email'] ?? 'family member'}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
  List<Widget> section(List<String> keys) => keys
      .map(
        (key) => Card(
          color: Colors.white,
          elevation: 0,
          child: ListTile(
            title: Text(
              fields[key]!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF65716B)),
            ),
            subtitle: Text(
              instructions[key]?.toString().isNotEmpty == true
                  ? instructions[key].toString()
                  : 'Not recorded',
              style: const TextStyle(color: Color(0xFF244032)),
            ),
          ),
        ),
      )
      .toList();

  Future<void> edit() async {
    final controllers = <String, TextEditingController>{
      for (final key in fields.keys)
        key: TextEditingController(text: instructions[key]?.toString() ?? ''),
    };
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
                  'Edit Daily Care Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                for (final entry in fields.entries)
                  TextField(
                    controller: controllers[entry.key],
                    keyboardType: entry.key == 'walkingMinutes'
                        ? TextInputType.number
                        : TextInputType.text,
                    maxLines:
                        entry.key.endsWith('Instructions') ||
                            entry.key == 'dietaryNotes'
                        ? 2
                        : 1,
                    decoration: InputDecoration(labelText: entry.value),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final minutesText = controllers['walkingMinutes']!
                                .text
                                .trim();
                            final minutes = minutesText.isEmpty
                                ? null
                                : int.tryParse(minutesText);
                            if (minutesText.isNotEmpty &&
                                (minutes == null ||
                                    minutes < 0 ||
                                    minutes > 1440)) {
                              message(
                                'Enter a walking duration from 0 to 1440 minutes.',
                              );
                              return;
                            }
                            update(() => saving = true);
                            try {
                              await api.saveInstructions(widget.petId, {
                                for (final key in fields.keys)
                                  if (key != 'walkingMinutes')
                                    key: controllers[key]!.text.trim(),
                                'walkingMinutes': minutes,
                              });
                              if (sheet.mounted) Navigator.pop(sheet);
                              await load();
                              message('Care instructions saved.');
                            } catch (e) {
                              message(e.toString());
                            } finally {
                              if (sheet.mounted) update(() => saving = false);
                            }
                          },
                    child: Text(saving ? 'Saving…' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }
}
