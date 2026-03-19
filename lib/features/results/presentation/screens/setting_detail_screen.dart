import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/domain/entities/settings_result.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';
import '../../../../shared/presentation/providers/scene_providers.dart';
import '../../../../shared/presentation/widgets/error_display.dart';

class SettingDetailScreen extends ConsumerWidget {
  final String settingId;

  const SettingDetailScreen({super.key, required this.settingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(settingsResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_settingName(settingId)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
    final theme = Theme.of(context);
    final hasNavPath = ref.watch(cameraDataCacheProvider).whenOrNull(
          data: (cache) => cache.getNavPath(settingId) != null,
        ) ??
        false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Value display
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(setting.valueDisplay,
                    style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer)),
                const SizedBox(height: 8),
                Text(setting.explanationShort,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Detailed explanation
        if (setting.explanationDetail.isNotEmpty) ...[
          Text('Pourquoi ce réglage ?',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(setting.explanationDetail,
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
        ],

        // Alternatives
        if (setting.alternatives.isNotEmpty) ...[
          Text('Alternatives',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...setting.alternatives.map((alt) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(alt.valueDisplay,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(alt.tradeOff,
                                style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                      if (alt.cascadeChanges.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            alt.cascadeChanges
                                .map((c) =>
                                    '${c.settingId}: ${c.fromValue} → ${c.toValue}')
                                .join(', '),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],

        // Navigate to menu — only if nav path exists
        if (hasNavPath)
          FilledButton.icon(
            onPressed: () =>
                context.go('/results/setting/$settingId/menu-nav'),
            icon: const Icon(Icons.menu_book),
            label: const Text('Comment régler ?'),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Le chemin dans les menus n\'est pas encore documenté pour ton boîtier.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
