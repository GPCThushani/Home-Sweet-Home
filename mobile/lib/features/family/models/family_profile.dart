class FamilyProfile {
  final String id;
  final String name;
  final String relationship;
  final String? gender;
  final bool hasAccount;
  final bool isSelf;

  const FamilyProfile({
    required this.id,
    required this.name,
    required this.relationship,
    this.gender,
    required this.hasAccount,
    required this.isSelf,
  });

  static String uuid(Object? value) {
    if (value is! String ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(value)) {
      throw const FormatException(
        'The server returned an invalid family profile identifier.',
      );
    }
    return value.toLowerCase();
  }

  factory FamilyProfile.fromJson(Map<String, dynamic> json) {
    final id = uuid(json['id']);
    if (json['profileId'] != null && uuid(json['profileId']) != id) {
      throw const FormatException(
        'The server returned conflicting profile identifiers.',
      );
    }
    final name = json['name'];
    final relationship = json['relationship'] ?? json['role'];
    if (name is! String ||
        name.trim().isEmpty ||
        relationship is! String ||
        relationship.trim().isEmpty ||
        json['hasAccount'] is! bool ||
        json['isSelf'] is! bool) {
      throw const FormatException(
        'The server returned an incomplete family profile.',
      );
    }
    return FamilyProfile(
      id: id,
      name: name,
      relationship: relationship,
      gender: json['gender'] as String?,
      hasAccount: json['hasAccount'] as bool,
      isSelf: json['isSelf'] as bool,
    );
  }
}

class FamilyInvitation {
  final String familyId;
  final String familyName;
  final List<FamilyProfile> profiles;

  const FamilyInvitation({
    required this.familyId,
    required this.familyName,
    required this.profiles,
  });
}
