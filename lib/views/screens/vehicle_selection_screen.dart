import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../models/vehicle_option.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/yellow_button.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  final _controller = RideController.instance;

  @override
  void initState() {
    super.initState();
    _controller.fetchFareEstimate();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: const AppTopBar(title: 'Select a Ride'),
          body: SafeArea(
            child: _controller.isLoading && _controller.vehicles.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
                : SingleChildScrollView(
                    padding: Responsive.pagePadding(context),
                    child: Column(
                      children: [
                        ...List.generate(
                          _controller.vehicles.length,
                          (i) => _VehicleTile(
                            vehicle: _controller.vehicles[i],
                            onTap: () => _controller.selectVehicleById(_controller.vehicles[i].id),
                          ),
                        ),
                        const SizedBox(height: 24),
                        YellowButton(
                          text: 'Continue',
                          onTap: _controller.vehicles.isEmpty
                              ? null
                              : () => Navigator.pushNamed(context, AppRoutes.confirmRide),
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

class _VehicleTile extends StatelessWidget {
  final VehicleOption vehicle;
  final VoidCallback onTap;
  const _VehicleTile({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: vehicle.selected ? AppColors.primary : AppColors.border,
            width: vehicle.selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: vehicle.selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.shadow,
              blurRadius: vehicle.selected ? 16 : 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 62,
              width: 88,
              decoration: BoxDecoration(
                color: vehicle.selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                vehicle.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(vehicle.icon, color: AppColors.black, size: 34),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.name, style: TextStyle(fontSize: Responsive.font(context, 16), fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(vehicle.priceRange, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [const Icon(Icons.person, size: 15), const SizedBox(width: 4), Text(vehicle.seats)]),
                const SizedBox(height: 4),
                Text(vehicle.eta, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            if (vehicle.selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: AppColors.primaryDark),
            ],
          ],
        ),
      ),
    );
  }
}