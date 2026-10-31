import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as raw;
import 'package:http/testing.dart';
import 'package:mobile/core/services/auth_session.dart';
import 'package:mobile/core/services/authenticated_http.dart';
import 'package:mobile/features/family/models/family_profile.dart';
import 'package:mobile/features/family/services/family_service.dart';
import 'package:mobile/features/family/screens/family_screen.dart';
import 'package:mobile/features/onboarding/screens/join_family_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const creatorId = '22222222-2222-4222-8222-222222222222';
const motherId = '33333333-3333-4333-8333-333333333333';
const childId = '44444444-4444-4444-8444-444444444444';

Map<String, dynamic> person(
  String id,
  String name,
  String role, {
  bool account = false,
  bool self = false,
}) => {
  'id': id,
  'profileId': id,
  'familyId': familyId,
  'name': name,
  'role': role,
  'relationship': role,
  'gender': 'Female',
  'hasAccount': account,
  'isSelf': self,
};

raw.Response response(Object body, [int status = 200]) => raw.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

FamilyService service(Future<raw.Response> Function(raw.Request) handler) =>
    FamilyService(client: AuthenticatedClient(inner: MockClient(handler)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final jwt =
        '${part({'alg': 'HS256'})}.${part({'sub': 'member@example.test', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.test-signature';
    SharedPreferences.setMockInitialValues({'jwt_token': jwt});
    AuthSession.onAuthenticationRequired = null;
  });

  test(
    'loads registered and unregistered people with their profile UUIDs',
    () async {
      final api = service((request) async {
        expect(request.headers['Authorization'], startsWith('Bearer '));
        expect(request.url.path, '/api/families/$familyId/profiles');
        return response([
          person(creatorId, 'Alex', 'Father', account: true, self: true),
          person(motherId, 'Sam', 'Mother'),
          person(childId, 'Robin', 'Daughter'),
        ]);
      });
      addTearDown(api.close);
      final profiles = await api.getFamilyProfiles(familyId);
      expect(profiles.map((p) => p.id), [creatorId, motherId, childId]);
      expect(profiles.map((p) => p.hasAccount), [true, false, false]);
      expect(profiles[1].relationship, 'Mother');
    },
  );

  test(
    'rejects names, missing UUIDs, mismatched IDs and duplicate response profiles',
    () async {
      for (final invalid in [
        <String, dynamic>{...person(motherId, 'Sam', 'Mother'), 'id': 'Sam'},
        <String, dynamic>{
          ...person(motherId, 'Sam', 'Mother'),
          'profileId': creatorId,
        },
      ]) {
        expect(() => FamilyProfile.fromJson(invalid), throwsFormatException);
      }
      final api = service(
        (_) async => response([
          person(motherId, 'Sam', 'Mother'),
          person(motherId, 'Sam', 'Mother'),
        ]),
      );
      addTearDown(api.close);
      await expectLater(api.getFamilyProfiles(familyId), throwsFormatException);
    },
  );

  test(
    'preview and join send the selected UUID without a client user or system role',
    () async {
      var calls = 0;
      final api = service((request) async {
        final body = jsonDecode(request.body) as Map;
        expect(body['inviteCode'], 'HSH-TEST');
        expect(request.headers['Authorization'], startsWith('Bearer '));
        if (calls++ == 0) {
          expect(request.url.path, '/api/families/invitations/preview');
          return response({
            'familyId': familyId,
            'familyName': 'Test family',
            'profiles': [person(motherId, 'Sam', 'Mother')],
          });
        }
        expect(request.url.path, '/api/families/join-by-code');
        expect(body['profileId'], motherId);
        expect(body.containsKey('userId'), false);
        expect(body.containsKey('role'), false);
        return response({
          'familyId': familyId,
          'profileId': motherId,
          'membershipId': creatorId,
        });
      });
      addTearDown(api.close);
      final invitation = await api.previewInvitation(' HSH-TEST ');
      expect(invitation.profiles.single.id, motherId);
      expect(
        await api.joinFamily(
          inviteCode: 'HSH-TEST',
          profileId: motherId,
          familyId: familyId,
        ),
        familyId,
      );
    },
  );

  test('does not accept a join response for a different profile', () async {
    final api = service(
      (_) async => response({'familyId': familyId, 'profileId': childId}),
    );
    addTearDown(api.close);
    await expectLater(
      api.joinFamily(
        inviteCode: 'HSH-TEST',
        profileId: motherId,
        familyId: familyId,
      ),
      throwsFormatException,
    );
  });

  test(
    'link-self uses the selected profile path and reports conflicts',
    () async {
      final api = service((request) async {
        expect(
          request.url.path,
          '/api/families/$familyId/profiles/$motherId/link-self',
        );
        return response({
          'error': 'This profile is linked to another account',
        }, 409);
      });
      addTearDown(api.close);
      await expectLater(
        api.linkSelf(familyId, motherId),
        throwsA(
          predicate((e) => e.toString().contains('linked to another account')),
        ),
      );
    },
  );

  testWidgets(
    'Family renders the full roster and existing members can link themselves',
    (tester) async {
      var linked = false;
      var requests = 0;
      final api = service((request) async {
        requests++;
        if (request.method == 'POST') {
          expect(
            request.url.path,
            '/api/families/$familyId/profiles/$motherId/link-self',
          );
          linked = true;
          return response({'profileId': motherId});
        }
        return response([
          person(creatorId, 'Alex', 'Father', account: true),
          person(motherId, 'Sam', 'Mother', account: linked, self: linked),
          person(childId, 'Robin', 'Daughter'),
        ]);
      });
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: FamilyScreen(
            userEmail: 'member@example.test',
            familyId: familyId,
            familyService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3 Family Members'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Robin'), findsOneWidget);
      expect(find.text('Not joined yet'), findsNWidgets(2));
      final link = find.byTooltip('This is me - link my account').first;
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Link my account'));
      await tester.pumpAndSettle();
      expect(linked, true);
      expect(requests, 3);
      expect(find.text('Account linked (you)'), findsOneWidget);
      expect(find.text('Not joined yet'), findsOneWidget);
    },
  );

  testWidgets(
    'join requires explicit selection when several household profiles are available',
    (tester) async {
      String? submitted;
      final api = service((request) async {
        if (request.url.path.endsWith('/preview')) {
          return response({
            'familyId': familyId,
            'familyName': 'Test family',
            'profiles': [
              person(motherId, 'Sam', 'Mother'),
              person(childId, 'Robin', 'Daughter'),
            ],
          });
        }
        submitted = (jsonDecode(request.body) as Map)['profileId'] as String?;
        return response({
          'error': 'This profile is linked to another account',
        }, 409);
      });
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JoinFamilyBottomSheet(
              userEmail: 'member@example.test',
              familyService: api,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'HSH-TEST');
      await tester.tap(find.text('Find Family'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Join Family Space'));
      await tester.pumpAndSettle();
      expect(submitted, isNull);
      expect(
        find.text('Select your existing household profile.'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Robin - Daughter').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Join Family Space'));
      await tester.pumpAndSettle();
      expect(submitted, childId);
      expect(
        find.text('This profile is linked to another account'),
        findsOneWidget,
      );
    },
  );
}
