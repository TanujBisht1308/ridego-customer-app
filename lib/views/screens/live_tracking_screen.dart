import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../widgets/driver_card.dart';
import '../widgets/ride_map.dart';


class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  // Simulated driver position — starts near pickup and slowly moves toward drop.
  // When you connect your real backend, replace this Timer with a WebSocket/
  // Firestore stream that pushes the driver's actual GPS coordinates.
  static const _pickup = LatLng(28.5708, 77.3261);
  static const _drop   = LatLng(28.6139, 77.2090);

  LatLng _driverPos = _pickup;
  double _progress = 0.0;
  Timer? _driverTimer;
  int _etaSeconds = 420; // 7 min countdown
  Timer? _etaTimer;
  final _controller = RideController.instance;

  @override
  void initState() {
    super.initState();
    _startDriverSimulation();
    _startEtaCountdown();
    // Auto-advance when the driver marks the ride as started on their end.
    RideController.instance.startPollingActiveRide((status) {
      if (!mounted) return;
      if (status == 'inProgress') {
        Navigator.pushReplacementNamed(context, AppRoutes.rideInProgress);
      }
    });
  }

  void _startDriverSimulation() {
    _driverTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _progress = (_progress + 0.015).clamp(0.0, 1.0);
        _driverPos = LatLng(
          _pickup.latitude + (_drop.latitude - _pickup.latitude) * _progress,
          _pickup.longitude + (_drop.longitude - _pickup.longitude) * _progress +
              sin(_progress * pi * 4) * 0.002, // slight wiggle for realism
        );
      });
    });
  }

  void _startEtaCountdown() {
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_etaSeconds > 0) _etaSeconds--;
      });
    });
  }

  String get _etaText {
    final m = _etaSeconds ~/ 60;
    final s = _etaSeconds % 60;
    return m > 0 ? '$m min${s > 0 ? ' $s sec' : ''}' : '$s sec';
  }

  @override
  void dispose() {
    _driverTimer?.cancel();
    _etaTimer?.cancel();
    super.dispose();
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse(RideController.emergencyNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling 112 — India Emergency Services')),
      );
    }
  }

  void _shareTracking() {
    final url = _controller.trackingUrl;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Live Tracking', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Send this link to anyone you want to share your real-time ride location with.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(url, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tracking link copied!')),
                      );
                    },
                    child: const Icon(Icons.copy, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                    label: const Text('WhatsApp'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final waUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('Track my ride live: $url')}');
                      if (await canLaunchUrl(waUri)) launchUrl(waUri, mode: LaunchMode.externalApplication);
                    },
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_browser, color: Colors.white),
                    label: const Text('Open Link'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Opens the tracking page within the app
                      Navigator.pushNamed(context, AppRoutes.trackingShare, arguments: url);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _controller.summary;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen live map with real driver marker
            Positioned.fill(
              child: RideMap(
                height: double.infinity,
                route: true,
                car: true,
                dense: true,
                driverPosition: RideController.instance.liveDriverPosition != null
    ? LatLng(
        RideController.instance.liveDriverPosition!['lat']!,
        RideController.instance.liveDriverPosition!['lng']!,
      )
    : _driverPos, // fallback to simulated position until first real update arrives
                pickupOverride: (RideController.instance.pickupLat != null && RideController.instance.pickupLng != null)
                    ? LatLng(RideController.instance.pickupLat!, RideController.instance.pickupLng!)
                    : null,
                dropOverride: (RideController.instance.dropLat != null && RideController.instance.dropLng != null)
                    ? LatLng(RideController.instance.dropLat!, RideController.instance.dropLng!)
                    : null,
                    routePoints: RideController.instance.routePoints
                    .map((p) => LatLng(p['lat']!, p['lng']!))
                    .toList(),
              ),
            ),

            // Top ETA card
            Positioned(
              left: 16, right: 16, top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.primaryDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver on the way',
                              style: TextStyle(fontSize: Responsive.font(context, 15), fontWeight: FontWeight.w900)),
                          Text('ETA: $_etaText', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Emergency button — top right
                    GestureDetector(
                      onTap: _callEmergency,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.emergency_share, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom panel — driver card + buttons
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DriverCard(compact: true),
                    const SizedBox(height: 14),
                    Text(
                      '${summary.distance} • ${summary.time} • ${summary.fare}',
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: const Text('Share Trip'),
                            onPressed: _shareTracking,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.rideInProgress),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Ride Started', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
