import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ShootHelper V2 typography — Inter + JetBrains Mono.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §Typographie
class AppTypography {
  AppTypography._();

  // === Display — hero values (f/2.8 in detail) ===
  static TextStyle display = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // === Headline — screen titles ===
  static TextStyle headline = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  // === Title — section titles ===
  static TextStyle title = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  // === Body — explanations, descriptions ===
  static TextStyle body = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  // === Caption — hints, secondary labels ===
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // === Overline — category labels (UPPERCASE) ===
  static TextStyle overline = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );

  // === Mono — menu paths, technical values ===
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // === Value — setting values with tabular figures ===
  static TextStyle value = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Build a Material 3 TextTheme from our styles.
  static TextTheme get textTheme => TextTheme(
        displayLarge: display,
        headlineMedium: headline,
        titleMedium: title,
        bodyMedium: body,
        bodySmall: caption,
        labelSmall: overline,
      );
}
