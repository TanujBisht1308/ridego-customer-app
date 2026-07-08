import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/section_card.dart';
import '../widgets/yellow_button.dart';

class RideCompletedScreen extends StatefulWidget {
  const RideCompletedScreen({super.key});

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> {
  final _controller = RideController.instance;
  final bool _recorded = false;

  @override
  void initState() {
    super.initState();
    // Record this trip into ride history / wallet exactly once.
    RideController.instance.stopPollingActiveRide();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _controller.summary;
    return Scaffold(
      appBar: const AppTopBar(title: '', showBack: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Container(
                height: 92,
                width: 92,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 54),
              ),
              const SizedBox(height: 22),
              Text('Ride Completed', style: TextStyle(fontSize: Responsive.font(context, 24), fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Total Fare', style: TextStyle(color: AppColors.textSecondary, fontSize: Responsive.font(context, 14))),
              const SizedBox(height: 4),
              Text(summary.fare, style: TextStyle(fontSize: Responsive.font(context, 30), fontWeight: FontWeight.w900)),
              const SizedBox(height: 26),
              SectionCard(
                child: Column(
                  children: [
                    _Row(label: 'Distance', value: summary.distance),
                    const Divider(height: 26),
                    _Row(label: 'Duration', value: summary.time),
                    const Divider(height: 26),
                    _Row(label: 'Payment', value: summary.paymentMethod),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text('Thank you for riding with RideGo!', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 26),
              YellowButton(text: 'Continue', onTap: () => Navigator.pushNamed(context, AppRoutes.payment)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}
