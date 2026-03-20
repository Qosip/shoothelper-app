import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Compact badge showing body + lens (e.g. "A6700 + Sigma 18-50").
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §GearBadge
class GearBadge extends StatelessWidget {
  final String bodyName;
  final String lensName;
  final VoidCallback? onTap;

  const GearBadge({
    super.key,
    required this.bodyName,
    required this.lensName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.camera, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              bodyName,
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                '+',
                style: AppTypography.caption.copyWith(color: iconColor),
              ),
            ),
            Icon(LucideIcons.aperture, size: 16, color: iconColor),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                lensName,
                style: AppTypography.body.copyWith(color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              Icon(LucideIcons.chevronRight, size: 16, color: iconColor),
          ],
        ),
      ),
    );
  }
}
