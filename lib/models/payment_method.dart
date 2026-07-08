import 'package:flutter/material.dart';

class PaymentMethodModel {
  final String title;
  final String subtitle;
  final IconData icon;
  bool selected;

  PaymentMethodModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.selected = false,
  });
}
