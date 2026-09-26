import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../shared/models/health_data.dart';
import 'api_config.dart';

class HealthApi {

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

    return HealthProfile.fromJson(
      jsonDecode(response.body),
    );
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
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update health profile',
      );
    }

    return HealthProfile.fromJson(
      jsonDecode(response.body),
    );
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

    return jsonDecode(response.body);
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

    return jsonDecode(response.body);
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

    return jsonDecode(response.body);
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

    return jsonDecode(response.body);
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
      throw Exception(
        'Failed to load menstrual cycles',
      );
    }

    return jsonDecode(response.body);
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
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'startDate':
            startDate.toIso8601String().split('T').first,
        'endDate': endDate
            ?.toIso8601String()
            .split('T')
            .first,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to save menstrual cycle',
      );
    }
  }
}