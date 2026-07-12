import 'package:flutter/material.dart';

/// Central colour palette for the Glossy app.
/// All values are `const` so they resolve at compile-time.
abstract final class AppColors {
  static const Color primary = Color(0xFFC2703D); // muted orange/brown
  static const Color paper = Color(0xFFFBF9F6); // warm white
  static const Color stage = Color(0xFFF1EEE7); // warm off-white
  static const Color ink = Color(0xFF2B2724); // dark grey
  static const Color secondary = Color(0xFFEAE5DC); // light warm grey
  static const Color muted = Color(0xFF8C8782); // medium grey
  static const Color success = Color(0xFF4F9D5C); // green
  static const Color warning = Color(0xFFD9A93B); // amber
  static const Color danger = Color(0xFFC4422E); // red
  static const Color border = Color(0x142B2724); // ink @ 8 % opacity
}
