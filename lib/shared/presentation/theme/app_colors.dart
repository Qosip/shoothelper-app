import 'package:flutter/material.dart';

/// ShootHelper V2 color palette.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §Palette
class AppColors {
  AppColors._();

  // === Primary ===
  static const darkBackground = Color(0xFF0D0D0D);
  static const lightBackground = Color(0xFFF5F3EF);
  static const blueOptique = Color(0xFF2E7DBA);
  static const blueOptique10 = Color(0x1A2E7DBA);

  // === Semantic ===
  static const success = Color(0xFF2DA44E);
  static const warning = Color(0xFFD4740C);
  static const critical = Color(0xFFCF222E);
  static const info = Color(0xFF6E7781);

  // === Surfaces — Dark ===
  static const darkSurface1 = Color(0xFF1C1C1E);
  static const darkSurface2 = Color(0xFF2C2C2E);
  static const darkDivider = Color(0xFF38383A);

  // === Surfaces — Light ===
  static const lightSurface1 = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFF2F2F7);
  static const lightDivider = Color(0xFFE5E5EA);

  // === Photo / EV indicators ===
  static const evLow = Color(0xFF6366F1);
  static const evMedium = Color(0xFFF59E0B);
  static const evHigh = Color(0xFFEF4444);

  // === Text ===
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFF8E8E93);
  static const lightTextPrimary = Color(0xFF1C1C1E);
  static const lightTextSecondary = Color(0xFF6E7781);

  // === Compromise severity (aliases) ===
  static const compromiseCritical = critical;
  static const compromiseWarning = warning;
  static const compromiseInfo = blueOptique;

  // === Confidence ===
  static const confidenceHigh = success;
  static const confidenceMedium = warning;
  static const confidenceLow = critical;

  // === Chip states ===
  static const chipSelectedBg = blueOptique;
  static const chipSelectedFg = Color(0xFFFFFFFF);
  static const chipSuggestedBorder = blueOptique;

  // === Legacy aliases for compatibility ===
  static const primary = blueOptique;
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = warning;
  static const onSecondary = Color(0xFFFFFFFF);
  static const tertiary = success;
  static const onTertiary = Color(0xFFFFFFFF);
  static const surface = lightSurface1;
  static const onSurface = lightTextPrimary;
  static const error = critical;
  static const onError = Color(0xFFFFFFFF);
}
