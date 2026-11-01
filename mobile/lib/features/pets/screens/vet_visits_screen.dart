import 'package:flutter/material.dart';
import 'pet_record_screen.dart';

class VetVisitsScreen extends StatelessWidget {
  final String petId, familyId, petName;
  const VetVisitsScreen({
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
    section: 'VET',
  );
}
