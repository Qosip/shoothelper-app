import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/domain/entities/settings_result.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';
import '../../../../shared/presentation/providers/scene_providers.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/error_display.dart';
import '../../../../shared/presentation/widgets/setting_card.dart';

class SettingDetailScreen extends ConsumerWidget {
  final String settingId;

  const SettingDetailScreen({super.key, required this.settingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(settingsResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_settingName(settingId), style: AppTypography.headline),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/results'),
        ),
      ),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorDisplay(
          failure: mapToFailure(e),
          onAction: () => ref.invalidate(settingsResultProvider),
        ),
        data: (result) {
          if (result == null) {
            return const Center(child: Text('Aucun résultat'));
          }
          final setting = result.findSetting(settingId);
          if (setting == null) {
            return Center(child: Text('Réglage "$settingId" non trouvé'));
          }
          return _DetailContent(setting: setting, settingId: settingId);
        },
      ),
    );
  }

  static String _settingName(String id) => switch (id) {
        'aperture' => 'Ouverture',
        'shutter_speed' => 'Vitesse',
        'iso' => 'ISO',
        'exposure_mode' => 'Mode exposition',
        'af_mode' => 'Mode autofocus',
        'af_area' => 'Zone autofocus',
        'metering' => 'Mode de mesure',
        'white_balance' => 'Balance des blancs',
        'drive' => 'Mode drive',
        'stabilization' => 'Stabilisation',
        'file_format' => 'Format fichier',
        _ => id,
      };
}

class _DetailContent extends ConsumerWidget {
  final SettingRecommendation setting;
  final String settingId;

  const _DetailContent({required this.setting, required this.settingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasNavPath = ref.watch(cameraDataCacheProvider).whenOrNull(
              data: (cache) => cache.getNavPath(settingId) != null,
            ) ??
        false;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // Hero value card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.darkSurface1, AppColors.darkSurface2]
                  : [AppColors.lightSurface1, AppColors.lightSurface2],
            ),
          ),
          child: Column(
            children: [
              Icon(
                SettingCard.iconForSetting(settingId),
                size: 32,
                color: AppColors.blueOptique,
              ),
              const SizedBox(height: AppSpacing.md),
              Hero(
                tag: 'setting_value_$settingId',
                flightShuttleBuilder:
                    (_, animation, direction, fromContext, toContext) =>
                        DefaultTextStyle(
                  style: DefaultTextStyle.of(toContext).style,
                  child: toContext.widget,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    setting.valueDisplay,
                    style: AppTypography.display.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                setting.explanationShort,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Detailed explanation
        if (setting.explanationDetail.isNotEmpty) ...[
          Text('POURQUOI CE RÉGLAGE', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface1 : AppColors.lightSurface1,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Text(setting.explanationDetail, style: AppTypography.body),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Alternatives
        if (setting.alternatives.isNotEmpty) ...[
          Text('ALTERNATIVES', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          ...setting.alternatives.map((alt) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface1
                      : AppColors.lightSurface1,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          alt.valueDisplay,
                          style: AppTypography.value.copyWith(
                            color: AppColors.blueOptique,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            alt.tradeOff,
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (alt.cascadeChanges.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          alt.cascadeChanges
                              .map((c) =>
                                  '${c.settingId}: ${c.fromValue} → ${c.toValue}')
                              .join(', '),
                          style: AppTypography.mono.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Navigate to menu
        if (hasNavPath)
          FilledButton(
            onPressed: () =>
                context.go('/results/setting/$settingId/menu-nav'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.blueOptique,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.menuSquare, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text('Comment régler ?',
                    style: AppTypography.title
                        .copyWith(color: Colors.white)),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Le chemin dans les menus n\'est pas encore documenté pour ton boîtier.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
