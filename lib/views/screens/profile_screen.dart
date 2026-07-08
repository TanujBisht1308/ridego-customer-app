import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../models/profile_menu_item.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _controller = RideController.instance;

  void _onMenuTap(ProfileMenuItem item) {
    switch (item.title) {
      case 'Logout':
  RideController.instance.logoutSession().then((_) {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  });
  break;
      case 'Saved Places':
        Navigator.pushNamed(context, AppRoutes.savedPlaces).then((_) => setState(() {}));
        break;
      case 'Payment Methods':
        Navigator.pushNamed(context, AppRoutes.payment);
        break;
      case 'Settings':
        Navigator.pushNamed(context, AppRoutes.settings).then((_) => setState(() {}));
        break;
      case 'Help & Support':
        Navigator.pushNamed(context, AppRoutes.helpSupport);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.title} coming soon')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final menus = _controller.profileMenus;
    return Scaffold(
      appBar: const AppTopBar(title: 'My Profile', showBack: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            children: [
              SectionCard(
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/profile_avatar.png',
                        height: 68,
                        width: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const CircleAvatar(radius: 34, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: AppColors.black, size: 34)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_controller.userName, style: TextStyle(fontSize: Responsive.font(context, 18), fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(_controller.userPhone, style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.profileSetup).then((_) => setState(() {})),
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: menus.map((item) => _MenuTile(item: item, last: item == menus.last, onTap: () => _onMenuTap(item))).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final ProfileMenuItem item;
  final bool last;
  final VoidCallback onTap;
  const _MenuTile({required this.item, required this.last, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(color: last ? AppColors.danger.withValues(alpha: .08) : AppColors.background, borderRadius: BorderRadius.circular(13)),
            child: Icon(item.icon, color: last ? AppColors.danger : AppColors.textPrimary, size: 20),
          ),
          title: Text(item.title, style: TextStyle(fontWeight: FontWeight.w800, color: last ? AppColors.danger : AppColors.textPrimary)),
          trailing: last ? null : const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ),
        if (!last) const Divider(height: 1, indent: 70),
      ],
    );
  }
}
