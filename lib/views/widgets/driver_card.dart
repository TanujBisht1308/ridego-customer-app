import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'section_card.dart';

class DriverCard extends StatelessWidget {
  final bool compact;
  final bool showActions;

  const DriverCard({super.key, this.compact = false, this.showActions = true});

  @override
  Widget build(BuildContext context) {
    final driver = RideController.instance.assignedDriver;

    if (driver == null) {
      return SectionCard(
        child: Row(
          children: [
            SizedBox(
              width: compact ? 46 : 56,
              height: compact ? 46 : 56,
              child: const CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Text('Finding your driver...', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      );
    }

    return SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: compact ? 23 : 28,
                backgroundColor: AppColors.primary,
                backgroundImage: const AssetImage('assets/images/driver_avatar.png'),
                onBackgroundImageError: (_, __) {},
                child: const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driver.name,
                            style: TextStyle(fontSize: Responsive.font(context, 16), fontWeight: FontWeight.w900),
                          ),
                        ),
                        const Icon(Icons.star_rounded, color: AppColors.primaryDark, size: 18),
                        Text(driver.rating, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(driver.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: _Action(icon: Icons.call, label: 'Call')),
                Expanded(child: _Action(icon: Icons.message_outlined, label: 'Message')),
                Expanded(child: _Action(icon: Icons.cancel_outlined, label: 'Cancel', danger: true)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const _Action({required this.icon, required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: danger ? AppColors.danger.withValues(alpha: .08) : AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: danger ? AppColors.danger : AppColors.textPrimary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: danger ? AppColors.danger : AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}