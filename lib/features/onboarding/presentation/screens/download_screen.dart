import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/presentation/providers/gear_profile_provider.dart';
import '../providers/onboarding_providers.dart';

class DownloadScreen extends ConsumerWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final bodyId = ref.watch(selectedBodyIdProvider);
    final selectedLensIds = ref.watch(selectedLensIdsProvider);
    final selectedLang = ref.watch(selectedLanguageProvider);
    final progress = ref.watch(downloadProgressProvider);
    final status = ref.watch(downloadStatusProvider);
    final error = ref.watch(downloadErrorProvider);
    final theme = Theme.of(context);

    final body = catalog?.findBody(bodyId ?? '');
    final lensNames = body?.lenses
            .where((l) => selectedLensIds.contains(l.id))
            .map((l) => l.displayName)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Récapitulatif'),
        leading: status != DownloadStatus.downloading
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/onboarding/language'),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recap
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RecapRow(
                        label: 'Boîtier',
                        value: body?.displayName ?? '-'),
                    const SizedBox(height: 8),
                    _RecapRow(
                        label: 'Objectif(s)',
                        value: lensNames.isEmpty
                            ? '-'
                            : lensNames.join(', ')),
                    const SizedBox(height: 8),
                    _RecapRow(
                        label: 'Langue menus',
                        value: _langName(selectedLang ?? '')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Download section
            if (status == DownloadStatus.idle) ...[
              Text(
                'Prêt à télécharger les données pour ton ${body?.displayName ?? "appareil"}.',
                style: theme.textTheme.bodyMedium,
              ),
              if (body != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '~${(body.packSizeBytes / 1024).round()} Ko',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],

            if (status == DownloadStatus.downloading) ...[
              Text('Téléchargement en cours...',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.total > 0
                    ? progress.current / progress.total
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.current}/${progress.total} fichiers',
                style: theme.textTheme.bodySmall,
              ),
            ],

            if (status == DownloadStatus.complete) ...[
              Row(
                children: [
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Téléchargement terminé !',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],

            if (status == DownloadStatus.error) ...[
              Row(
                children: [
                  Icon(Icons.error, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error ?? 'Erreur lors du téléchargement',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],

            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (status) {
          DownloadStatus.idle => FilledButton.icon(
              onPressed: () => _startDownload(ref),
              icon: const Icon(Icons.download),
              label: const Text('Télécharger'),
            ),
          DownloadStatus.downloading => const FilledButton(
              onPressed: null,
              child: SizedBox(
                height: 20,
                width: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          DownloadStatus.complete => FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('C\'est parti !'),
            ),
          DownloadStatus.error => FilledButton.icon(
              onPressed: () => _startDownload(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
        },
      ),
    );
  }

  void _startDownload(WidgetRef ref) async {
    ref.read(downloadStatusProvider.notifier).state =
        DownloadStatus.downloading;
    ref.read(downloadErrorProvider.notifier).state = null;

    try {
      // MVP: data is bundled in assets, so we just save the gear profile.
      ref.read(downloadProgressProvider.notifier).state =
          (current: 0, total: 1);

      final bodyId = ref.read(selectedBodyIdProvider);
      final lensIds = ref.read(selectedLensIdsProvider);
      final language = ref.read(selectedLanguageProvider);

      if (bodyId == null || language == null) {
        throw Exception('Sélection incomplète');
      }

      final profile = ref.read(gearProfileProvider);
      await profile.saveOnboarding(
        bodyId: bodyId,
        lensIds: lensIds,
        language: language,
      );

      ref.read(downloadProgressProvider.notifier).state =
          (current: 1, total: 1);
      ref.read(downloadStatusProvider.notifier).state =
          DownloadStatus.complete;
    } catch (e) {
      ref.read(downloadErrorProvider.notifier).state = e.toString();
      ref.read(downloadStatusProvider.notifier).state =
          DownloadStatus.error;
    }
  }

  static String _langName(String lang) => switch (lang) {
        'fr' => 'Français',
        'en' => 'English',
        'de' => 'Deutsch',
        'ja' => '日本語',
        _ => lang,
      };
}

class _RecapRow extends StatelessWidget {
  final String label;
  final String value;

  const _RecapRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
