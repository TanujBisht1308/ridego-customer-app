import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/ride_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = RideController.instance;

  @override
  void initState() {
    super.initState();
    _controller.fetchCurrentLocationAsPickup().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _promptAndGo({required String label, required String? current, required ValueChanged<String> onSave}) async {
    final textController = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set $label address'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter full address'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    onSave(result);
    if (!mounted) return;
    _controller.setDrop(result);
    Navigator.pushNamed(context, AppRoutes.vehicleSelection);
  }

  void _goTo(String place) {
    _controller.setDrop(place);
    Navigator.pushNamed(context, AppRoutes.vehicleSelection);
  }

  void _onQuickAction(String label) {
    switch (label) {
      case 'Home':
        if (_controller.homeAddress != null) {
          _goTo(_controller.homeAddress!);
        } else {
          _promptAndGo(label: 'Home', current: _controller.homeAddress, onSave: _controller.setHomeAddress);
        }
        break;
      case 'Work':
        if (_controller.workAddress != null) {
          _goTo(_controller.workAddress!);
        } else {
          _promptAndGo(label: 'Work', current: _controller.workAddress, onSave: _controller.setWorkAddress);
        }
        break;
      case 'Airport':
        _goTo(_controller.airportAddress);
        break;
      case 'Recent':
        Navigator.pushNamed(context, AppRoutes.searchDestination);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: RideMap(height: double.infinity, route: false, car: false, dense: true)),
            Positioned(
              left: 20,
              right: 20,
              top: 16,
              child: Column(
                children: [
                  _SearchCard(icon: Icons.my_location, title: 'Current Location', subtitle: _controller.summary.pickup),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.searchDestination),
                    child: const _SearchCard(icon: Icons.search, title: 'Where to?', subtitle: 'Search destination'),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                children: [
                  _SuggestionPanel(onTap: _onQuickAction),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SearchCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: Responsive.font(context, 12))),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: Responsive.font(context, 14), fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _SuggestionPanel({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.work_rounded, 'Work'),
      (Icons.flight_takeoff, 'Airport'),
      (Icons.history, 'Recent'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggestions', style: TextStyle(fontSize: Responsive.font(context, 15), fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items
                .map((item) => Expanded(
                      child: InkWell(
                        onTap: () => onTap(item.$2),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                              child: Icon(item.$1, color: AppColors.textPrimary, size: 20),
                            ),
                            const SizedBox(height: 7),
                            Text(item.$2, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
