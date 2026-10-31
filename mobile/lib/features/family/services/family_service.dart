import 'dart:convert';

import '../../../core/services/api_config.dart';
import '../../../core/services/authenticated_http.dart' as http;
import '../models/family_profile.dart';

class FamilyService {
  final http.AuthenticatedClient _client;
  FamilyService({http.AuthenticatedClient? client})
    : _client = client ?? http.AuthenticatedClient();

  void close() => _client.close();

  Map<String, dynamic> _object(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        decoded is Map && decoded['error'] is String
            ? decoded['error']
            : 'Family request failed (${response.statusCode}).',
      );
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  List<FamilyProfile> _profiles(dynamic decoded, String familyId) {
    if (decoded is! List) {
      throw const FormatException('Invalid family profile response.');
    }
    final seen = <String>{};
    return decoded.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      if (data['familyId'] != null &&
          FamilyProfile.uuid(data['familyId']) != familyId) {
        throw const FormatException('A profile belongs to another family.');
      }
      final profile = FamilyProfile.fromJson(data);
      if (!seen.add(profile.id)) {
        throw const FormatException('Duplicate profile IDs in response.');
      }
      return profile;
    }).toList();
  }

  Future<List<FamilyProfile>> getFamilyProfiles(String familyId) async {
    final id = FamilyProfile.uuid(familyId);
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/families/$id/profiles'),
    );
    if (response.statusCode != 200) {
      _object(response);
    }
    return _profiles(jsonDecode(response.body), id);
  }

  Future<FamilyInvitation> previewInvitation(String inviteCode) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/families/invitations/preview'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'inviteCode': inviteCode.trim()}),
    );
    final data = _object(response);
    final id = FamilyProfile.uuid(data['familyId']);
    return FamilyInvitation(
      familyId: id,
      familyName: data['familyName'] as String,
      profiles: _profiles(data['profiles'], id),
    );
  }

  Future<String> joinFamily({
    required String inviteCode,
    required String profileId,
    required String familyId,
    String? nickname,
  }) async {
    final selected = FamilyProfile.uuid(profileId);
    final expectedFamily = FamilyProfile.uuid(familyId);
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/families/join-by-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'inviteCode': inviteCode.trim(),
        'profileId': selected,
        'nickname': nickname,
      }),
    );
    final data = _object(response);
    final joinedFamily = FamilyProfile.uuid(data['familyId']);
    if (joinedFamily != expectedFamily ||
        FamilyProfile.uuid(data['profileId']) != selected) {
      throw const FormatException(
        'The server returned a different family or profile. Please refresh.',
      );
    }
    return joinedFamily;
  }

  Future<void> linkSelf(String familyId, String profileId) async {
    final family = FamilyProfile.uuid(familyId);
    final profile = FamilyProfile.uuid(profileId);
    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/families/$family/profiles/$profile/link-self',
      ),
    );
    if (FamilyProfile.uuid(_object(response)['profileId']) != profile) {
      throw const FormatException('The server returned a different profile.');
    }
  }
}
