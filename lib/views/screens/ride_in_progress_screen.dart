import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/driver_card.dart';
import '../widgets/ride_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/section_card.dart';
import '../widgets/yellow_button.dart';

class RideInProgressScreen extends StatefulWidget {
  const RideInProgressScreen({super.key});

  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}

class _RideInProgressScreenState extends State<RideInProgressScreen> {
  @override
  void initState() {
    super.initState();
    RideController.instance.startPollingActiveRide((status) {
      if (!mounted) return;
      if (status == 'completed') {
        Navigator.pushReplacementNamed(context, AppRoutes.rideCompleted);
      }
    });
  }
  Future<void> _callEmergency(BuildContext context) async {
    final uri = Uri.parse(RideController.emergencyNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calling 112 — India Emergency Services'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _shareTracking(BuildContext context) {
    final url = RideController.instance.trackingUrl;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Live Tracking', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Let someone track your ride in real time.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(url,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tracking link copied!')),
                      );
                    },
                    child: const Icon(Icons.copy, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                    label: const Text('WhatsApp'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final waUri = Uri.parse(
                          'https://wa.me/?text=${Uri.encodeComponent('Track my ride live: $url')}');
                      if (await canLaunchUrl(waUri)) {
                        launchUrl(waUri, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_browser, color: Colors.white),
                    label: const Text('Open Page'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.trackingShare, arguments: url);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = RideController.instance.summary;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            children: [
              // Emergency banner — tapping actually calls 112
              GestureDetector(
                onTap: () => _callEmergency(context),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withValues(alpha: .3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emergency_share, color: AppColors.danger),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Emergency — Tap to Call 112',
                            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.danger)),
                      ),
                      Icon(Icons.phone, color: AppColors.danger),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RideMap(
                height: 270,
                pickupOverride: (RideController.instance.pickupLat != null && RideController.instance.pickupLng != null)
                    ? LatLng(RideController.instance.pickupLat!, RideController.instance.pickupLng!)
                    : null,
                dropOverride: (RideController.instance.dropLat != null && RideController.instance.dropLng != null)
                    ? LatLng(RideController.instance.dropLat!, RideController.instance.dropLng!)
                    : null,
                    routePoints: RideController.instance.routePoints
                    .map((p) => LatLng(p['lat']!, p['lng']!))
                    .toList(),
              ),
              const SizedBox(height: 14),
              SectionCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TripMetric(label: 'Distance', value: summary.distance),
                    _TripMetric(label: 'Time', value: summary.time),
                    _TripMetric(label: 'Fare', value: summary.fare),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const DriverCard(compact: true, showActions: false),
              const SizedBox(height: 16),
              // Share tracking — separate button, user's choice
              OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share Live Tracking'),
                onPressed: () => _shareTracking(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              YellowButton(
                text: 'Complete Ride',
                onTap: () => Navigator.pushNamed(context, AppRoutes.rideCompleted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripMetric extends StatelessWidget {
  final String label;
  final String value;
  const _TripMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: Responsive.font(context, 16), fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
