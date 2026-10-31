import 'dart:convert';

import 'package:mobile/core/services/health_http.dart' as http;

import '../../shared/models/health_data.dart';
import 'api_config.dart';

class HealthApi {
  static void verifyScope(Map value, String familyId, String memberId) {
    if (value['familyId'] != familyId || value['familyMemberId'] != memberId) {
      throw const FormatException('Health response belongs to a different household profile');
    }
  }
  static Map<String, dynamic> decodeProfile(String body, String familyId, String memberId) {
    final value = jsonDecode(body);
    if (value is! Map<String, dynamic>) throw const FormatException('Invalid health profile response');
    verifyScope(value, familyId, memberId);
    return value;
  }
  static List<dynamic> decodeList(String body, String familyId, String memberId) {
    final value = jsonDecode(body);
    if (value is! List) throw const FormatException('Invalid health list response');
    for (final row in value) {
      if (row is! Map) throw const FormatException('Invalid health record');
      verifyScope(row, familyId, memberId);
    }
    return value;
  }

  static Future<HealthProfile> getProfile({
    required String familyId,
    required String memberId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/health/profile/'
        '$familyId/$memberId',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load health profile: '
        '${response.statusCode}',
      );
    }

    return HealthProfile.fromJson(decodeProfile(response.body, familyId, memberId));
  }

  static Future<HealthProfile> updateProfile({
    required String familyId,
    required String memberId,
    required HealthProfile profile,
  }) async {
    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/health/profile/'
        '$familyId/$memberId',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update health profile');
    }

    return HealthProfile.fromJson(decodeProfile(response.body, familyId, memberId));
  }

  static Future<List<dynamic>> getMedicines({
    required String familyId,
    required String memberId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/health/medicines/'
        '$familyId/$memberId',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load medicines');
    }

    return decodeList(response.body, familyId, memberId);
  }

  static Future<List<dynamic>> getAppointments({
    required String familyId,
    required String memberId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/health/appointments/'
        '$familyId/$memberId',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load appointments');
    }

    return decodeList(response.body, familyId, memberId);
  }

  static Future<List<dynamic>> getRecords({
    required String familyId,
    required String memberId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/health/records/'
        '$familyId/$memberId',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load records');
    }

    return decodeList(response.body, familyId, memberId);
  }

  static Future<List<dynamic>> getDocuments({
    required String familyId,
    required String memberId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/health/documents/'
        '$familyId/$memberId',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load documents');
    }

    return decodeList(response.body, familyId, memberId);
  }

  static Future<List<dynamic>> getCycles({
    required String familyId,
    required String memberId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/health/womens-health/'
        'cycles/$familyId/$memberId',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load menstrual cycles');
    }

    return decodeList(response.body, familyId, memberId);
  }

  static Future<void> addCycle({
    required String familyId,
    required String memberId,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/health/womens-health/'
        'cycles/$familyId/$memberId',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'startDate': startDate.toIso8601String().split('T').first,
        'endDate': endDate?.toIso8601String().split('T').first,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save menstrual cycle');
    }
  }
}
