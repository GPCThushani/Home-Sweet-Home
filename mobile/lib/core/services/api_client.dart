import 'dart:convert';
import 'package:http/http.dart' as raw;
import 'authenticated_http.dart';
export 'authenticated_http.dart'
    show AuthenticationException, AuthorizationException;

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

/// Checked transport for Dashboard and Tasks. Authentication stays centralized.
class ApiClient extends raw.BaseClient {
  final AuthenticatedClient _authenticated;
  ApiClient({raw.Client? inner})
    : _authenticated = AuthenticatedClient(inner: inner);

  @override
  Future<raw.StreamedResponse> send(raw.BaseRequest request) async {
    final response = await _authenticated.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await raw.Response.fromStream(response);
      String message =
          'Request failed (HTTP ${response.statusCode}). Please try again.';
      try {
        final decoded = jsonDecode(body.body);
        if (decoded is Map && decoded['error'] is String) {
          message = decoded['error'];
        }
      } catch (_) {
        /* Keep the status for non-JSON errors. */
      }
      throw ApiException(message);
    }
    return response;
  }

  @override
  void close() => _authenticated.close();
}
