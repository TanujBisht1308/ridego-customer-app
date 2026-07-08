import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/yellow_button.dart';

class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({super.key});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  final _controller = RideController.instance;
  late final _reviewController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await _controller.submitRideRating(_controller.rating, _reviewController.text.trim());
    _controller.resetForNextRide();
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your feedback!')));
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.rideHistory, (route) => route.settings.name == AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final driver = _controller.assignedDriver;
    return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text('Rate Your Ride', style: TextStyle(fontSize: Responsive.font(context, 24), fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              ClipOval(
                child: Image.asset(
                  'assets/images/driver_avatar.png',
                  height: 88,
                  width: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const CircleAvatar(radius: 44, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 44, color: AppColors.black)),
                ),
              ),
              const SizedBox(height: 12),
              Text(driver?.name ?? 'Your Driver', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _controller.setRating(index + 1)),
                    icon: Icon(
                      index < _controller.rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.primaryDark,
                      size: 38,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _reviewController,
                minLines: 4,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Write a Review (Optional)\nGreat ride!'),
              ),
              const SizedBox(height: 30),
              YellowButton(text: _submitting ? 'Submitting...' : 'Submit', onTap: _submitting ? null : _submit),
            ],
          ),
        ),
      ),
    );
  }
}