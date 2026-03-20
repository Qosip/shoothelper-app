import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Sticky bottom bar with glassmorphism (blur) effect.
/// Ref: V2_SKILLS_ROADMAP.md V2-01 §BottomStickyBar
class BottomStickyBar extends StatelessWidget {
  final Widget child;

  const BottomStickyBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkBackground : AppColors.lightBackground)
                .withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.md,
            AppSpacing.base,
            AppSpacing.md + bottomPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
