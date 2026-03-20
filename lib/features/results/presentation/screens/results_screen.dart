import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/domain/entities/settings_result.dart';
import '../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../shared/presentation/providers/scene_providers.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/compromise_banner.dart'
    as banner;
import '../../../../shared/presentation/widgets/confidence_badge.dart';
import '../../../../shared/presentation/widgets/error_display.dart';
import '../../../../shared/presentation/widgets/setting_card.dart';
import '../../../../shared/presentation/widgets/summary_header.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(settingsResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats', style: AppTypography.headline),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/scene-input'),
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
    String val(String id) =>
        result.findSetting(id)?.valueDisplay ?? '-';

    final confidenceLevel = switch (result.confidence) {
      Confidence.high => ConfidenceLevel.high,
      Confidence.medium => ConfidenceLevel.medium,
      Confidence.low => ConfidenceLevel.low,
    };

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // Exposure summary with gradient + confidence badge
        SummaryHeader(
          aperture: val('aperture'),
          shutterSpeed: val('shutter_speed'),
          iso: val('iso'),
          exposureMode: val('exposure_mode'),
          confidence: confidenceLevel,
        ),
        const SizedBox(height: AppSpacing.base),

        // Compromises
        if (result.compromises.isNotEmpty) ...[
          ...result.compromises.map((c) {
            final severity = switch (c.severity) {
              CompromiseSeverity.critical =>
                banner.CompromiseSeverity.critical,
              CompromiseSeverity.warning =>
                banner.CompromiseSeverity.warning,
              CompromiseSeverity.info => banner.CompromiseSeverity.warning,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: banner.CompromiseBanner(
                text: c.message,
                severity: severity,
              ),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Settings list
        Text('TOUS LES RÉGLAGES', style: AppTypography.overline),
        const SizedBox(height: AppSpacing.md),
        ...result.settings.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SettingCard(
                settingName: _settingName(s.settingId),
                explanation: s.explanationShort,
                valueDisplay: s.valueDisplay,
                icon: SettingCard.iconForSetting(s.settingId),
                heroTag: 'setting_value_${s.settingId}',
                variant: s.isCompromised
                    ? SettingCardVariant.compromised
                    : SettingCardVariant.normal,
                onTap: () =>
                    context.go('/results/setting/${s.settingId}'),
              ),
            )),
      ],
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
