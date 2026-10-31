import 'dart:convert';

import 'package:http/http.dart' as raw;

import 'api_config.dart';
import 'auth_session.dart';

export 'package:http/http.dart' show Response, MultipartRequest, MultipartFile;
export 'auth_session.dart' show AuthenticationException, AuthorizationException;

class AuthenticatedClient extends raw.BaseClient {
  final raw.Client _inner;
  AuthenticatedClient({raw.Client? inner}) : _inner = inner ?? raw.Client();

  @override
  Future<raw.StreamedResponse> send(raw.BaseRequest request) async {
    final api = Uri.parse(ApiConfig.baseUrl);
    final isApi =
        request.url.origin == api.origin &&
        request.url.normalizePath().path.startsWith('${api.path}/');
    final isPublic =
        request.method == 'POST' &&
        (request.url.path == '${api.path}/users/login' ||
            request.url.path == '${api.path}/users/register');
    String? token;
    if (isApi) {
      request.headers.removeWhere(
        (key, _) => key.toLowerCase() == 'authorization',
      );
      if (!isPublic) {
        token = await AuthSession.requireToken();
        request.headers['Authorization'] = 'Bearer $token';
        // Never forward credentials to another origin through a redirect.
        request.followRedirects = false;
      }
    }
    final response = await _inner.send(request);
    if (isApi &&
        !isPublic &&
        (response.statusCode == 401 || response.statusCode == 403)) {
      await response.stream.drain<void>();
      if (response.statusCode == 401) {
        await AuthSession.invalidate(token);
        throw const AuthenticationException();
      }
      throw const AuthorizationException();
    }
    return response;
  }

  @override
  void close() => _inner.close();
}

final _client = AuthenticatedClient();

Future<raw.Response> get(Uri url, {Map<String, String>? headers}) =>
    _client.get(url, headers: headers);
Future<raw.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _client.post(url, headers: headers, body: body, encoding: encoding);
Future<raw.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _client.put(url, headers: headers, body: body, encoding: encoding);
Future<raw.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _client.delete(url, headers: headers, body: body, encoding: encoding);
Future<raw.StreamedResponse> send(raw.BaseRequest request) =>
    _client.send(request);
