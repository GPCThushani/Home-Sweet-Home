import 'dart:convert';
import 'package:mobile/core/services/api_client.dart';
import 'package:mobile/core/services/api_config.dart';
import 'package:mobile/features/family/models/family_profile.dart';

class TaskApi {
  final ApiClient _client;
  TaskApi({ApiClient? client}) : _client = client ?? ApiClient();
  void close() => _client.close();

  Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}/$path');
  Map<String, dynamic> _task(dynamic value, String familyId) {
    if (value is! Map ||
        value['family'] is! Map ||
        value['family']['id'] != familyId) {
      throw const FormatException(
        'Task response belongs to a different family',
      );
    }
    FamilyProfile.uuid(value['id']);
    return Map<String, dynamic>.from(value);
  }

  Future<List<Map<String, dynamic>>> tasks(String familyId) async {
    FamilyProfile.uuid(familyId);
    final response = await _client.get(_url('tasks/family/$familyId'));
    final data = jsonDecode(response.body);
    if (data is! List) {
      throw const FormatException('Invalid task list response');
    }
    return data.map((value) => _task(value, familyId)).toList();
  }

  Future<List<Map<String, dynamic>>> members(String familyId) async {
    FamilyProfile.uuid(familyId);
    final response = await _client.get(_url('families/$familyId/members'));
    final data = jsonDecode(response.body);
    if (data is! List) {
      throw const FormatException('Invalid task membership response');
    }
    final seen = <String>{};
    return data.map((value) {
      if (value is! Map || value['familyId'] != familyId) {
        throw const FormatException('Member belongs to a different family');
      }
      final id = FamilyProfile.uuid(value['membershipId'] ?? value['id']);
      if (id != value['id'] || !seen.add(id)) {
        throw const FormatException('Invalid or duplicate membership ID');
      }
      return Map<String, dynamic>.from(value);
    }).toList();
  }

  Future<Map<String, dynamic>> save(
    String familyId,
    Map<String, dynamic> fields, {
    String? taskId,
  }) async {
    FamilyProfile.uuid(familyId);
    if (taskId != null) FamilyProfile.uuid(taskId);
    final assignee = fields['assignedToMemberId'];
    if (assignee != null) FamilyProfile.uuid(assignee);
    final response = await (taskId == null ? _client.post : _client.put)(
      _url(taskId == null ? 'tasks' : 'tasks/$taskId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({...fields, if (taskId == null) 'familyId': familyId}),
    );
    return _task(jsonDecode(response.body), familyId);
  }

  Future<void> complete(String familyId, String taskId) async {
    FamilyProfile.uuid(taskId);
    final response = await _client.put(_url('tasks/$taskId/complete'));
    _task(jsonDecode(response.body), familyId);
  }

  Future<void> delete(String taskId) async {
    FamilyProfile.uuid(taskId);
    await _client.delete(_url('tasks/$taskId'));
  }

  static String memberName(dynamic value) {
    if (value is! Map) return 'Unassigned';
    for (final key in ['name', 'nickname']) {
      final name = value[key];
      if (name is String && name.trim().isNotEmpty) return name;
    }
    return 'Family member';
  }
}
