import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Horizontal divider with an optional centered label.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §SectionDivider
class SectionDivider extends StatelessWidget {
  final String? label;

  const SectionDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (label == null) {
      return Divider(color: dividerColor, height: AppSpacing.xl);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              label!,
              style: AppTypography.overline.copyWith(color: textColor),
            ),
          ),
          Expanded(child: Divider(color: dividerColor)),
        ],
      ),
    );
  }
}
