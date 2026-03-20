import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
import '../providers/onboarding_providers.dart';

class LensSelectionScreen extends ConsumerWidget {
  const LensSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final bodyId = ref.watch(selectedBodyIdProvider);
    final selectedLensIds = ref.watch(selectedLensIdsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = catalog?.findBody(bodyId ?? '');
    final lenses = body?.lenses ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Choisis tes objectifs', style: AppTypography.headline),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/onboarding/body'),
        ),
      ),
      body: lenses.isEmpty
          ? const Center(child: Text('Aucun objectif disponible'))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: lenses.length,
              itemBuilder: (context, index) {
                final lens = lenses[index];
                final isSelected = selectedLensIds.contains(lens.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blueOptique.withValues(alpha: 0.1)
                        : (isDark
                            ? AppColors.darkSurface1
                            : AppColors.lightSurface1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusCard),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.blueOptique, width: 1.5)
                        : null,
                  ),
                  child: InkWell(
                    onTap: () {
                      final notifier =
                          ref.read(selectedLensIdsProvider.notifier);
                      if (isSelected) {
                        notifier.state = selectedLensIds
                            .where((id) => id != lens.id)
                            .toList();
                      } else {
                        notifier.state = [...selectedLensIds, lens.id];
                      }
                    },
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusCard),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.aperture,
                            color: isSelected
                                ? AppColors.blueOptique
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(lens.displayName,
                                    style: AppTypography.title),
                                if (lens.isKitLens)
                                  Text(
                                    'Objectif kit',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.blueOptique,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? LucideIcons.checkCircle
                                : LucideIcons.circle,
                            size: 20,
                            color: isSelected
                                ? AppColors.blueOptique
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: FilledButton(
          onPressed: selectedLensIds.isNotEmpty
              ? () => context.go('/onboarding/language')
              : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: AppColors.blueOptique,
          ),
          child: Text('Suivant',
              style: AppTypography.title.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
}
