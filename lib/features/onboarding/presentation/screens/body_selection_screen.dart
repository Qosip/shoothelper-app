import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
import '../providers/onboarding_providers.dart';

class BodySelectionScreen extends ConsumerWidget {
  const BodySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final selectedId = ref.watch(selectedBodyIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Choisis ton boîtier', style: AppTypography.headline),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: catalog == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: catalog.bodies.length,
              itemBuilder: (context, index) {
                final body = catalog.bodies[index];
                final isSelected = body.id == selectedId;
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
                        ? Border.all(color: AppColors.blueOptique, width: 1.5)
                        : null,
                  ),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedBodyIdProvider.notifier).state =
                          body.id;
                      final locale =
                          Localizations.localeOf(context).languageCode;
                      final lang = body.languages.contains(locale)
                          ? locale
                          : body.languages.first;
                      ref.read(selectedLanguageProvider.notifier).state =
                          lang;
                      ref.read(selectedLensIdsProvider.notifier).state = [];
                    },
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusCard),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.camera,
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
                                Row(
                                  children: [
                                    Text(body.displayName,
                                        style: AppTypography.title),
                                    if (body.isFullSupport) ...[
                                      const SizedBox(width: AppSpacing.sm),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.blueOptique
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppSpacing.radiusChip),
                                        ),
                                        child: Text(
                                          'Full',
                                          style:
                                              AppTypography.caption.copyWith(
                                            color: AppColors.blueOptique,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  body.isFullSupport
                                      ? '${_sensorLabel(body.sensorSize)} · ${body.lenses.length} objectif(s) · Navigation menu'
                                      : '${_sensorLabel(body.sensorSize)} · Réglages uniquement',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(LucideIcons.checkCircle,
                                size: 20, color: AppColors.blueOptique),
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
          onPressed: selectedId != null
              ? () => context.go('/onboarding/lens')
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

  static String _sensorLabel(String s) => switch (s) {
        'aps-c' => 'APS-C',
        'full-frame' => 'Plein format',
        'micro-four-thirds' => 'Micro 4/3',
        _ => s,
      };
}
