import 'package:flutter/material.dart';

/// ShootHelper color palette.
class AppColors {
  // Primary — camera/photo inspired deep blue
  static const primary = Color(0xFF1565C0);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFD1E4FF);
  static const onPrimaryContainer = Color(0xFF001D36);

  // Secondary — warm amber for accents
  static const secondary = Color(0xFFE65100);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFFDBC8);
  static const onSecondaryContainer = Color(0xFF2B0A00);

  // Tertiary — green for success/confidence
  static const tertiary = Color(0xFF2E7D32);
  static const onTertiary = Color(0xFFFFFFFF);

  // Surface
  static const surface = Color(0xFFF8F9FA);
  static const onSurface = Color(0xFF1A1C1E);
  static const surfaceVariant = Color(0xFFE7E0EC);
  static const onSurfaceVariant = Color(0xFF49454F);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);

  // Compromise severity colors
  static const compromiseCritical = Color(0xFFD32F2F);
  static const compromiseWarning = Color(0xFFED6C02);
  static const compromiseInfo = Color(0xFF0288D1);

  // Confidence colors
  static const confidenceHigh = Color(0xFF2E7D32);
  static const confidenceMedium = Color(0xFFED6C02);
  static const confidenceLow = Color(0xFFD32F2F);
}
