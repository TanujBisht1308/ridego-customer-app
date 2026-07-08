import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/yellow_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _controller = RideController.instance;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final value = _phoneController.text.trim();
    if (value.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _error = null);

    final success = await _controller.sendOtp('+91$value');
    if (!mounted) return;

    if (success) {
      Navigator.pushNamed(context, AppRoutes.otp, arguments: value);
    } else {
      setState(() => _error = _controller.errorMessage ?? 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 180),
                    Text('Welcome Back', style: TextStyle(fontSize: Responsive.font(context, 46), fontWeight: FontWeight.w900)),
                    const SizedBox(height: 20),
                    const Text('Login to Continue', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    const _TaxiHero(),
                    const SizedBox(height: 0),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _continue(),
                      decoration: InputDecoration(
                        counterText: '',
                        prefixIcon: Container(
                          alignment: Alignment.center,
                          width: 72,
                          child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        hintText: 'Enter Mobile Number',
                        errorText: _error,
                      ),
                    ),
                    const SizedBox(height: 28),
                    YellowButton(
                      text: _controller.isLoading ? 'Please wait...' : 'Continue',
                      onTap: _controller.isLoading ? null : _continue,
                    ),
                    const SizedBox(height: 18),
                    Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: Responsive.font(context, 12)),
                        children: const [
                          TextSpan(text: 'Terms & Conditions', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(AppStrings.appName, style: TextStyle(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TaxiHero extends StatelessWidget {
  const _TaxiHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      width: 450,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: .15),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/splash_car.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 65, color: AppColors.primaryDark),
      ),
    );
  }
}