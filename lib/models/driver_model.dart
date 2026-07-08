import 'package:flutter/material.dart';


class DriverModel {
  final String name;
  final String rating;
  final String vehicle;
  final String vehicleNumber;
  final String phone;

  const DriverModel({
    required this.name,
    required this.rating,
    required this.vehicle,
    required this.vehicleNumber,
    required this.phone,
  });
}
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