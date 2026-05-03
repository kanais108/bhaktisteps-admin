import 'package:flutter/material.dart';

class AdminCard extends StatelessWidget {
  final Widget child;

  const AdminCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
