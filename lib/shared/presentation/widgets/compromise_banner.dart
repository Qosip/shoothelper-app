import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Severity level for compromise banners.
enum CompromiseSeverity { warning, critical }

/// Compact alert banner for compromises.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §CompromiseBanner
class CompromiseBanner extends StatelessWidget {
  final String text;
  final CompromiseSeverity severity;
  final VoidCallback? onTap;

  const CompromiseBanner({
    super.key,
    required this.text,
    this.severity = CompromiseSeverity.warning,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      CompromiseSeverity.warning => AppColors.warning,
      CompromiseSeverity.critical => AppColors.critical,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              severity == CompromiseSeverity.critical
                  ? LucideIcons.alertTriangle
                  : LucideIcons.alertCircle,
              size: 20,
              color: color,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: AppTypography.body.copyWith(color: color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              Icon(LucideIcons.chevronRight, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
