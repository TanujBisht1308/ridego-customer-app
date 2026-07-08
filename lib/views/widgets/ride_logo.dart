import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/responsive.dart';

class RideLogo extends StatelessWidget {
  final bool dark;
  final double size;

  const RideLogo({super.key, this.dark = false, this.size = 78});

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? AppColors.card : AppColors.textPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * .30),
          child: Image.asset(
            'assets/images/logo.png',
            height: size,
            width: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(size * .30),
              ),
              child: Icon(Icons.local_taxi_rounded, color: AppColors.black, size: size * .48),
            ),
          ),
        ),
        const SizedBox(height: 14),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Ride',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: Responsive.font(context, 30),
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: 'Go',
                style: TextStyle(
                  color: textColor,
                  fontSize: Responsive.font(context, 30),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Text(
          AppStrings.tagLine,
          textAlign: TextAlign.center,
          style: TextStyle(color: dark ? AppColors.border : AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
