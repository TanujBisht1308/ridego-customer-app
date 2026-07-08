import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/yellow_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final _controller = RideController.instance;
  int _secondsLeft = 30;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
        _tick();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _isComplete => _controllers.every((c) => c.text.trim().isNotEmpty);

  Future<void> _verify() async {
    if (!_isComplete) {
      setState(() => _error = 'Please enter the complete 4-digit OTP');
      return;
    }
    final otp = _controllers.map((c) => c.text.trim()).join();
    final success = await _controller.verifyOtp(otp);
    if (!mounted) return;

    if (success) {
      if (_controller.isProfileComplete) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profileSetup, (_) => false);
      }
    } else {
      setState(() => _error = _controller.errorMessage ?? 'Invalid OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ModalRoute.of(context)?.settings.arguments as String?;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: const AppTopBar(title: ''),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Text('Enter OTP', style: TextStyle(fontSize: Responsive.font(context, 24), fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('We have sent OTP to', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(phone == null ? '+91 98765 43210' : '+91 $phone', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 38),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (i) => _OtpBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          hasError: _error != null,
                          onChanged: (value) {
                            if (_error != null) setState(() => _error = null);
                            if (value.isNotEmpty && i < 3) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (value.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            } else if (value.isNotEmpty && i == 3) {
                              _verify();
                            }
                            setState(() {});
                          },
                        )),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: _secondsLeft == 0
                        ? () async {
                            setState(() => _secondsLeft = 30);
                            if (phone != null) await _controller.sendOtp('+91$phone');
                          }
                        : null,
                    child: Text(
                      _secondsLeft > 0 ? 'Resend OTP in 00:${_secondsLeft.toString().padLeft(2, '0')}' : 'Resend OTP',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  YellowButton(
                    text: _controller.isLoading ? 'Verifying...' : 'Verify',
                    onTap: _controller.isLoading ? null : _verify,
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: hasError ? AppColors.danger : AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          maxLength: 1,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(fontSize: Responsive.font(context, 20), fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}