import 'package:mobile/core/services/api_config.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as raw;
import 'package:http/testing.dart';
import 'package:mobile/core/services/health_http.dart';
import 'package:mobile/core/services/health_api.dart';
import 'package:mobile/features/health/screens/health_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authenticated_http_test.dart' show token, login;

const family = '11111111-1111-4111-8111-111111111111';
const parent = '22222222-2222-4222-8222-222222222222';
const child = '33333333-3333-4333-8333-333333333333';
Uri health(String type, [String id = parent]) =>
    Uri.parse('${ApiConfig.baseUrl}/health/$type/$family/$id');
Map<String, dynamic> profile(String id, String allergy) => {
  'familyId': family,
  'familyMemberId': id,
  'allergies': allergy,
  'womensHealthEnabled': false,
  'emergencyAccessEnabled': true,
};
final roster = [
  {
    'id': parent,
    'profileId': parent,
    'name': 'Parent',
    'relationship': 'Mother',
    'gender': 'Female',
    'hasAccount': true,
    'isSelf': true,
  },
  {
    'id': child,
    'profileId': child,
    'name': 'Child',
    'relationship': 'Son',
    'gender': 'Male',
    'hasAccount': false,
    'isSelf': false,
  },
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await login(token());
  });
  test('Health API rejects malformed or mismatched response scopes', () {
    expect(HealthApi.decodeProfile(jsonEncode(profile(parent, 'Saved')), family, parent)['allergies'], 'Saved');
    expect(HealthApi.decodeList('[]', family, parent), isEmpty);
    for (final body in ['{}', '[]', jsonEncode(profile(child, 'Other'))]) {
      expect(() => HealthApi.decodeProfile(body, family, parent), throwsFormatException);
    }
    for (final body in ['{}', '[null]', jsonEncode([profile(child, 'Other')])]) {
      expect(() => HealthApi.decodeList(body, family, parent), throwsFormatException);
    }
  });
  test(
    'every HTTP error propagates instead of becoming empty health data',
    () async {
      for (final status in [400, 404, 409, 413, 500, 503]) {
        final client = HealthClient(
          inner: MockClient(
            (_) async =>
                raw.Response('{"error":"Health operation rejected"}', status),
          ),
        );
        await expectLater(
          client.get(health('profile')),
          throwsA(
            isA<HealthApiException>().having(
              (e) => e.message,
              'message',
              'Health operation rejected',
            ),
          ),
        );
        client.close();
      }
    },
  );
  test('invalid profile identifiers never reach the network', () async {
    var requests = 0;
    final client = HealthClient(
      inner: MockClient((_) async {
        requests++;
        return raw.Response('{}', 200);
      }),
    );
    for (final id in ['', 'Mother', 'null', 'not-a-uuid']) {
      await expectLater(
        client.get(health('profile', id)),
        throwsA(isA<HealthApiException>()),
      );
    }
    expect(requests, 0);
    client.close();
  });
  test(
    'multipart and download requests carry JWT and retain file bytes',
    () async {
      final jwt = token();
      await login(jwt);
      final requests = <String>[];
      final client = HealthClient(
        inner: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer $jwt');
          requests.add(request.method);
          return request.method == 'POST'
              ? raw.Response('{"id":1}', 200)
              : raw.Response.bytes([37, 80, 68, 70, 45], 200);
        }),
      );
      await client.upload(
        MultipartRequest('POST', Uri.parse('${health('documents')}/upload'))
          ..fields['title'] = 'Report'
          ..files.add(
            MultipartFile.fromBytes('file', [
              37,
              80,
              68,
              70,
              45,
            ], filename: 'report.pdf'),
          ),
      );
      final downloaded = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/health/documents/1/file'),
      );
      expect(downloaded.bodyBytes, [37, 80, 68, 70, 45]);
      expect(requests, ['POST', 'GET']);
      client.close();
    },
  );
  test(
    'expired server sessions clear authentication; forbidden preserves it',
    () async {
      final forbidden = HealthClient(
        inner: MockClient((_) async => raw.Response('', 403)),
      );
      await expectLater(
        forbidden.get(health('profile')),
        throwsA(isA<AuthorizationException>()),
      );
      expect(
        (await SharedPreferences.getInstance()).getString('jwt_token'),
        isNotNull,
      );
      final expired = HealthClient(
        inner: MockClient((_) async => raw.Response('', 401)),
      );
      await expectLater(
        expired.get(health('profile')),
        throwsA(isA<AuthenticationException>()),
      );
      expect(
        (await SharedPreferences.getInstance()).getString('jwt_token'),
        isNull,
      );
      forbidden.close();
      expired.close();
    },
  );
  testWidgets('roster errors show retry, never local membership fallbacks', (
    tester,
  ) async {
    final client = HealthClient(
      inner: MockClient(
        (_) async => raw.Response('{"error":"Profiles unavailable"}', 503),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HealthScreen(
          userEmail: 'member@example.test',
          familyId: family,
          client: client,
          initialFamilyMembers: const [
            {'id': 'membership-id', 'name': 'Fallback'},
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Profiles unavailable'), findsOneWidget);
    expect(find.text('Fallback'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    client.close();
  });
  testWidgets(
    'registered and unregistered profiles switch independently; stale loads cannot overwrite',
    (tester) async {
      final delayed = Completer<raw.Response>();
      final paths = <String>[];
      final client = HealthClient(
        inner: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/profiles')) {
            return raw.Response(jsonEncode(roster), 200);
          }
          if (request.url.path.contains('/profile/')) {
            if (request.url.path.endsWith(parent)) return delayed.future;
            return raw.Response(
              jsonEncode(profile(child, 'Child allergy')),
              200,
            );
          }
          return raw.Response('[]', 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HealthScreen(
            userEmail: 'member@example.test',
            familyId: family,
            client: client,
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(find.text('Child'), findsOneWidget);
      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      expect(find.text('Child allergy'), findsWidgets);
      delayed.complete(
        raw.Response(jsonEncode(profile(parent, 'Parent allergy')), 200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Parent allergy'), findsNothing);
      expect(find.text('Child allergy'), findsWidgets);
      expect(paths.any((path) => path.contains('/members')), isFalse);
      expect(paths.any((path) => path.endsWith(child)), isTrue);
      await tester.pumpWidget(const SizedBox());
      client.close();
    },
  );
}
