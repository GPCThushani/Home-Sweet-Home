import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as raw;
import 'package:http/testing.dart';
import 'package:mobile/core/services/api_client.dart';
import 'package:mobile/core/services/api_config.dart';
import 'package:mobile/features/home/screens/home_screen.dart';
import 'package:mobile/features/onboarding/screens/welcome_screen.dart';
import 'package:mobile/features/tasks/screens/global_tasks_screen.dart';
import 'package:mobile/features/tasks/services/task_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/shared/widgets/main_navigation_shell.dart';
import 'authenticated_http_test.dart' show token, login;

const family = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
const member = '33333333-3333-4333-8333-333333333333';
const person = '44444444-4444-4444-8444-444444444444';
const taskId = '55555555-5555-4555-8555-555555555555';
Map<String, dynamic> task({String household = family}) => {
  'id': taskId,
  'family': {'id': household},
  'title': 'A household task',
  'description': 'Details',
  'originModule': 'CHORES',
  'status': 'PENDING',
  'assignedTo': {'id': member},
  'dueDate': '2020-01-01T09:00:37.123Z',
};
List<Map<String, dynamic>> profiles() => [
  {
    'id': person,
    'name': 'Sam',
    'relationship': 'Parent',
    'hasAccount': true,
    'isSelf': true,
  },
];
Map<String, dynamic> membership() => {
  'id': member,
  'membershipId': member,
  'profileId': person,
  'familyId': family,
  'name': 'Sam',
  'email': 'member@example.test',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await login(token());
  });

  test(
    'API configuration covers web, Android emulator, and physical hosts',
    () {
      expect(ApiConfig.resolve(platform: 'web'), 'http://localhost:8080/api');
      expect(
        ApiConfig.resolve(platform: 'android'),
        'http://10.0.2.2:8080/api',
      );
      expect(
        ApiConfig.resolve(platform: 'windows'),
        'http://localhost:8080/api',
      );
      expect(
        ApiConfig.resolve(
          platform: 'android',
          override: 'https://household.example.test/api/',
        ),
        'https://household.example.test/api',
      );
      for (final value in [
        'localhost:8080/api',
        'ftp://example.test/api',
        'https://example.test',
        'https://user:password@example.test/api',
        'https://example.test/api?token=test',
      ]) {
        expect(
          () => ApiConfig.resolve(platform: 'web', override: value),
          throwsArgumentError,
        );
      }
    },
  );
  testWidgets('Dashboard loads the selected family, not the first family', (
    tester,
  ) async {
    final paths = <String>[];
    final client = ApiClient(
      inner: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/user')) {
          expect(
            request.url.queryParameters['email'],
            'member+alias@example.test',
          );
          return raw.Response(
            jsonEncode([
              {'id': other, 'name': 'Wrong household', 'inviteCode': 'WRONG'},
              {
                'id': family,
                'name': 'Selected household',
                'inviteCode': 'REAL-CODE',
                'memberCount': 99,
              },
            ]),
            200,
          );
        }
        expect(request.url.path, '/api/families/$family/profiles');
        return raw.Response(jsonEncode(profiles()), 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userEmail: 'member+alias@example.test',
          familyId: family,
          client: client,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Selected household'), findsOneWidget);
    expect(find.text('Wrong household'), findsNothing);
    expect(find.text('REAL-CODE'), findsOneWidget);
    expect(find.text('1 household members.'), findsOneWidget);
    expect(paths.length, 2);
    await tester.pumpWidget(const SizedBox());
    client.close();
  });
  testWidgets(
    'Dashboard does not fabricate missing codes or missing families',
    (tester) async {
      final client = ApiClient(
        inner: MockClient(
          (request) async => raw.Response(
            jsonEncode(
              request.url.path.endsWith('/user')
                  ? [
                      {'id': family, 'name': 'Selected household'},
                    ]
                  : profiles(),
            ),
            200,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userEmail: 'member@example.test',
            familyId: family,
            client: client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Invite code unavailable'), findsOneWidget);
      final copy = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == 'Copy Invite Code',
        ),
      );
      expect(copy.onPressed, isNull);
      expect(find.textContaining('DEMO'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      client.close();
    },
  );
  testWidgets(
    'late Dashboard responses cannot overwrite a newly selected family',
    (tester) async {
      final delayed = Completer<raw.Response>();
      var requests = 0;
      final client = ApiClient(
        inner: MockClient((request) async {
          if (request.url.path.endsWith('/user')) {
            requests++;
            if (requests == 1) return delayed.future;
            return raw.Response(
              jsonEncode([
                {'id': other, 'name': 'New household'},
              ]),
              200,
            );
          }
          return raw.Response(jsonEncode(profiles()), 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userEmail: 'member@example.test',
            familyId: family,
            client: client,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userEmail: 'member@example.test',
            familyId: other,
            client: client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      delayed.complete(
        raw.Response(
          jsonEncode([
            {'id': family, 'name': 'Old household'},
          ]),
          200,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('New household'), findsOneWidget);
      expect(find.text('Old household'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      client.close();
    },
  );
  testWidgets(
    'missing selected family shows an error instead of another household',
    (tester) async {
      final client = ApiClient(
        inner: MockClient(
          (_) async => raw.Response(
            jsonEncode([
              {'id': other, 'name': 'Wrong household', 'inviteCode': 'WRONG'},
            ]),
            200,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userEmail: 'member@example.test',
            familyId: family,
            client: client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('selected family is unavailable'),
        findsOneWidget,
      );
      expect(find.text('Wrong household'), findsNothing);
      expect(find.text('WRONG'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      client.close();
    },
  );
  testWidgets('standalone Tasks navigation keeps the selected household', (
    tester,
  ) async {
    final api = TaskApi(
      client: ApiClient(
        inner: MockClient(
          (request) async => raw.Response(
            jsonEncode(
              request.url.path.endsWith('/members') ? [membership()] : [task()],
            ),
            200,
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalTasksScreen(
          userEmail: 'member@example.test',
          familyId: family,
          api: api,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    final shell = tester.widget<MainNavigationShell>(
      find.byType(MainNavigationShell),
    );
    expect(shell.familyId, family);
    expect(shell.initialIndex, 0);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.close();
  });
  test(
    'Tasks use membership UUIDs, matching endpoints, JWT, and scoped responses',
    () async {
      final jwt = token();
      await login(jwt);
      final requests = <raw.Request>[];
      final client = ApiClient(
        inner: MockClient((request) async {
          requests.add(request);
          expect(request.headers['Authorization'], 'Bearer $jwt');
          if (request.url.path.endsWith('/members')) {
            return raw.Response(jsonEncode([membership()]), 200);
          }
          if (request.method == 'DELETE') return raw.Response('', 204);
          if (request.method == 'GET') {
            return raw.Response(jsonEncode([task()]), 200);
          }
          return raw.Response(
            jsonEncode(task()),
            request.method == 'POST' ? 201 : 200,
          );
        }),
      );
      final api = TaskApi(client: client);
      expect((await api.members(family)).single['id'], member);
      expect((await api.tasks(family)).single['id'], taskId);
      await api.save(family, {
        'title': 'Task',
        'originModule': 'CHORES',
        'assignedToMemberId': member,
        'dueDate': null,
      });
      await api.save(family, {
        'title': 'Updated',
        'originModule': 'CHORES',
        'assignedToMemberId': null,
        'dueDate': null,
      }, taskId: taskId);
      await api.complete(family, taskId);
      await api.delete(taskId);
      final create = jsonDecode(
        requests.firstWhere((r) => r.method == 'POST').body,
      );
      expect(create['assignedToMemberId'], member);
      expect(create['assignedToMemberId'], isNot(person));
      expect(create.containsKey('creatorMemberId'), isFalse);
      expect(requests.map((r) => r.method), [
        'GET',
        'GET',
        'POST',
        'PUT',
        'PUT',
        'DELETE',
      ]);
      api.close();
    },
  );
  test(
    'Tasks reject wrong-family records, invalid IDs and HTTP failures',
    () async {
      final client = ApiClient(
        inner: MockClient(
          (_) async => raw.Response(jsonEncode([task(household: other)]), 200),
        ),
      );
      final api = TaskApi(client: client);
      await expectLater(api.tasks(family), throwsFormatException);
      await expectLater(api.tasks('Family name'), throwsFormatException);
      api.close();
      final failed = TaskApi(
        client: ApiClient(
          inner: MockClient(
            (_) async => raw.Response('{"error":"Tasks unavailable"}', 503),
          ),
        ),
      );
      await expectLater(failed.tasks(family), throwsA(isA<ApiException>()));
      failed.close();
      expect(TaskApi.memberName(membership()), 'Sam');
      expect(TaskApi.memberName(null), 'Unassigned');
    },
  );
  testWidgets('Tasks show errors and retry instead of an empty success state', (
    tester,
  ) async {
    final api = TaskApi(
      client: ApiClient(
        inner: MockClient(
          (_) async => raw.Response('{"error":"Tasks unavailable"}', 503),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalTasksScreen(
          userEmail: 'member@example.test',
          familyId: family,
          api: api,
          embedded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tasks unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    await tester.pumpWidget(const SizedBox());
    api.close();
  });
  testWidgets('overdue tasks can open the date picker and be unassigned', (
    tester,
  ) async {
    final api = TaskApi(
      client: ApiClient(
        inner: MockClient((_) async => raw.Response(jsonEncode(task()), 200)),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditTaskBottomSheet(
            familyId: family,
            familyMembers: [membership()],
            task: task(),
            api: api,
            onTaskUpdated: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1/1/2020'));
    await tester.tap(find.text('1/1/2020'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    api.close();
  });
  testWidgets(
    'editing a task can clear assignment without changing its due instant',
    (tester) async {
      Map<String, dynamic>? sent;
      var saves = 0;
      final api = TaskApi(
        client: ApiClient(
          inner: MockClient((request) async {
            sent = Map<String, dynamic>.from(jsonDecode(request.body));
            return raw.Response(
              jsonEncode({...task(), 'assignedTo': null}),
              200,
            );
          }),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('Open editor'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => EditTaskBottomSheet(
                    familyId: family,
                    familyMembers: [membership()],
                    task: task(),
                    api: api,
                    onTaskUpdated: () {
                      saves++;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sam'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unassigned').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Update Task'));
      await tester.tap(find.text('Update Task'));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(sent!['assignedToMemberId'], isNull);
      expect(
        DateTime.parse(
          sent!['dueDate'],
        ).isAtSameMomentAs(DateTime.parse('2020-01-01T09:00:37.123Z')),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Clear due date'));
      await tester.tap(find.byTooltip('Clear due date'));
      await tester.ensureVisible(find.text('Update Task'));
      await tester.tap(find.text('Update Task'));
      await tester.pumpAndSettle();
      expect(saves, 2);
      expect(sent!['dueDate'], isNull);
      await tester.pumpWidget(const SizedBox());
      api.close();
    },
  );
  for (final size in [
    const Size(320, 200),
    const Size(568, 320),
    const Size(390, 844),
  ]) {
    testWidgets('welcome remains scrollable without overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.5),
            ),
            child: const WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Log In'));
      expect(find.text('Get Started'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
