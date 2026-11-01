import 'package:flutter/material.dart';
import '../../tasks/services/task_api.dart';
import '../services/pet_care_api.dart';
import '../widgets/pet_section_scaffold.dart';

/// Shared record editor; dedicated section screens select their own record kind.
class PetRecordScreen extends StatefulWidget {
  final String petId, familyId, petName, section;
  const PetRecordScreen({
    super.key,
    required this.petId,
    required this.familyId,
    required this.petName,
    required this.section,
  });
  @override
  State<PetRecordScreen> createState() => _PetRecordScreenState();
}

class _PetRecordScreenState extends State<PetRecordScreen> {
  final api = PetCareApi();
  final taskApi = TaskApi();
  List<Map<String, dynamic>> records = [];
  List<Map<String, dynamic>> members = [];
  String? error;
  bool loading = true;
  String healthTab = 'HEALTH';
  String get kind => widget.section == 'HEALTH' ? healthTab : widget.section;
  String get heading => switch (widget.section) {
    'VACCINATION' => 'Vaccinations',
    'HEALTH' => 'Health Records',
    'VET' => 'Vet Visits',
    _ => 'Pet Records',
  };
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    api.close();
    taskApi.close();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final values = await api.entries(widget.petId, kind);
      final people = (kind == 'VACCINATION' || kind == 'VET')
          ? await taskApi.members(widget.familyId)
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          records = values;
          members = people;
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

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> changeTab(String value) async {
    setState(() => healthTab = value);
    await load();
  }

  @override
  Widget build(BuildContext context) => PetSectionScaffold(
    title: '${widget.petName} · $heading',
    onAdd: loading || error != null ? null : () => edit(),
    addLabel: kind == 'WEIGHT'
        ? 'Add Weight'
        : kind == 'MEDICATION'
        ? 'Add Medication'
        : 'Add Record',
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? PetSectionError(message: error!, retry: load)
        : Column(
            children: [
              if (widget.section == 'HEALTH')
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      for (final tab in ['HEALTH', 'MEDICATION', 'WEIGHT'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              tab == 'HEALTH'
                                  ? 'Medical history'
                                  : tab == 'MEDICATION'
                                  ? 'Medications'
                                  : 'Weight history',
                            ),
                            selected: healthTab == tab,
                            onSelected: (_) => changeTab(tab),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: records.isEmpty
                    ? PetSectionEmpty(
                        message: 'No ${kind.toLowerCase()} records yet.',
                      )
                    : RefreshIndicator(
                        onRefresh: load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          children: ordered().map(card).toList(),
                        ),
                      ),
              ),
            ],
          ),
  );

  List<Map<String, dynamic>> ordered() {
    final items = [...records];
    if (kind == 'VET') {
      items.sort((a, b) {
        final aCurrent = a['status'] == 'UPCOMING' ? 0 : 1;
        final bCurrent = b['status'] == 'UPCOMING' ? 0 : 1;
        if (aCurrent != bCurrent) return aCurrent.compareTo(bCurrent);
        return (a['appointmentAt']?.toString() ?? '').compareTo(
          b['appointmentAt']?.toString() ?? '',
        );
      });
    } else if (kind == 'WEIGHT') {
      items.sort(
        (a, b) => (a['recordDate']?.toString() ?? '').compareTo(
          b['recordDate']?.toString() ?? '',
        ),
      );
    }
    return items;
  }

  Widget card(Map<String, dynamic> value) {
    final date = kind == 'VET'
        ? value['appointmentAt']?.toString()
        : value['recordDate']?.toString() ?? value['startDate']?.toString();
    final status = kind == 'VACCINATION'
        ? value['computedStatus']?.toString()
        : value['status']?.toString();
    final subtitle = kind == 'WEIGHT'
        ? '${value['weightKg'] ?? '?'} kg'
        : kind == 'MEDICATION'
        ? '${value['dosage'] ?? ''} · ${value['frequency'] ?? ''}'
        : kind == 'VACCINATION'
        ? 'Next due: ${value['nextDueDate'] ?? 'Not set'}'
        : kind == 'VET'
        ? '${value['clinic'] ?? ''} · ${value['veterinarian'] ?? ''}'
        : value['description']?.toString() ?? '';
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(value['title']?.toString() ?? heading),
            content: SingleChildScrollView(
              child: Text(
                [
                  if (date != null) 'Date: $date',
                  if (status != null) 'Status: $status',
                  if (subtitle.isNotEmpty) subtitle,
                  if (value['diagnosisTreatment'] != null)
                    value['diagnosisTreatment'].toString(),
                  if (value['instructions'] != null)
                    value['instructions'].toString(),
                  if (value['notes'] != null) value['notes'].toString(),
                ].join('\n\n'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE5EEE7),
          foregroundColor: Color(0xFF355C4A),
          child: Icon(Icons.pets),
        ),
        title: Text(
          value['title']?.toString() ?? heading,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            if (date != null) date,
            subtitle,
            if (status != null) status,
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') edit(value);
            if (action == 'delete') remove(value);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> remove(Map<String, dynamic> value) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('Delete ${value['title']}?'),
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
      await api.deleteEntry(widget.petId, kind, value['id'].toString());
      await load();
      message('Record deleted.');
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> edit([Map<String, dynamic>? current]) async {
    final title = TextEditingController(
      text: current?['title']?.toString() ?? '',
    );
    final description = TextEditingController(
      text: current?['description']?.toString() ?? '',
    );
    final diagnosis = TextEditingController(
      text: current?['diagnosisTreatment']?.toString() ?? '',
    );
    final vet = TextEditingController(
      text: current?['veterinarian']?.toString() ?? '',
    );
    final clinic = TextEditingController(
      text: current?['clinic']?.toString() ?? '',
    );
    final notes = TextEditingController(
      text: current?['notes']?.toString() ?? '',
    );
    final dosage = TextEditingController(
      text: current?['dosage']?.toString() ?? '',
    );
    final frequency = TextEditingController(
      text: current?['frequency']?.toString() ?? '',
    );
    final instructions = TextEditingController(
      text: current?['instructions']?.toString() ?? '',
    );
    final weight = TextEditingController(
      text: current?['weightKg']?.toString() ?? '',
    );
    DateTime? date = DateTime.tryParse(
      current?['recordDate']?.toString() ?? '',
    );
    DateTime? nextDue = DateTime.tryParse(
      current?['nextDueDate']?.toString() ?? '',
    );
    DateTime? start = DateTime.tryParse(
      current?['startDate']?.toString() ?? '',
    );
    DateTime? end = DateTime.tryParse(current?['endDate']?.toString() ?? '');
    DateTime? appointment = DateTime.tryParse(
      current?['appointmentAt']?.toString() ?? '',
    )?.toLocal();
    String status = current?['status']?.toString() ?? 'UPCOMING';
    String recordType = current?['recordType']?.toString() ?? 'OTHER';
    bool reminder = current?['reminderTask'] == true;
    String? assignee = current?['assignedMemberId']?.toString();
    bool saving = false;
    String? iso(DateTime? value) => value?.toIso8601String().split('T').first;
    Future<DateTime?> pickDate(DateTime? initial) => showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    Widget field(
      TextEditingController controller,
      String label, {
      TextInputType? keyboard,
      int lines = 1,
    }) => TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF8F3),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(sheet).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current == null ? 'Add $heading' : 'Edit $heading',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                field(
                  title,
                  kind == 'MEDICATION'
                      ? 'Medication name *'
                      : kind == 'VACCINATION'
                      ? 'Vaccine name *'
                      : 'Title *',
                ),
                if (kind != 'MEDICATION' && kind != 'VET')
                  ListTile(
                    title: Text(
                      kind == 'VACCINATION'
                          ? 'Date administered: ${iso(date) ?? 'Choose date'}'
                          : 'Date: ${iso(date) ?? 'Choose date'}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final chosen = await pickDate(date);
                      if (chosen != null) update(() => date = chosen);
                    },
                  ),
                if (kind == 'VACCINATION')
                  ListTile(
                    title: Text('Next due: ${iso(nextDue) ?? 'Not set'}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final chosen = await pickDate(nextDue);
                      if (chosen != null) update(() => nextDue = chosen);
                    },
                  ),
                if (kind == 'VET')
                  ListTile(
                    title: Text(
                      'Appointment: ${appointment?.toString() ?? 'Choose date and time'}',
                    ),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final chosen = await pickDate(appointment);
                      if (chosen == null || !sheet.mounted) return;
                      final time = await showTimePicker(
                        context: sheet,
                        initialTime: TimeOfDay.fromDateTime(
                          appointment ?? DateTime.now(),
                        ),
                      );
                      if (time != null) {
                        update(
                          () => appointment = DateTime(
                            chosen.year,
                            chosen.month,
                            chosen.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      }
                    },
                  ),
                if (kind == 'VET')
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['UPCOMING', 'COMPLETED', 'CANCELLED']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => update(() => status = v!),
                  ),
                if (kind == 'MEDICATION') ...[
                  field(dosage, 'Dosage *'),
                  field(frequency, 'Frequency *'),
                  ListTile(
                    title: Text('Start date: ${iso(start) ?? 'Choose date'}'),
                    onTap: () async {
                      final d = await pickDate(start);
                      if (d != null) update(() => start = d);
                    },
                  ),
                  ListTile(
                    title: Text('End date: ${iso(end) ?? 'Optional'}'),
                    onTap: () async {
                      final d = await pickDate(end);
                      if (d != null) update(() => end = d);
                    },
                  ),
                  field(instructions, 'Instructions', lines: 2),
                ],
                if (kind == 'HEALTH')
                  DropdownButtonFormField<String>(
                    initialValue: recordType,
                    decoration: const InputDecoration(labelText: 'Record type'),
                    items:
                        [
                              'ALLERGY',
                              'CONDITION',
                              'ILLNESS',
                              'TREATMENT',
                              'OTHER',
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (v) => update(() => recordType = v!),
                  ),
                if (kind == 'WEIGHT')
                  field(
                    weight,
                    'Weight (kg) *',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                if (kind == 'HEALTH' || kind == 'VET')
                  field(
                    description,
                    kind == 'VET' ? 'Reason for visit' : 'Description',
                    lines: 2,
                  ),
                if (kind == 'HEALTH')
                  field(diagnosis, 'Diagnosis / treatment', lines: 2),
                if (kind == 'VET' ||
                    kind == 'VACCINATION' ||
                    kind == 'HEALTH') ...[
                  field(clinic, 'Clinic'),
                  field(vet, 'Veterinarian'),
                ],
                if (kind != 'WEIGHT') field(notes, 'Notes', lines: 2),
                if (kind == 'VET' || kind == 'VACCINATION') ...[
                  SwitchListTile(
                    title: const Text('Create reminder in Global Tasks'),
                    value: reminder,
                    onChanged: (v) => update(() => reminder = v),
                  ),
                  if (reminder)
                    DropdownButtonFormField<String?>(
                      initialValue: assignee,
                      decoration: const InputDecoration(
                        labelText: 'Assigned family member',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        ...members.map(
                          (m) => DropdownMenuItem<String?>(
                            value: m['id']?.toString(),
                            child: Text(TaskApi.memberName(m)),
                          ),
                        ),
                      ],
                      onChanged: (v) => update(() => assignee = v),
                    ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (title.text.trim().isEmpty ||
                                ((kind == 'HEALTH' ||
                                        kind == 'VACCINATION' ||
                                        kind == 'WEIGHT') &&
                                    date == null) ||
                                (kind == 'VET' &&
                                    (appointment == null ||
                                        clinic.text.trim().isEmpty)) ||
                                (kind == 'MEDICATION' &&
                                    (dosage.text.trim().isEmpty ||
                                        frequency.text.trim().isEmpty ||
                                        start == null)) ||
                                (kind == 'WEIGHT' &&
                                    (double.tryParse(weight.text) == null ||
                                        double.parse(weight.text) <= 0))) {
                              message('Complete the required fields.');
                              return;
                            }
                            update(() => saving = true);
                            try {
                              await api.saveEntry(widget.petId, kind, {
                                'title': title.text.trim(),
                                'recordType': recordType,
                                'recordDate': iso(date),
                                'nextDueDate': iso(nextDue),
                                'appointmentAt': appointment
                                    ?.toUtc()
                                    .toIso8601String(),
                                'status': status,
                                'description': description.text.trim(),
                                'diagnosisTreatment': diagnosis.text.trim(),
                                'veterinarian': vet.text.trim(),
                                'clinic': clinic.text.trim(),
                                'notes': notes.text.trim(),
                                'dosage': dosage.text.trim(),
                                'frequency': frequency.text.trim(),
                                'startDate': iso(start),
                                'endDate': iso(end),
                                'instructions': instructions.text.trim(),
                                'weightKg': double.tryParse(weight.text),
                                'assignedMemberId': assignee,
                                'reminderTask': reminder,
                              }, id: current?['id']?.toString());
                              if (sheet.mounted) Navigator.pop(sheet);
                              await load();
                              message('Record saved.');
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
    for (final controller in [
      title,
      description,
      diagnosis,
      vet,
      clinic,
      notes,
      dosage,
      frequency,
      instructions,
      weight,
    ]) {
      controller.dispose();
    }
  }
}
