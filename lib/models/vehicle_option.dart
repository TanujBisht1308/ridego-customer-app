import 'package:flutter/material.dart';

class VehicleOption {
  final String id; // matches backend vehicleType key: bike/auto/mini/sedan
  final String name;
  final String priceRange;
  final String eta;
  final String seats;
  final IconData icon;
  final String imagePath;
  bool selected;

  VehicleOption({
    required this.id,
    required this.name,
    required this.priceRange,
    required this.eta,
    required this.seats,
    required this.icon,
    required this.imagePath,
    this.selected = false,
  });
}