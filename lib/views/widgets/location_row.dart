import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class LocationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const LocationRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: Responsive.font(context, 12), color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: Responsive.font(context, 14), fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
