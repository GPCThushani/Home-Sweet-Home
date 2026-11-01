import 'package:flutter/material.dart';

class PetSectionScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onAdd;
  final String addLabel;
  const PetSectionScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onAdd,
    this.addLabel = 'Add',
  });
  static const ivory = Color(0xFFFAF8F3),
      pale = Color(0xFFE5EEE7),
      forest = Color(0xFF355C4A),
      dark = Color(0xFF244032);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ivory,
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(color: dark, fontWeight: FontWeight.w800),
      ),
      foregroundColor: dark,
      backgroundColor: pale,
      elevation: 0,
    ),
    body: SafeArea(child: body),
    floatingActionButton: onAdd == null
        ? null
        : FloatingActionButton.extended(
            onPressed: onAdd,
            backgroundColor: forest,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          ),
  );
}

class PetSectionError extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const PetSectionError({
    super.key,
    required this.message,
    required this.retry,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Color(0xFF65716B),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class PetSectionEmpty extends StatelessWidget {
  final String message;
  const PetSectionEmpty({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets_rounded, size: 48, color: Color(0xFF4A8B71)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
