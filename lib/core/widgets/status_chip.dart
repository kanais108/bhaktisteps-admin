import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
