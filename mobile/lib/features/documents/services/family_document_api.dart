import 'dart:convert';
import 'dart:typed_data';

import 'package:mobile/core/services/api_client.dart';
import 'package:mobile/core/services/api_config.dart';
import 'package:mobile/core/services/authenticated_http.dart' as http;

class FamilyDocumentApi {
  final http.AuthenticatedClient _client;
  FamilyDocumentApi({http.AuthenticatedClient? client})
      : _client = client ?? http.AuthenticatedClient();

  void close() => _client.close();

  Future<List<Map<String, dynamic>>> list(String familyId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/documents/$familyId'),
    );
    return _list(response);
  }

  Future<Map<String, dynamic>> upload({
    required String familyId,
    required Uint8List bytes,
    required String fileName,
    required String title,
    required String category,
    String? description,
    String? familyProfileId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/documents/$familyId/upload'),
    );
    request.fields.addAll({
      'title': title,
      'category': category,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (familyProfileId != null) 'familyProfileId': familyProfileId,
    });
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final response = await http.Response.fromStream(await _client.send(request));
    return _object(response, expected: 201);
  }

  Future<Uint8List> download(String id) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/documents/$id/file'),
    );
    if (response.statusCode != 200) _error(response);
    return response.bodyBytes;
  }

  Future<void> delete(String id) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/documents/$id'),
    );
    if (response.statusCode != 204) _error(response);
  }

  List<Map<String, dynamic>> _list(http.Response response) {
    if (response.statusCode != 200) _error(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const ApiException('The document response is invalid.');
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Map<String, dynamic> _object(http.Response response, {required int expected}) {
    if (response.statusCode != expected) _error(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const ApiException('The document response is invalid.');
    return Map<String, dynamic>.from(decoded);
  }

  Never _error(http.Response response) {
    String message = 'Document request failed (HTTP ${response.statusCode}).';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) message = decoded['error'] as String;
    } catch (_) {}
    throw ApiException(message);
  }
}
