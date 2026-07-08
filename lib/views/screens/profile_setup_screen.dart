import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/yellow_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _controller = RideController.instance;
  late final _nameController = TextEditingController(text: _controller.userName);
  late final _emailController = TextEditingController(text: _controller.userEmail);
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    setState(() => _error = null);

    final success = await _controller.saveCustomerProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );
    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
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
          appBar: const AppTopBar(title: '', showBack: false),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: Column(
                children: [
                  Text('Complete Your Profile', style: TextStyle(fontSize: Responsive.font(context, 23), fontWeight: FontWeight.w900)),
                  const SizedBox(height: 26),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/profile_avatar.png',
                          height: 96,
                          width: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const CircleAvatar(radius: 48, backgroundColor: AppColors.border, child: Icon(Icons.person, size: 48, color: AppColors.textTertiary)),
                        ),
                      ),
                      Container(
                        height: 34,
                        width: 34,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  _Field(label: 'Full Name', hint: 'John Doe', controller: _nameController),
                  const SizedBox(height: 18),
                  _Field(label: 'Email', hint: 'john@example.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                  const SizedBox(height: 32),
                  YellowButton(
                    text: _controller.isLoading ? 'Saving...' : 'Save & Continue',
                    onTap: _controller.isLoading ? null : _save,
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

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  const _Field({required this.label, required this.hint, required this.controller, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: Responsive.font(context, 13), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}