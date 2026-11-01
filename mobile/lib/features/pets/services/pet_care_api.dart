import 'dart:convert';
import 'dart:typed_data';
import 'package:mobile/core/services/api_client.dart';
import 'package:mobile/core/services/api_config.dart';
import 'package:mobile/core/services/authenticated_http.dart' as http;
import 'package:mobile/features/family/models/family_profile.dart';

class PetCareApi {
  final ApiClient _client;
  PetCareApi({ApiClient? client}) : _client = client ?? ApiClient();
  void close() => _client.close();
  Uri _url(String petId, String path) {
    FamilyProfile.uuid(petId);
    return Uri.parse('${ApiConfig.baseUrl}/pets/$petId/$path');
  }

  List<Map<String, dynamic>> _list(http.Response response) {
    final value = jsonDecode(response.body);
    if (value is! List) throw const ApiException('Invalid pet data response.');
    return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Map<String, dynamic> _map(http.Response response) =>
      Map<String, dynamic>.from(jsonDecode(response.body) as Map);

  Future<List<Map<String, dynamic>>> entries(String petId, String kind) async =>
      _list(await _client.get(_url(petId, 'entries/$kind')));
  Future<Map<String, dynamic>> saveEntry(
    String petId,
    String kind,
    Map<String, dynamic> data, {
    String? id,
  }) async => _map(
    id == null
        ? await _client.post(
            _url(petId, 'entries/$kind'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
        : await _client.put(
            _url(petId, 'entries/$kind/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          ),
  );
  Future<void> deleteEntry(String petId, String kind, String id) async =>
      _client.delete(_url(petId, 'entries/$kind/$id'));

  Future<List<Map<String, dynamic>>> schedules(String petId) async =>
      _list(await _client.get(_url(petId, 'care-schedules')));
  Future<Map<String, dynamic>> saveSchedule(
    String petId,
    Map<String, dynamic> data, {
    String? id,
  }) async => _map(
    id == null
        ? await _client.post(
            _url(petId, 'care-schedules'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
        : await _client.put(
            _url(petId, 'care-schedules/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          ),
  );
  Future<void> deleteSchedule(String petId, String id) async =>
      _client.delete(_url(petId, 'care-schedules/$id'));

  Future<Map<String, dynamic>> instructions(String petId) async =>
      _map(await _client.get(_url(petId, 'daily-care/instructions')));
  Future<Map<String, dynamic>> saveInstructions(
    String petId,
    Map<String, dynamic> data,
  ) async => _map(
    await _client.put(
      _url(petId, 'daily-care/instructions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ),
  );
  Future<List<Map<String, dynamic>>> history(String petId) async =>
      _list(await _client.get(_url(petId, 'daily-care/history')));

  Future<List<Map<String, dynamic>>> documents(String petId) async =>
      _list(await _client.get(_url(petId, 'documents')));
  Future<Map<String, dynamic>> uploadDocument(
    String petId, {
    required Uint8List bytes,
    required String fileName,
    required String title,
    required String category,
  }) async {
    final request = http.MultipartRequest('POST', _url(petId, 'documents'));
    request.fields.addAll({'title': title, 'category': category});
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    return _map(await http.Response.fromStream(await _client.send(request)));
  }

  Future<Uint8List> documentBytes(String petId, String id) async =>
      (await _client.get(_url(petId, 'documents/$id/file'))).bodyBytes;
  Future<void> deleteDocument(String petId, String id) async =>
      _client.delete(_url(petId, 'documents/$id'));
}
