import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Variant for SettingCard appearance.
enum SettingCardVariant { normal, compromised, overridden }

/// Card displaying a single setting recommendation.
/// Layout: icon | name + explanation | value | chevron
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §SettingCard
class SettingCard extends StatelessWidget {
  final String settingName;
  final String explanation;
  final String valueDisplay;
  final IconData? icon;
  final SettingCardVariant variant;
  final VoidCallback? onTap;

  const SettingCard({
    super.key,
    required this.settingName,
    required this.explanation,
    required this.valueDisplay,
    this.icon,
    this.variant = SettingCardVariant.normal,
    this.onTap,
  });

  /// Map setting IDs to appropriate icons.
  static IconData iconForSetting(String settingId) {
    return switch (settingId) {
      'aperture' => LucideIcons.aperture,
      'shutter_speed' => LucideIcons.timer,
      'iso' => LucideIcons.gauge,
      'af_mode' || 'af_area' => LucideIcons.focus,
      'metering' => LucideIcons.scan,
      'white_balance' => LucideIcons.thermometer,
      'exposure_mode' => LucideIcons.sliders,
      'drive' => LucideIcons.layers,
      'stabilization' => LucideIcons.move,
      'file_format' => LucideIcons.file,
      _ => LucideIcons.settings,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface1 : AppColors.lightSurface1;
    final borderColor = switch (variant) {
      SettingCardVariant.compromised => AppColors.warning,
      SettingCardVariant.overridden => AppColors.blueOptique,
      SettingCardVariant.normal => Colors.transparent,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: borderColor,
            width: variant == SettingCardVariant.normal ? 0 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Icon(
              icon ?? LucideIcons.settings,
              size: 22,
              color: variant == SettingCardVariant.compromised
                  ? AppColors.warning
                  : AppColors.blueOptique,
            ),
            const SizedBox(width: AppSpacing.md),

            // Name + explanation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settingName,
                    style: AppTypography.title.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    explanation,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Value
            Text(
              valueDisplay,
              style: AppTypography.value.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Chevron
            if (onTap != null)
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
