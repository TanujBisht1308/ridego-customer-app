import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  void _open(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.rideHistory);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.wallet);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.history, 'Rides'),
      (Icons.account_balance_wallet_outlined, 'Wallet'),
      (Icons.person_outline, 'Profile'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final selected = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => _open(context, index),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[index].$1, color: selected ? AppColors.primaryDark : AppColors.textTertiary),
                        const SizedBox(height: 3),
                        Text(
                          items[index].$2,
                          style: TextStyle(
                            color: selected ? AppColors.textPrimary : AppColors.textTertiary,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
