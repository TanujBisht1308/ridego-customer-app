import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';

class FindingDriverScreen extends StatefulWidget {
  const FindingDriverScreen({super.key});

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _spinCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    // Real polling — waits for a driver to actually accept in your backend.
    RideController.instance.startPollingActiveRide((status) {
      if (!mounted) return;
      if (status == 'accepted') {
        Navigator.pushReplacementNamed(context, AppRoutes.driverAssigned);
      } else if (status == 'cancelled') {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelRide() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Ride?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to cancel the ride request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No, Keep')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await RideController.instance.cancelActiveRide();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: '', actions: [
        TextButton(
          onPressed: _cancelRide,
          child: const Text('Cancel', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
        ),
      ]),
      body: SizedBox.expand(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 180,
                      width: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _spinCtrl,
                            child: Container(
                              height: 170,
                              width: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 3, strokeAlign: BorderSide.strokeAlignOutside),
                              ),
                            ),
                          ),
                          ScaleTransition(
                            scale: _pulseAnim,
                            child: Container(
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                          ),
                          Container(
                            height: 104,
                            width: 104,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))],
                            ),
                            child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text('Finding you a driver...', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.font(context, 22), fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    const Text('Please wait while we find the best driver for you.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 32),
                    const LinearProgressIndicator(color: AppColors.primaryDark, backgroundColor: AppColors.border, minHeight: 3),
                    const SizedBox(height: 36),
                    OutlinedButton(
                      onPressed: _cancelRide,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                      child: const Text('Cancel Ride', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}