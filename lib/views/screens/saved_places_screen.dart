import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/section_card.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final _controller = RideController.instance;

  Future<void> _edit({required String label, required String? current, required ValueChanged<String> onSave}) async {
    final textController = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set $label address'),
        content: TextField(controller: textController, autofocus: true, decoration: const InputDecoration(hintText: 'Enter full address')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, textController.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result == null) return;
    setState(() => onSave(result));
  }

  void _useForRide(String address) {
    _controller.setDrop(address);
    Navigator.pushNamed(context, AppRoutes.vehicleSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Saved Places'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            children: [
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _PlaceTile(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      subtitle: _controller.homeAddress ?? 'Tap to set address',
                      onTap: () => _controller.homeAddress == null
                          ? _edit(label: 'Home', current: _controller.homeAddress, onSave: _controller.setHomeAddress)
                          : _useForRide(_controller.homeAddress!),
                      onEdit: () => _edit(label: 'Home', current: _controller.homeAddress, onSave: _controller.setHomeAddress),
                    ),
                    const Divider(height: 1, indent: 70),
                    _PlaceTile(
                      icon: Icons.work_rounded,
                      title: 'Work',
                      subtitle: _controller.workAddress ?? 'Tap to set address',
                      onTap: () => _controller.workAddress == null
                          ? _edit(label: 'Work', current: _controller.workAddress, onSave: _controller.setWorkAddress)
                          : _useForRide(_controller.workAddress!),
                      onEdit: () => _edit(label: 'Work', current: _controller.workAddress, onSave: _controller.setWorkAddress),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Other Places', style: TextStyle(fontWeight: FontWeight.w900, fontSize: Responsive.font(context, 14))),
              ),
              const SizedBox(height: 10),
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: _controller.popularPlaces
                      .map((place) => Column(
                            children: [
                              _PlaceTile(
                                icon: Icons.location_on_outlined,
                                title: place,
                                subtitle: 'Popular destination',
                                onTap: () => _useForRide(place),
                              ),
                              if (place != _controller.popularPlaces.last) const Divider(height: 1, indent: 70),
                            ],
                          ))
                      .toList(),
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
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _PlaceTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: onEdit != null
          ? IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: AppColors.textTertiary, size: 19))
          : const Icon(Icons.chevron_right, color: AppColors.textTertiary),
    );
  }
}
