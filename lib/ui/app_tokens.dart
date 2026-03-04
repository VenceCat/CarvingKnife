import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

abstract final class AppRadii {
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 180);
}

abstract final class AppTypography {
  static const TextStyle pageTitle = TextStyle(
    letterSpacing: 1.5,
    fontWeight: FontWeight.w400,
    fontSize: 24,
  );
}
