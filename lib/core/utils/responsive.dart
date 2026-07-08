import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  static double scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return .88;
    if (width < 420) return .95;
    if (width > 700) return 1.10;
    return 1.0;
  }

  static double font(BuildContext context, double value) => value * scale(context);

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 700) {
      return EdgeInsets.symmetric(horizontal: width * .24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  }
}
