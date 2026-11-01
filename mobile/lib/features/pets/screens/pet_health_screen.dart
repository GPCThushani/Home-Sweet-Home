import 'package:flutter/material.dart';
import 'pet_record_screen.dart';

class PetHealthScreen extends StatelessWidget {
  final String petId, familyId, petName;
  const PetHealthScreen({
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
    section: 'HEALTH',
  );
}
