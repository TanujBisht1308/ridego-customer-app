import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/driver_card.dart';
import '../widgets/ride_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/section_card.dart';
import '../widgets/yellow_button.dart';

class DriverAssignedScreen extends StatelessWidget {
  const DriverAssignedScreen({super.key});

  void _cancelRide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Ride?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why do you want to cancel?'),
            const SizedBox(height: 14),
            ...[
              'Driver is taking too long',
              'Booked by mistake',
              'Change of plans',
              'Found another ride',
            ].map((reason) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.radio_button_off, size: 18),
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    RideController.instance.cancelRide();
                    Navigator.pop(ctx);
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ride cancelled successfully')),
                    );
                  },
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Ride')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: '',
        actions: [
          TextButton(
            onPressed: () => _cancelRide(context),
            child: const Text('Cancel Ride', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            children: [
              SectionCard(
                color: AppColors.success.withValues(alpha: .08),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text('Driver is on the way',
                            style: TextStyle(fontWeight: FontWeight.w900))),
                    Text('2 min', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Real map with driver marker
              RideMap(
                height: 245,
                route: true,
                car: true,
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
              const SizedBox(height: 16),
              const DriverCard(),
              const SizedBox(height: 20),
              YellowButton(
                text: 'Track Driver',
                icon: Icons.location_on,
                onTap: () => Navigator.pushNamed(context, AppRoutes.liveTracking),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
