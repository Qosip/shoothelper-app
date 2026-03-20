import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/gear_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyAsync = ref.watch(currentBodyProvider);
    final lensAsync = ref.watch(currentLensProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('ShootHelper', style: AppTypography.headline),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gear badge
            bodyAsync.when(
              loading: () => const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erreur: $e'),
              data: (body) => lensAsync.when(
                loading: () => GearBadge(
                  bodyName: body.displayName,
                  lensName: '...',
                  onTap: () => context.go('/settings'),
                ),
                error: (e, _) => GearBadge(
                  bodyName: body.displayName,
                  lensName: 'Erreur',
                  onTap: () => context.go('/settings'),
                ),
                data: (lens) => GearBadge(
                  bodyName: body.displayName,
                  lensName: lens.displayName,
                  onTap: () => context.go('/settings'),
                ),
              ),
            ),

            const Spacer(),

            // Main CTA
            FilledButton(
              onPressed: () => context.go('/scene-input'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.blueOptique,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.camera, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Nouveau shoot', style: AppTypography.title.copyWith(color: Colors.white)),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Photo tip
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface1 : AppColors.lightSurface2,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.lightbulb,
                    size: 18,
                    color: AppColors.evMedium,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Astuce du jour',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'La golden hour commence environ 1h avant le coucher du soleil. '
                          'La lumière y est douce et chaude — idéale pour les portraits.',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
