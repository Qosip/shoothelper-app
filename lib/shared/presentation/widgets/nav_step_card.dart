import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Card for a single menu navigation step with timeline connector.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §NavStepCard
class NavStepCard extends StatelessWidget {
  final int stepNumber;
  final String text;
  final bool isLast;
  final bool isActive;

  const NavStepCard({
    super.key,
    required this.stepNumber,
    required this.text,
    this.isLast = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isLast ? AppColors.blueOptique : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline: circle + connector line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isLast
                        ? AppColors.blueOptique
                        : (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(color: AppColors.blueOptique, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$stepNumber',
                    style: AppTypography.caption.copyWith(
                      color: isLast
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Step content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: isLast
                    ? AppColors.blueOptique10
                    : (isDark ? AppColors.darkSurface1 : AppColors.lightSurface1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: isLast
                    ? Border.all(color: AppColors.blueOptique, width: 1)
                    : null,
              ),
              child: Text(
                text,
                style: (isLast ? AppTypography.mono : AppTypography.body).copyWith(
                  color: accentColor ??
                      (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
