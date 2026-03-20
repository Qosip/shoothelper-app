import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'confidence_badge.dart';

/// Exposure summary header — 4 big values with gradient background.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §SummaryHeader
class SummaryHeader extends StatelessWidget {
  final String aperture;
  final String shutterSpeed;
  final String iso;
  final String exposureMode;
  final ConfidenceLevel confidence;

  const SummaryHeader({
    super.key,
    required this.aperture,
    required this.shutterSpeed,
    required this.iso,
    required this.exposureMode,
    this.confidence = ConfidenceLevel.high,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkSurface1,
                  AppColors.darkSurface2,
                ]
              : [
                  AppColors.lightSurface1,
                  AppColors.lightSurface2,
                ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ValueTile(label: 'Ouverture', value: aperture, isDark: isDark),
              _ValueTile(label: 'Vitesse', value: shutterSpeed, isDark: isDark),
              _ValueTile(label: 'ISO', value: iso, isDark: isDark),
              _ValueTile(label: 'Mode', value: exposureMode, isDark: isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ConfidenceBadge(level: confidence),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _ValueTile({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.overline.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.display.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
