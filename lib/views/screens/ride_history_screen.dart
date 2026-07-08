import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/transaction_item.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/section_card.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final _controller = RideController.instance;
  int _tab = 0; // 0 All, 1 Completed, 2 Cancelled

  @override
  void initState() {
    super.initState();
    _controller.fetchRideHistoryFromApi().then((_) {
      if (mounted) setState(() {});
    });
  } // 0 All, 1 Completed, 2 Cancelled

  @override
  Widget build(BuildContext context) {
    final rides = _controller.rideHistory.where((r) {
      if (_tab == 1) return r.status == 'Completed';
      if (_tab == 2) return r.status == 'Cancelled';
      return true;
    }).toList();

    return Scaffold(
      appBar: const AppTopBar(title: 'Ride History'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            children: [
              _Tabs(selected: _tab, onChanged: (i) => setState(() => _tab = i)),
              const SizedBox(height: 18),
              if (rides.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text('No rides here yet', style: const TextStyle(color: AppColors.textSecondary)),
                )
              else
                ...rides.map((ride) => _RideHistoryCard(item: ride)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['All', 'Completed', 'Cancelled'];
    return Container(
      height: 46,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: List.generate(
          labels.length,
          (i) => Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: _TabItem(text: labels[i], selectedTab: selected == i),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool selectedTab;
  const _TabItem({required this.text, this.selectedTab = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: selectedTab ? AppColors.black : Colors.transparent, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: selectedTab ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  final TransactionItem item;
  const _RideHistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cancelled = item.status == 'Cancelled';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.local_taxi, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (cancelled ? AppColors.danger : AppColors.success).withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(item.status, style: TextStyle(color: cancelled ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ],
              ),
            ),
            Text(item.amount, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
