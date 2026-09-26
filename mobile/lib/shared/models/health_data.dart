class HealthProfile {
  final String familyId;
  final String familyMemberId;

  String? dateOfBirth;
  String? bloodType;

  double? heightCm;
  double? weightKg;

  String? allergies;
  String? knownConditions;
  String? previousSurgeries;
  String? previousHospitalizations;
  String? specialMedicalNotes;

  String? primaryPhysicianName;
  String? primaryPhysicianPhone;
  String? hospitalOrClinic;

  String? insuranceProvider;
  String? insurancePolicyNumber;
  String? insuranceExpiryDate;

  String? emergencyContactName;
  String? emergencyContactRelationship;
  String? emergencyContactPhone;

  bool womensHealthEnabled;
  bool emergencyAccessEnabled;
  bool familyHealthSummaryVisible;

  HealthProfile({
    required this.familyId,
    required this.familyMemberId,
    this.dateOfBirth,
    this.bloodType,
    this.heightCm,
    this.weightKg,
    this.allergies,
    this.knownConditions,
    this.previousSurgeries,
    this.previousHospitalizations,
    this.specialMedicalNotes,
    this.primaryPhysicianName,
    this.primaryPhysicianPhone,
    this.hospitalOrClinic,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.insuranceExpiryDate,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.womensHealthEnabled = false,
    this.emergencyAccessEnabled = true,
    this.familyHealthSummaryVisible = true,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      familyId: json['familyId'] ?? '',
      familyMemberId: json['familyMemberId'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      bloodType: json['bloodType'],
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      allergies: json['allergies'],
      knownConditions: json['knownConditions'],
      previousSurgeries: json['previousSurgeries'],
      previousHospitalizations: json['previousHospitalizations'],
      specialMedicalNotes: json['specialMedicalNotes'],
      primaryPhysicianName: json['primaryPhysicianName'],
      primaryPhysicianPhone: json['primaryPhysicianPhone'],
      hospitalOrClinic: json['hospitalOrClinic'],
      insuranceProvider: json['insuranceProvider'],
      insurancePolicyNumber: json['insurancePolicyNumber'],
      insuranceExpiryDate: json['insuranceExpiryDate'],
      emergencyContactName: json['emergencyContactName'],
      emergencyContactRelationship: json['emergencyContactRelationship'],
      emergencyContactPhone: json['emergencyContactPhone'],
      womensHealthEnabled: json['womensHealthEnabled'] ?? false,
      emergencyAccessEnabled: json['emergencyAccessEnabled'] ?? true,
      familyHealthSummaryVisible: json['familyHealthSummaryVisible'] ?? true,
    ); // <--- Added missing closing parenthesis and semicolon
  } // <--- Added missing closing brace for fromJson

  Map<String, dynamic> toJson() {
    return {
      'familyId': familyId,
      'familyMemberId': familyMemberId,
      'dateOfBirth': dateOfBirth,
      'bloodType': bloodType,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'allergies': allergies,
      'knownConditions': knownConditions,
      'previousSurgeries': previousSurgeries,
      'previousHospitalizations': previousHospitalizations,
      'specialMedicalNotes': specialMedicalNotes,
      'primaryPhysicianName': primaryPhysicianName,
      'primaryPhysicianPhone': primaryPhysicianPhone,
      'hospitalOrClinic': hospitalOrClinic,
      'insuranceProvider': insuranceProvider,
      'insurancePolicyNumber': insurancePolicyNumber,
      'insuranceExpiryDate': insuranceExpiryDate,
      'emergencyContactName': emergencyContactName,
      'emergencyContactRelationship': emergencyContactRelationship,
      'emergencyContactPhone': emergencyContactPhone,
      'womensHealthEnabled': womensHealthEnabled,
      'emergencyAccessEnabled': emergencyAccessEnabled,
      'familyHealthSummaryVisible': familyHealthSummaryVisible,
    };
  }
}