import 'package:flutter/material.dart';
import '../../tasks/services/task_api.dart';
import '../services/pet_care_api.dart';
import '../widgets/pet_section_scaffold.dart';

class CareSchedulesScreen extends StatefulWidget {
  final String petId, petName, familyId;
  const CareSchedulesScreen({
    super.key,
    required this.petId,
    required this.petName,
    required this.familyId,
  });
  @override
  State<CareSchedulesScreen> createState() => _CareSchedulesScreenState();
}

class _CareSchedulesScreenState extends State<CareSchedulesScreen> {
  final api = PetCareApi(), taskApi = TaskApi();
  List<Map<String, dynamic>> schedules = [], members = [];
  bool loading = true;
  String? error;
  static const frequencies = {
    'DAILY': 'Daily',
    'SELECTED_WEEKDAYS': 'Selected weekdays',
    'WEEKLY': 'Weekly',
    'MONTHLY': 'Monthly',
    'ONE_TIME': 'One-time',
  };
  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
      final data = await Future.wait([
        api.schedules(widget.petId),
        taskApi.members(widget.familyId),
      ]);
      if (mounted) {
        setState(() {
          schedules = data[0];
          members = data[1];
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

  String assigneeName(Object? id) {
    if (id == null) return 'Unassigned';
    for (final member in members) {
      if (member['id']?.toString() == id.toString()) {
        return TaskApi.memberName(member);
      }
    }
    return 'Member unavailable';
  }

  @override
  Widget build(BuildContext context) => PetSectionScaffold(
    title: '${widget.petName} · Care Schedules',
    onAdd: loading || error != null ? null : () => edit(),
    addLabel: 'Add Schedule',
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? PetSectionError(message: error!, retry: load)
        : schedules.isEmpty
        ? const PetSectionEmpty(
            message:
                'No care schedules yet. Add feeding, walking, grooming or another activity.',
          )
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: schedules.map(card).toList(),
            ),
          ),
  );
  Widget card(Map<String, dynamic> value) {
    final active = value['active'] == true;
    final frequency =
        frequencies[value['frequency']] ?? value['frequency']?.toString() ?? '';
    final subtitle =
        '$frequency · ${value['scheduledTime'] ?? ''}\n${assigneeName(value['assignedMemberId'])} · ${active ? 'Active' : 'Paused'}';
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE5EEE7),
          child: Icon(active ? Icons.pets : Icons.pause),
        ),
        title: Text(
          value['activityName']?.toString() ?? 'Care activity',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        isThreeLine: true,
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(value['activityName']?.toString() ?? 'Care activity'),
            content: Text(
              'Instructions: ${value['description'] ?? 'None'}\nStart: ${value['startDate']}\nEnd: ${value['endDate'] ?? 'Not set'}\nAutomatic tasks: ${value['autoTasks'] == true ? 'On' : 'Off'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') edit(value);
            if (action == 'toggle') toggle(value);
            if (action == 'delete') remove(value);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(active ? 'Pause' : 'Resume'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> toggle(Map<String, dynamic> value) async {
    try {
      await api.saveSchedule(widget.petId, {
        'activityName': value['activityName'],
        'description': value['description'],
        'frequency': value['frequency'],
        'weekdays': parseDays(value['weekdays']).toList(),
        'scheduledTime': value['scheduledTime'],
        'startDate': value['startDate'],
        'endDate': value['endDate'],
        'assignedMemberId': value['assignedMemberId'],
        'active': value['active'] != true,
        'autoTasks': value['autoTasks'],
      }, id: value['id'].toString());
      await load();
      message(
        value['active'] == true ? 'Schedule paused.' : 'Schedule resumed.',
      );
    } catch (e) {
      message(e.toString());
    }
  }

  Set<int> parseDays(Object? value) =>
      value
          ?.toString()
          .split(',')
          .map((v) => int.tryParse(v))
          .whereType<int>()
          .toSet() ??
      <int>{};
  Future<void> remove(Map<String, dynamic> value) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: const Text(
          'Future pending tasks will be removed. Completed task history stays available.',
        ),
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
      await api.deleteSchedule(widget.petId, value['id'].toString());
      await load();
      message('Schedule deleted.');
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> edit([Map<String, dynamic>? current]) async {
    final name = TextEditingController(
      text: current?['activityName']?.toString() ?? '',
    );
    final details = TextEditingController(
      text: current?['description']?.toString() ?? '',
    );
    String frequency = current?['frequency']?.toString() ?? 'DAILY';
    Set<int> weekdays = parseDays(current?['weekdays']);
    DateTime? start =
        DateTime.tryParse(current?['startDate']?.toString() ?? '') ??
        DateTime.now();
    DateTime? end = DateTime.tryParse(current?['endDate']?.toString() ?? '');
    final parts = current?['scheduledTime']?.toString().split(':');
    TimeOfDay time = parts != null && parts.length >= 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 8,
            minute: int.tryParse(parts[1]) ?? 0,
          )
        : const TimeOfDay(hour: 8, minute: 0);
    String? assignee = current?['assignedMemberId']?.toString();
    bool active = current?['active'] != false;
    bool auto = current?['autoTasks'] == true;
    bool saving = false;
    String? iso(DateTime? date) => date?.toIso8601String().split('T').first;
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
                Text(
                  current == null ? 'Add Care Schedule' : 'Edit Care Schedule',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Activity name *',
                  ),
                ),
                TextField(
                  controller: details,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Instructions (optional)',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: frequencies.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => update(() => frequency = value!),
                ),
                if (frequency == 'SELECTED_WEEKDAYS')
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 1; i <= 7; i++)
                        FilterChip(
                          label: Text(days[i - 1]),
                          selected: weekdays.contains(i),
                          onSelected: (selected) => update(() {
                            if (selected) {
                              weekdays.add(i);
                            } else {
                              weekdays.remove(i);
                            }
                          }),
                        ),
                    ],
                  ),
                ListTile(
                  title: Text('Time: ${time.format(sheet)}'),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final result = await showTimePicker(
                      context: sheet,
                      initialTime: time,
                    );
                    if (result != null) update(() => time = result);
                  },
                ),
                ListTile(
                  title: Text('Start: ${iso(start)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final result = await showDatePicker(
                      context: sheet,
                      initialDate: start!,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (result != null) update(() => start = result);
                  },
                ),
                ListTile(
                  title: Text('End: ${iso(end) ?? 'Not set'}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final result = await showDatePicker(
                      context: sheet,
                      initialDate: end ?? start!,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (result != null) update(() => end = result);
                  },
                ),
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
                      (member) => DropdownMenuItem<String?>(
                        value: member['id']?.toString(),
                        child: Text(TaskApi.memberName(member)),
                      ),
                    ),
                  ],
                  onChanged: (value) => update(() => assignee = value),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: active,
                  onChanged: (value) => update(() => active = value),
                ),
                SwitchListTile(
                  title: const Text(
                    'Automatically create tasks for the next 14 days',
                  ),
                  value: auto,
                  onChanged: (value) => update(() => auto = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (name.text.trim().isEmpty ||
                                (frequency == 'SELECTED_WEEKDAYS' &&
                                    weekdays.isEmpty) ||
                                (end != null && end!.isBefore(start!))) {
                              message(
                                'Check the activity, weekdays and dates.',
                              );
                              return;
                            }
                            update(() => saving = true);
                            try {
                              await api.saveSchedule(widget.petId, {
                                'activityName': name.text.trim(),
                                'description': details.text.trim(),
                                'frequency': frequency,
                                'weekdays': weekdays.toList(),
                                'scheduledTime':
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
                                'startDate': iso(start),
                                'endDate': iso(end),
                                'assignedMemberId': assignee,
                                'active': active,
                                'autoTasks': auto,
                              }, id: current?['id']?.toString());
                              if (sheet.mounted) Navigator.pop(sheet);
                              await load();
                              message('Care schedule saved.');
                            } catch (e) {
                              message(e.toString());
                            } finally {
                              if (sheet.mounted) update(() => saving = false);
                            }
                          },
                    child: Text(saving ? 'Saving…' : 'Save Schedule'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
    details.dispose();
  }
}
