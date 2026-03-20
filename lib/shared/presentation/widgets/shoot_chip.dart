import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Custom chip with 4 states: default, selected, suggested, disabled.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §ShootChip
enum ShootChipState { defaultState, selected, suggested, disabled }

class ShootChip extends StatelessWidget {
  final String label;
  final ShootChipState state;
  final IconData? icon;
  final VoidCallback? onTap;

  const ShootChip({
    super.key,
    required this.label,
    this.state = ShootChipState.defaultState,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = state == ShootChipState.disabled;
    final isSelected = state == ShootChipState.selected;
    final isSuggested = state == ShootChipState.suggested;

    final bgColor = isSelected
        ? AppColors.blueOptique
        : isDark
            ? AppColors.darkSurface1
            : AppColors.lightSurface1;

    final fgColor = isSelected
        ? Colors.white
        : isDisabled
            ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                .withValues(alpha: 0.5)
            : isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary;

    final borderColor = isSelected
        ? Colors.transparent
        : isSuggested
            ? AppColors.blueOptique
            : isDark
                ? AppColors.darkDivider
                : AppColors.lightDivider;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: icon != null ? AppSpacing.md : AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          border: Border.all(
            color: borderColor,
            width: isSuggested ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fgColor),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: fgColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
