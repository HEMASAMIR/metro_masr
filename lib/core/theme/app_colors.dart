import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Ultra Minimalist (Apple/Uber vibe)
  static const Color primary = Color(0xFF000000); // Pure Black
  static const Color accent = Color(0xFF007AFF);  // System Blue

  // Metro Line Colors (Unchanged for logic/identification)
  static const Color line1 = Color(0xFFE11D48); 
  static const Color line2 = Color(0xFFF59E0B); 
  static const Color line3 = Color(0xFF10B981); 

  // Background & Surface
  static const Color background = Color(0xFFF9F9F9); // Very light grey for main scaffold
  static const Color surface = Colors.white;         // Pure white for cards/elements
  
  // Dark Mode Tokens (Muted grayscale)
  static const Color backgroundDark = Color(0xFF000000); // True black
  static const Color surfaceDark = Color(0xFF121212);    // Very dark grey
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA1A1AA); // Zinc 400

  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF71717A); // Zinc 500
  static const Color textOnPrimary = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF34C759); // iOS Green
  static const Color warning = Color(0xFFFF9500); // iOS Orange
  static const Color error = Color(0xFFFF3B30);   // iOS Red
  static const Color info = Color(0xFF007AFF);    // System Blue
}
