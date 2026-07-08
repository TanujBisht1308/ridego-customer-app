import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/ride_map.dart';

/// Public tracking page — shown when someone opens your share link.
/// In production, this will be a web page served by your backend. Inside
/// the app, it shows the live map and ride details for context.
class TrackingShareScreen extends StatelessWidget {
  const TrackingShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final url = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tracking link copied!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Full-width map
              const SizedBox(
                height: 380,
                child: RideMap(height: 380, route: true, car: true, dense: true),
              ),
              Padding(
                padding: Responsive.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(radius: 22, backgroundColor: AppColors.primary,
                                  child: Icon(Icons.local_taxi, color: Colors.white)),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rohit Kumar', style: TextStyle(
                                      fontWeight: FontWeight.w900, fontSize: Responsive.font(context, 16))),
                                  const Text('White Swift Dzire • UP AB 1234',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.star, color: AppColors.primaryDark, size: 16),
                              const Text(' 4.8', style: TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          _InfoRow(icon: Icons.circle, iconColor: AppColors.success,
                              label: 'Pickup', value: 'Sector 62, Noida'),
                          const SizedBox(height: 10),
                          _InfoRow(icon: Icons.location_on, iconColor: AppColors.danger,
                              label: 'Drop', value: 'Connaught Place, Delhi'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primaryDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('This is a live tracking link shared by the rider.',
                                style: TextStyle(color: AppColors.primaryDark, fontSize: Responsive.font(context, 13))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 10),
        Text('$label  ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
