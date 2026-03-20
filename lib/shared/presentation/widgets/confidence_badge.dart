import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Confidence level for recommendations.
enum ConfidenceLevel { high, medium, low }

/// Colored badge showing confidence level (green/orange/red) + text.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §ConfidenceBadge
class ConfidenceBadge extends StatelessWidget {
  final ConfidenceLevel level;

  const ConfidenceBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (level) {
      ConfidenceLevel.high => (AppColors.confidenceHigh, 'Confiance haute'),
      ConfidenceLevel.medium => (AppColors.confidenceMedium, 'Compromis'),
      ConfidenceLevel.low => (AppColors.confidenceLow, 'Confiance faible'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
