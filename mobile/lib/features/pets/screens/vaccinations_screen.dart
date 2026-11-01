import 'package:flutter/material.dart';
import 'pet_record_screen.dart';

class VaccinationsScreen extends StatelessWidget {
  final String petId, familyId, petName;
  const VaccinationsScreen({
    super.key,
    required this.petId,
    required this.familyId,
    required this.petName,
  });
  @override
  Widget build(BuildContext context) => PetRecordScreen(
    petId: petId,
    familyId: familyId,
    petName: petName,
    section: 'VACCINATION',
  );
}
