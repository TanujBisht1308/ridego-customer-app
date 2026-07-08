import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';

/// Real Google Map with actual GPS user-location dot.
///
/// NOTE: Add your Google Maps API key before this will render tiles.
///   Android → android/app/src/main/AndroidManifest.xml  (meta-data geo.API_KEY)
///   iOS     → ios/Runner/AppDelegate.swift               (GMSServices.provideAPIKey)
///   Web     → web/index.html                             (maps JS script src)
class RideMap extends StatefulWidget {
  final double height;
  final bool route;
  final bool car;
  final bool dense;
  final LatLng? driverPosition; // live driver marker (updated externally)
  final LatLng? pickupOverride; // real pickup coords, when known
  final LatLng? dropOverride;
  final List<LatLng>? routePoints;   // real drop coords, when known

  const RideMap({
    super.key,
    this.height = 300,
    this.route = true,
    this.car = true,
    this.dense = false,
    this.driverPosition,
    this.pickupOverride,
    this.dropOverride,
    this.routePoints,
  });

  // Delhi NCR fallback demo coords — only used if no real pickup/drop
  // coords were passed in (e.g. before a search has been made).
  static const LatLng _pickup = LatLng(28.5708, 77.3261); // Noida Sector 18
  static const LatLng _drop   = LatLng(28.6139, 77.2090); // Connaught Place
  static const LatLng _demo   = LatLng(28.5921, 77.2675); // midpoint fallbackLatLng _demo   = LatLng(28.5921, 77.2675); // midpoint fallback

  @override
  State<RideMap> createState() => _RideMapState();
}
class _RideMapState extends State<RideMap> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionSub;

  LatLng get _pickupPoint => widget.pickupOverride ?? RideMap._pickup;
  LatLng get _dropPoint => widget.dropOverride ?? RideMap._drop;
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // Snap camera to real user position once on first load
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _userLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14.5));

      // Then stream updates so the blue dot stays live
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((p) {
        if (!mounted) return;
        setState(() => _userLocation = LatLng(p.latitude, p.longitude));
      });
    } catch (_) {
      // Falls back to demo coords silently — user still sees map tiles.
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _center {
    if (!widget.route) return _userLocation ?? RideMap._demo;
    return _midpoint(_pickupPoint, _dropPoint);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: AppColors.mapBackground,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _userLocation ?? _center,
            zoom: widget.route ? 12.2 : 14.5,
          ),
          onMapCreated: (c) => _mapController = c,
          markers: _buildMarkers(),
          polylines: widget.route ? _buildPolylines() : {},
          // myLocationEnabled shows the native blue accuracy dot — the same
          // "you are here" indicator used by Google Maps, Rapido, Ola, Uber.
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          buildingsEnabled: true,
          indoorViewEnabled: false,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.route) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ));
      markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: _dropPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop'),
      ));
    }

    // Driver / car marker (yellow) — position updated from outside for live tracking
    if (widget.car) {
      final carPos = widget.driverPosition ??
          (widget.route
              ? _pointAlong(_pickupPoint, _dropPoint, widget.dense ? 0.45 : 0.60)
              : (_userLocation ?? RideMap._demo));
      markers.add(Marker(
        markerId: const MarkerId('car'),
        position: carPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(title: 'Your Ride'),
        rotation: 45,
      ));
    }

    return markers;
  }
  Set<Polyline> _buildPolylines() {
    final points = (widget.routePoints != null && widget.routePoints!.isNotEmpty)
        ? widget.routePoints!
        : [_pickupPoint, _pointAlong(_pickupPoint, _dropPoint, 0.5), _dropPoint];

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: AppColors.info,
        width: 5,
        patterns: const [],
      ),
    };
  }
  static LatLng _midpoint(LatLng a, LatLng b) =>
      LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);

  static LatLng _pointAlong(LatLng a, LatLng b, double t) =>
      LatLng(a.latitude + (b.latitude - a.latitude) * t,
             a.longitude + (b.longitude - a.longitude) * t);
}
