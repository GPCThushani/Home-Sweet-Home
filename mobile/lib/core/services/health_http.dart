import 'dart:convert';
import 'package:http/http.dart' as raw;
import 'authenticated_http.dart' as authenticated;
export 'authenticated_http.dart'
    show
        Response,
        MultipartRequest,
        MultipartFile,
        AuthenticationException,
        AuthorizationException;

Future<authenticated.Response> checked(
  Future<authenticated.Response> request,
) async {
  final response = await request;
  if (response.statusCode < 200 || response.statusCode >= 300) {
    String message =
        'Health request failed (HTTP ${response.statusCode}). Please try again.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String) message = body['error'];
    } catch (_) {
      /* A non-JSON error still retains its HTTP status. */
    }
    throw HealthApiException(message);
  }
  return response;
}

class HealthApiException implements Exception {
  final String message;
  const HealthApiException(this.message);
  @override
  String toString() => message;
}

/// A checked, authenticated transport shared by all Health callers.
class HealthClient extends raw.BaseClient {
  final authenticated.AuthenticatedClient _authenticated;
  HealthClient({raw.Client? inner})
    : _authenticated = authenticated.AuthenticatedClient(inner: inner);

  static void validateUrl(Uri url) {
    final match = RegExp(
      r'^/api/health/(profile|medicines(?:/logs)?|appointments|records|documents|womens-health/(?:cycles|entries))/([^/]*)/([^/]*)(?:/upload)?$',
    ).firstMatch(url.path);
    if (match == null ||
        (match[1] == 'medicines' && match[3] == 'schedules') ||
        (match[1] == 'documents' && match[3] == 'file')) {
      return;
    }
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    );
    if (!uuid.hasMatch(match[2]!) || !uuid.hasMatch(match[3]!)) {
      throw const HealthApiException(
        'Select a valid household profile before loading health information.',
      );
    }
  }

  @override
  Future<raw.StreamedResponse> send(raw.BaseRequest request) async {
    validateUrl(request.url);
    final response = await _authenticated.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await checked(raw.Response.fromStream(response));
    }
    return response;
  }

  Future<raw.Response> upload(raw.MultipartRequest request) =>
      send(request).then(raw.Response.fromStream);

  @override
  void close() => _authenticated.close();
}

final _client = HealthClient();
Future<authenticated.Response> get(Uri url, {Map<String, String>? headers}) =>
    _client.get(url, headers: headers);
Future<authenticated.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _client.post(url, headers: headers, body: body, encoding: encoding);
Future<authenticated.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _client.put(url, headers: headers, body: body, encoding: encoding);
Future<authenticated.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _client.delete(url, headers: headers, body: body, encoding: encoding);
