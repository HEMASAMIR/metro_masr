import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Blue & White Theme
  static const Color primary = Color(0xFF1565C0); // Deep Blue
  static const Color accent = Color(0xFF42A5F5);  // Light Blue

  // Metro Line Colors (Unchanged for logic/identification)
  static const Color line1 = Color(0xFFE11D48);
  static const Color line2 = Color(0xFFF59E0B);
  static const Color line3 = Color(0xFF10B981);

  // Background & Surface (Light)
  static const Color background = Color(0xFFF5F8FF); // Very light blue-white
  static const Color surface = Color(0xFFFFFFFF);    // Pure white

  // Dark Mode Tokens (Deep Navy Blue)
  static const Color backgroundDark = Color(0xFF0D1B2A); // Deep navy
  static const Color surfaceDark = Color(0xFF1A2E45);    // Dark navy blue
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF90B4D4); // Muted blue-grey

  // Text Colors
  static const Color textPrimary = Color(0xFF0D1B2A);     // Very dark navy
  static const Color textSecondary = Color(0xFF546E8A);   // Blue-grey
  static const Color textOnPrimary = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF2E7D32); // Green
  static const Color warning = Color(0xFFF57C00); // Orange
  static const Color error = Color(0xFFC62828);   // Red
  static const Color info = Color(0xFF1565C0);    // Same as primary blue
}
