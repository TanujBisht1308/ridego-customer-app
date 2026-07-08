import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../widgets/ride_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    await RideController.instance.loadSession();
    if (!mounted) return;

    final controller = RideController.instance;
    if (!controller.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (!controller.isProfileComplete) {
      Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SizedBox.expand(
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Center(child: RideLogo(dark: true, size: 86)),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Container(
                    height: 4,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}