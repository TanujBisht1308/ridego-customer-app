import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = RideController.instance;

  Future<void> _pickLanguage() async {
    final options = ['English', 'Hindi', 'Tamil', 'Telugu'];
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((lang) => ListTile(
                    title: Text(lang),
                    trailing: lang == _controller.language ? const Icon(Icons.check, color: AppColors.primaryDark) : null,
                    onTap: () => Navigator.pop(ctx, lang),
                  ))
              .toList(),
        ),
      ),
    );
    if (result != null) {
      setState(() => _controller.setLanguage(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Settings'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Preferences'),
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _controller.notificationsEnabled,
                      onChanged: (v) => setState(() => _controller.toggleNotifications(v)),
                      activeThumbColor: AppColors.primaryDark,
                      title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: const Text('Ride updates, offers & alerts'),
                    ),
                    const Divider(height: 1, indent: 16),
                    SwitchListTile(
                      value: _controller.locationSharingEnabled,
                      onChanged: (v) => setState(() => _controller.toggleLocationSharing(v)),
                      activeThumbColor: AppColors.primaryDark,
                      title: const Text('Location Sharing', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: const Text('Share live location with driver'),
                    ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(_controller.language),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      onTap: _pickLanguage,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _Label('Account'),
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('A reset link will be sent to your email')),
                      ),
                    ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                      title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.danger)),
                      onTap: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete account?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _Label('About'),
              const SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RideGo Customer App', style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text, style: TextStyle(fontSize: Responsive.font(context, 13), fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
    );
  }
}
