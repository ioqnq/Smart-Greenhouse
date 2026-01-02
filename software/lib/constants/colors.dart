import 'package:flutter/material.dart';

/// Paleta oficială Smart Greenhouse
class AppColors {
  // Brand / Primary colors
  // static const Color primary = Color.fromARGB(255, 138, 245, 88);
  // static const Color primaryDark = Color.fromARGB(255, 72, 183, 25);
  static const Color primary = Color.fromARGB(224, 138, 229, 96);
  static const Color primaryDark = Color.fromARGB(255, 116, 203, 79);
  static const Color primaryLight = Color.fromARGB(255, 234, 254, 221);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFE53935);

  // UI background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textDark = Color(0xFF2E2E2E);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF8A8A8A);

  // Sensor card colors (pentru Dashboard)
  static const Color temperature = Color(0xFFE57373); // Red-ish
  static const Color humidity = Color(0xFF64B5F6);    // Blue-ish
}
