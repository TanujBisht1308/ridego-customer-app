import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/location_row.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/ride_map.dart';
import '../widgets/section_card.dart';
import '../widgets/yellow_button.dart';

class ConfirmRideScreen extends StatelessWidget {
  const ConfirmRideScreen({super.key});

  Future<void> _confirm(BuildContext context) async {
    final controller = RideController.instance;
    final success = await controller.requestRide();
    if (!context.mounted) return;

    if (success) {
      Navigator.pushNamed(context, AppRoutes.findingDriver);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Could not request ride')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = RideController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final summary = controller.summary;
        return Scaffold(
          appBar: const AppTopBar(title: 'Confirm Ride'),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: Column(
                children: [
                   RideMap(
                    height: 225,
                    pickupOverride: (controller.pickupLat != null && controller.pickupLng != null)
                        ? LatLng(controller.pickupLat!, controller.pickupLng!)
                        : null,
                    dropOverride: (controller.dropLat != null && controller.dropLng != null)
                        ? LatLng(controller.dropLat!, controller.dropLng!)
                        : null,
                        routePoints: RideController.instance.routePoints
                    .map((p) => LatLng(p['lat']!, p['lng']!))
                    .toList(),
                  ),
                  const SizedBox(height: 18),
                  SectionCard(
                    child: Column(
                      children: [
                        LocationRow(title: 'Pickup Location', subtitle: summary.pickup, color: AppColors.success, icon: Icons.my_location),
                        const Divider(height: 28),
                        LocationRow(title: 'Drop Location', subtitle: summary.drop, color: AppColors.danger, icon: Icons.location_on),
                        const Divider(height: 28),
                        _InfoLine(icon: Icons.route_outlined, label: 'Distance', value: summary.distance),
                        const SizedBox(height: 14),
                        _InfoLine(icon: Icons.schedule_outlined, label: 'Estimated Time', value: summary.time),
                        const SizedBox(height: 14),
                        _InfoLine(icon: Icons.local_taxi, label: 'Ride Type', value: summary.rideType),
                        const SizedBox(height: 14),
                        _InfoLine(icon: Icons.payments_outlined, label: 'Estimated Fare', value: summary.fare),
                        const SizedBox(height: 14),
                        _InfoLine(icon: Icons.account_balance_wallet_outlined, label: 'Payment Method', value: summary.paymentMethod),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  YellowButton(
                    text: controller.isLoading ? 'Requesting...' : 'Confirm Ride',
                    onTap: controller.isLoading ? null : () => _confirm(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoLine({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
        Text(value, style: TextStyle(fontSize: Responsive.font(context, 14), fontWeight: FontWeight.w900)),
      ],
    );
  }
}