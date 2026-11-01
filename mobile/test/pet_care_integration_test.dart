import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/services/api_client.dart';
import 'package:mobile/features/pets/services/pet_care_api.dart';
import 'package:mobile/features/pets/screens/pet_documents_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'authenticated_http_test.dart' show login, token;

const petId = '11111111-1111-4111-8111-111111111111';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await login(token());
  });

  test(
    'pet records and document requests use authenticated endpoints',
    () async {
      final paths = <String>[];
      final client = PetCareApi(
        client: ApiClient(
          inner: MockClient((request) async {
            expect(request.headers['Authorization'], 'Bearer ${token()}');
            paths.add('${request.method} ${request.url.path}');
            if (request.url.path.endsWith('/entries/HEALTH')) {
              return http.Response(
                '[{"id":"record-1","title":"Allergy"}]',
                200,
              );
            }
            if (request.url.path.endsWith('/documents') &&
                request.method == 'POST') {
              expect(
                request.headers['content-type'] ??
                    request.headers['Content-Type'],
                contains('multipart/form-data'),
              );
              expect(
                request.bodyBytes,
                contains(37),
              ); // PDF signature starts with %.
              return http.Response('{"id":"document-1"}', 201);
            }
            if (request.url.path.endsWith('/documents/document-1/file')) {
              return http.Response.bytes(
                Uint8List.fromList([37, 80, 68, 70]),
                200,
              );
            }
            if (request.method == 'DELETE') return http.Response('', 204);
            return http.Response('[]', 200);
          }),
        ),
      );
      expect(
        (await client.entries(petId, 'HEALTH')).single['title'],
        'Allergy',
      );
      expect(
        (await client.uploadDocument(
          petId,
          bytes: Uint8List.fromList(utf8.encode('%PDF-test')),
          fileName: 'test.pdf',
          title: 'Test',
          category: 'Other',
        ))['id'],
        'document-1',
      );
      expect(await client.documentBytes(petId, 'document-1'), [37, 80, 68, 70]);
      await client.deleteDocument(petId, 'document-1');
      expect(paths, [
        'GET /api/pets/$petId/entries/HEALTH',
        'POST /api/pets/$petId/documents',
        'GET /api/pets/$petId/documents/document-1/file',
        'DELETE /api/pets/$petId/documents/document-1',
      ]);
      client.close();
    },
  );

  test('pet API reports server errors instead of empty records', () async {
    final client = PetCareApi(
      client: ApiClient(
        inner: MockClient(
          (request) async =>
              http.Response('{"error":"Storage unavailable"}', 503),
        ),
      ),
    );
    await expectLater(client.documents(petId), throwsA(isA<ApiException>()));
    client.close();
  });

  test('pet documents search and category filter combine correctly', () {
    final documents = <Map<String, dynamic>>[
      {
        'title': 'Rabies certificate',
        'fileName': 'rabies.pdf',
        'category': 'Vaccination Certificates',
      },
      {
        'title': 'Insurance',
        'fileName': 'policy.pdf',
        'category': 'Insurance Documents',
      },
    ];
    expect(filterPetDocuments(documents, query: 'RABIES').length, 1);
    expect(
      filterPetDocuments(documents, query: 'policy').single['title'],
      'Insurance',
    );
    expect(
      filterPetDocuments(
        documents,
        query: 'rabies',
        category: 'Insurance Documents',
      ),
      isEmpty,
    );
    expect(
      filterPetDocuments(
        documents,
        category: 'Vaccination Certificates',
      ).single['title'],
      'Rabies certificate',
    );
  });
}
