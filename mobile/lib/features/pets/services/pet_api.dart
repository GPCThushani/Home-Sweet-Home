import 'dart:convert';
import 'dart:typed_data';
import 'package:mobile/core/services/api_config.dart';
import 'package:mobile/core/services/api_client.dart';
import 'package:mobile/core/services/authenticated_http.dart' as http;

class PetApi {
  final http.AuthenticatedClient _client;
  PetApi({http.AuthenticatedClient? client})
    : _client = client ?? http.AuthenticatedClient();
  void close() => _client.close();
  Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}/pets/$path');

  Future<List<Map<String, dynamic>>> list(String familyId) async {
    final response = await _client.get(_url(familyId));
    if (response.statusCode != 200) _fail(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const ApiException('Invalid pet response.');
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> save(
    String familyId,
    Map<String, dynamic> data, {
    String? petId,
  }) async {
    final response = petId == null
        ? await _client.post(
            _url(familyId),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
        : await _client.put(
            _url(petId),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          );
    if (response.statusCode != (petId == null ? 201 : 200)) _fail(response);
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> uploadPhoto(
    String petId,
    Uint8List bytes,
    String fileName,
  ) async {
    final request = http.MultipartRequest('POST', _url('$petId/photo'));
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    if (response.statusCode != 200) _fail(response);
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Uint8List> photo(String petId) async {
    final response = await _client.get(_url('$petId/photo'));
    if (response.statusCode != 200) _fail(response);
    return response.bodyBytes;
  }

  Future<void> delete(String petId) async {
    final response = await _client.delete(_url(petId));
    if (response.statusCode != 204) _fail(response);
  }

  Never _fail(http.Response response) {
    String message = 'Pet request failed (HTTP ${response.statusCode}).';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String) {
        message = body['error'] as String;
      }
    } catch (_) {}
    throw ApiException(message);
  }
}
