import 'package:mobile/core/services/api_config.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/services/auth_session.dart';
import 'package:mobile/core/services/authenticated_http.dart';
import 'package:shared_preferences/shared_preferences.dart';

String token({int seconds = 3600}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': 'member@example.test', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + seconds})}.test-signature';
}

Future<void> login(String jwt) => AuthSession.save({
  'token': jwt,
  'userId': 'test-user-id',
  'email': 'member@example.test',
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final protected = Uri.parse(
    '${ApiConfig.baseUrl}/health/medicines/family/person',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthSession.onAuthenticationRequired = null;
  });

  test(
    'rejects fabricated, empty, malformed, and expired sessions without storing them',
    () async {
      for (final invalid in [
        '',
        'fabricated-token',
        'a.b.c',
        token(seconds: -60),
      ]) {
        await expectLater(
          login(invalid),
          throwsA(isA<AuthenticationException>()),
        );
        expect(
          (await SharedPreferences.getInstance()).getString('jwt_token'),
          isNull,
        );
      }
    },
  );

  test(
    'adds the stored Bearer token to every protected request method',
    () async {
      final jwt = token();
      await login(jwt);
      final methods = <String>[];
      final client = AuthenticatedClient(
        inner: MockClient((request) async {
          methods.add(request.method);
          expect(request.headers['Authorization'], 'Bearer $jwt');
          expect(request.followRedirects, isFalse);
          return http.Response('{}', 200);
        }),
      );
      addTearDown(client.close);
      await client.get(protected);
      await client.post(
        protected,
        headers: {'Authorization': 'Bearer stale'},
        body: '{}',
      );
      await client.put(protected, body: '{}');
      await client.delete(protected);
      expect(methods, ['GET', 'POST', 'PUT', 'DELETE']);
    },
  );

  test('login and registration do not send stale credentials', () async {
    SharedPreferences.setMockInitialValues({'jwt_token': 'expired-value'});
    final client = AuthenticatedClient(
      inner: MockClient((request) async {
        expect(request.headers['Authorization'], isNull);
        return http.Response('{}', 401);
      }),
    );
    addTearDown(client.close);
    for (final endpoint in ['login', 'register']) {
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/users/$endpoint'),
        headers: {'Authorization': 'Bearer stale'},
      );
      expect(response.statusCode, 401);
    }
  });

  test('missing and expired sessions never send protected requests', () async {
    var sent = false;
    final client = AuthenticatedClient(
      inner: MockClient((_) async {
        sent = true;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);
    await expectLater(
      client.get(protected),
      throwsA(isA<AuthenticationException>()),
    );
    SharedPreferences.setMockInitialValues({'jwt_token': token(seconds: -60)});
    await expectLater(
      client.get(protected),
      throwsA(isA<AuthenticationException>()),
    );
    expect(sent, isFalse);
  });

  test(
    '401 invalidates the session and requests login once for concurrent failures',
    () async {
      await login(token());
      var notifications = 0;
      AuthSession.onAuthenticationRequired = (_) => notifications++;
      final client = AuthenticatedClient(
        inner: MockClient((_) async => http.Response('{}', 401)),
      );
      addTearDown(client.close);
      final results = List.generate(
        3,
        (_) => expectLater(
          client.get(protected),
          throwsA(isA<AuthenticationException>()),
        ),
      );
      await Future.wait(results);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jwt_token'), isNull);
      expect(prefs.getString('user_id'), isNull);
      expect(prefs.getString('user_email'), isNull);
      expect(notifications, 1);
    },
  );

  test(
    '403 preserves a valid session and reports authorization failure',
    () async {
      final jwt = token();
      await login(jwt);
      final client = AuthenticatedClient(
        inner: MockClient((_) async => http.Response('{}', 403)),
      );
      addTearDown(client.close);
      await expectLater(
        client.get(protected),
        throwsA(isA<AuthorizationException>()),
      );
      expect(
        (await SharedPreferences.getInstance()).getString('jwt_token'),
        jwt,
      );
    },
  );

  test('a rejected older request cannot erase a newer login', () async {
    await login(token(seconds: 600));
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final client = AuthenticatedClient(
      inner: MockClient((_) {
        started.complete();
        return pending.future;
      }),
    );
    addTearDown(client.close);
    final result = expectLater(
      client.get(protected),
      throwsA(isA<AuthenticationException>()),
    );
    await started.future;
    final newer = token(seconds: 3600);
    await login(newer);
    pending.complete(http.Response('{}', 401));
    await result;
    expect(
      (await SharedPreferences.getInstance()).getString('jwt_token'),
      newer,
    );
  });

  test('does not attach the stored token to another origin', () async {
    await login(token());
    final client = AuthenticatedClient(
      inner: MockClient((request) async {
        expect(request.headers['Authorization'], isNull);
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);
    await client.get(Uri.parse('https://example.test/api/health'));
  });

  test('multipart uploads also receive the stored token', () async {
    final jwt = token();
    await login(jwt);
    final client = AuthenticatedClient(
      inner: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer $jwt');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/together/memories/family/photo'),
    );
    request.files.add(http.MultipartFile.fromString('file', 'test'));
    await http.Response.fromStream(await client.send(request));
  });
}
