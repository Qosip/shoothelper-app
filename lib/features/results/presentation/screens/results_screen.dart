import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/domain/entities/settings_result.dart';
import '../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../shared/presentation/providers/scene_providers.dart';
import '../../../../shared/presentation/theme/app_colors.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(settingsResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/scene-input'),
        ),
      ),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (result) {
          if (result == null) {
            return const Center(child: Text('Aucun résultat'));
          }
          return _ResultsContent(result: result);
        },
      ),
    );
  }
}

class _ResultsContent extends StatelessWidget {
  final SettingsResult result;

  const _ResultsContent({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Scene summary + confidence
        _ConfidenceBanner(
          sceneSummary: result.sceneSummary,
          confidence: result.confidence,
        ),
        const SizedBox(height: 16),

        // Exposure summary card (4 main values)
        _ExposureSummaryCard(result: result),
        const SizedBox(height: 16),

        // Compromises
        if (result.compromises.isNotEmpty) ...[
          ...result.compromises.map((c) => _CompromiseCard(compromise: c)),
          const SizedBox(height: 16),
        ],

        // All settings list
        Text('Tous les réglages',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...result.settings.map((s) => _SettingRow(setting: s)),
      ],
    );
  }
}

class _ConfidenceBanner extends StatelessWidget {
  final String sceneSummary;
  final Confidence confidence;

  const _ConfidenceBanner({
    required this.sceneSummary,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (confidence) {
      Confidence.high => AppColors.confidenceHigh,
      Confidence.medium => AppColors.confidenceMedium,
      Confidence.low => AppColors.confidenceLow,
    };
    final label = switch (confidence) {
      Confidence.high => 'Confiance haute',
      Confidence.medium => 'Confiance moyenne',
      Confidence.low => 'Confiance basse',
    };

    return Card(
      color: color.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sceneSummary,
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(label,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExposureSummaryCard extends StatelessWidget {
  final SettingsResult result;

  const _ExposureSummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String val(String id) =>
        result.findSetting(id)?.valueDisplay ?? '-';

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ExposureValue(label: 'Ouverture', value: val('aperture')),
            _ExposureValue(label: 'Vitesse', value: val('shutter_speed')),
            _ExposureValue(label: 'ISO', value: val('iso')),
            _ExposureValue(label: 'Mode', value: val('exposure_mode')),
          ],
        ),
      ),
    );
  }
}

class _ExposureValue extends StatelessWidget {
  final String label;
  final String value;

  const _ExposureValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer)),
        const SizedBox(height: 4),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withAlpha(180))),
      ],
    );
  }
}

class _CompromiseCard extends StatelessWidget {
  final Compromise compromise;

  const _CompromiseCard({required this.compromise});

  @override
  Widget build(BuildContext context) {
    final color = switch (compromise.severity) {
      CompromiseSeverity.critical => AppColors.compromiseCritical,
      CompromiseSeverity.warning => AppColors.compromiseWarning,
      CompromiseSeverity.info => AppColors.compromiseInfo,
    };
    final icon = switch (compromise.severity) {
      CompromiseSeverity.critical => Icons.error,
      CompromiseSeverity.warning => Icons.warning_amber,
      CompromiseSeverity.info => Icons.info_outline,
    };

    return Card(
      color: color.withAlpha(20),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(compromise.message,
                      style: Theme.of(context).textTheme.bodySmall),
                  if (compromise.suggestion.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(compromise.suggestion,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final SettingRecommendation setting;

  const _SettingRow({required this.setting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () =>
            context.go('/results/setting/${setting.settingId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_settingName(setting.settingId),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(setting.explanationShort,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(setting.valueDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  static String _settingName(String id) => switch (id) {
        'aperture' => 'Ouverture',
        'shutter_speed' => 'Vitesse',
        'iso' => 'ISO',
        'exposure_mode' => 'Mode expo',
        'af_mode' => 'Mode AF',
        'af_area' => 'Zone AF',
        'metering' => 'Mesure',
        'white_balance' => 'Balance blancs',
        'drive' => 'Mode drive',
        'stabilization' => 'Stabilisation',
        'file_format' => 'Format fichier',
        _ => id,
      };
}
