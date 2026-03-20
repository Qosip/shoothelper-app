import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';
import '../../../../shared/presentation/providers/gear_profile_provider.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';

/// Bottom sheet to quickly switch the active lens.
class LensQuickSwitchSheet extends ConsumerWidget {
  const LensQuickSwitchSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gearProfileProvider);
    final activeId = profile.activeLensId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ref.watch(cameraDataCacheProvider).when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: Text('Erreur de chargement')),
          ),
          data: (cache) {
            final allLenses = cache.allLenses;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Text('OBJECTIF ACTIF', style: AppTypography.overline),
                    const SizedBox(height: AppSpacing.md),
                    ...allLenses.map((lens) {
                      final isActive = lens.id == activeId;
                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.blueOptique
                                  .withValues(alpha: 0.1)
                              : (isDark
                                  ? AppColors.darkSurface1
                                  : AppColors.lightSurface1),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusCard),
                          border: isActive
                              ? Border.all(
                                  color: AppColors.blueOptique,
                                  width: 1.5)
                              : null,
                        ),
                        child: InkWell(
                          onTap: isActive
                              ? null
                              : () async {
                                  await profile.setActiveLens(lens.id);
                                  ref.invalidate(gearProfileProvider);
                                  ref.invalidate(cameraDataCacheProvider);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusCard),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppSpacing.base),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.aperture,
                                  size: 20,
                                  color: isActive
                                      ? AppColors.blueOptique
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors
                                              .lightTextSecondary),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lens.displayName,
                                        style:
                                            AppTypography.title.copyWith(
                                          color: isActive
                                              ? AppColors.blueOptique
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        '${lens.focalLength.minMm}-${lens.focalLength.maxMm}mm f/${lens.aperture.maxAperture}',
                                        style: AppTypography.caption
                                            .copyWith(
                                          color: isDark
                                              ? AppColors
                                                  .darkTextSecondary
                                              : AppColors
                                                  .lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  Icon(LucideIcons.checkCircle,
                                      size: 20,
                                      color: AppColors.blueOptique),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
  }
}
