import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Expand/collapse toggle with rotating arrow and optional counter badge.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §ExpandToggle
class ExpandToggle extends StatelessWidget {
  final String label;
  final bool isExpanded;
  final int? badgeCount;
  final VoidCallback? onTap;

  const ExpandToggle({
    super.key,
    required this.label,
    required this.isExpanded,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.title.copyWith(color: textColor),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueOptique,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(
                LucideIcons.chevronDown,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
