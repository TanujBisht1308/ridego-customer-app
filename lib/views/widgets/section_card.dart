import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}
