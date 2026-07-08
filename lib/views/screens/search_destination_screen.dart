import 'dart:async';
import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';

class SearchDestinationScreen extends StatefulWidget {
  const SearchDestinationScreen({super.key});

  @override
  State<SearchDestinationScreen> createState() => _SearchDestinationScreenState();
}

class _SearchDestinationScreenState extends State<SearchDestinationScreen> {
  final _controller = RideController.instance;
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, String>> _suggestions = [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      final results = await _controller.searchPlaces(value);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    });
  }

  Future<void> _select(String placeId) async {
    setState(() => _searching = true);
    final success = await _controller.selectDropPlace(placeId);
    if (!mounted) return;
    setState(() => _searching = false);

    if (success) {
      Navigator.pushNamed(context, AppRoutes.vehicleSelection);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve that place. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: SafeArea(
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Where to?',
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              if (_suggestions.isEmpty && _searchController.text.trim().isNotEmpty && !_searching)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('No places found', style: TextStyle(color: AppColors.textSecondary))),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    return _PlaceTile(
                      title: s['text'] ?? '',
                      icon: Icons.location_on_outlined,
                      onTap: () => _select(s['placeId']!),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _PlaceTile({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}