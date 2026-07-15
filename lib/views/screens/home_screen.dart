import 'dart:async';
import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../models/saved_place.dart';
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
    _controller.fetchSavedPlaces();
  }

  void _goToSavedPlace(SavedPlace place) {
    _controller.setDrop(place.address);
    _controller.dropLat = place.latitude;
    _controller.dropLng = place.longitude;
    _controller.fetchRoute();
    Navigator.pushNamed(context, AppRoutes.vehicleSelection);
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
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _SavedPlacesPanel(
                  controller: _controller,
                  onOpenPlace: _goToSavedPlace,
                ),
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

IconData _iconForPlace(String icon) {
  switch (icon) {
    case 'home':
      return Icons.home_rounded;
    case 'work':
      return Icons.work_rounded;
    default:
      return Icons.place_rounded;
  }
}

class _SavedPlacesPanel extends StatefulWidget {
  final RideController controller;
  final ValueChanged<SavedPlace> onOpenPlace;

  const _SavedPlacesPanel({required this.controller, required this.onOpenPlace});

  @override
  State<_SavedPlacesPanel> createState() => _SavedPlacesPanelState();
}

class _SavedPlacesPanelState extends State<_SavedPlacesPanel> {
  bool _expanded = false;

  Future<void> _openEditDialog(SavedPlace place) async {
    final labelCtrl = TextEditingController(text: place.label);
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Place', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: labelCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (action == 'delete') {
      await widget.controller.deleteSavedPlace(place.id);
    } else if (action == 'save' && labelCtrl.text.trim().isNotEmpty) {
      await widget.controller.updateSavedPlace(place.id, label: labelCtrl.text.trim());
    }
  }

  Future<void> _openAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPlaceSheet(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.controller.savedPlaces;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.bookmark_rounded, color: AppColors.textPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved Places', style: TextStyle(fontSize: Responsive.font(context, 15), fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        places.isEmpty ? 'Add a place to get started' : '${places.length} saved',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: !_expanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...places.map(
                          (place) => Dismissible(
                            key: ValueKey(place.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.only(right: 16),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline, color: AppColors.danger),
                            ),
                            onDismissed: (_) => widget.controller.deleteSavedPlace(place.id),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => widget.onOpenPlace(place),
                                borderRadius: BorderRadius.circular(14),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                                      child: Icon(_iconForPlace(place.icon), color: AppColors.textPrimary, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(place.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text(
                                            place.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textTertiary),
                                      onPressed: () => _openEditDialog(place),
                                      splashRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _openAddSheet,
                          borderRadius: BorderRadius.circular(14),
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.textTertiary.withOpacity(0.3), width: 1),
                                ),
                                child: const Icon(Icons.add_rounded, color: AppColors.textSecondary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('Add New Place', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddPlaceSheet extends StatefulWidget {
  final RideController controller;
  const _AddPlaceSheet({required this.controller});

  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  final _searchCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, String>> _suggestions = [];
  Map<String, String>? _selectedSuggestion;
  bool _saving = false;
  String _icon = 'place';

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _selectedSuggestion = null;
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await widget.controller.searchPlaces(value);
      if (mounted) setState(() => _suggestions = results);
    });
  }

  Future<void> _save() async {
    if (_selectedSuggestion == null || _labelCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final details = await widget.controller.resolvePlaceDetails(_selectedSuggestion!['placeId']!);
    if (details == null) {
      setState(() => _saving = false);
      return;
    }

    final success = await widget.controller.addSavedPlace(
      label: _labelCtrl.text.trim(),
      address: details['address'] as String,
      latitude: details['latitude'] as double,
      longitude: details['longitude'] as double,
      icon: _icon,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.pop(context);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Place', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Row(
              children: [
                _IconChoiceChip(label: 'Home', icon: Icons.home_rounded, selected: _icon == 'home', onTap: () => setState(() => _icon = 'home')),
                const SizedBox(width: 8),
                _IconChoiceChip(label: 'Work', icon: Icons.work_rounded, selected: _icon == 'work', onTap: () => setState(() => _icon = 'work')),
                const SizedBox(width: 8),
                _IconChoiceChip(label: 'Other', icon: Icons.place_rounded, selected: _icon == 'place', onTap: () => setState(() => _icon = 'place')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(labelText: 'Label', hintText: 'e.g. Mom\'s House'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(labelText: 'Search address', hintText: 'Start typing an address'),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined, size: 18),
                      title: Text(s['text'] ?? '', style: const TextStyle(fontSize: 13)),
                      onTap: () {
                        setState(() {
                          _selectedSuggestion = s;
                          _searchCtrl.text = s['text'] ?? '';
                          _suggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving || _selectedSuggestion == null || _labelCtrl.text.trim().isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Save Place', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoiceChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.12) : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.4),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? AppColors.primary : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}