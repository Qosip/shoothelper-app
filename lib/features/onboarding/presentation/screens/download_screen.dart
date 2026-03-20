import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/presentation/providers/gear_profile_provider.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = catalog?.findBody(bodyId ?? '');
    final lensNames = body?.lenses
            .where((l) => selectedLensIds.contains(l.id))
            .map((l) => l.displayName)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Récapitulatif', style: AppTypography.headline),
        leading: status != DownloadStatus.downloading
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => context.go('/onboarding/language'),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recap card
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface1
                    : AppColors.lightSurface1,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: Column(
                children: [
                  _RecapRow(
                    icon: LucideIcons.camera,
                    label: 'Boîtier',
                    value: body?.displayName ?? '-',
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RecapRow(
                    icon: LucideIcons.aperture,
                    label: 'Objectif(s)',
                    value: lensNames.isEmpty
                        ? '-'
                        : lensNames.join(', '),
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RecapRow(
                    icon: LucideIcons.globe,
                    label: 'Langue menus',
                    value: _langName(selectedLang ?? ''),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Download status
            if (status == DownloadStatus.idle) ...[
              Text(
                'Prêt à télécharger les données pour ton ${body?.displayName ?? "appareil"}.',
                style: AppTypography.body,
              ),
              if (body != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '~${(body.packSizeBytes / 1024).round()} Ko',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
            ],

            if (status == DownloadStatus.downloading) ...[
              Text('Téléchargement en cours...', style: AppTypography.body),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                child: LinearProgressIndicator(
                  value: progress.total > 0
                      ? progress.current / progress.total
                      : null,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? AppColors.darkSurface2
                      : AppColors.lightSurface2,
                  color: AppColors.blueOptique,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${progress.current}/${progress.total} fichiers',
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],

            if (status == DownloadStatus.complete) ...[
              Row(
                children: [
                  Icon(LucideIcons.checkCircle,
                      size: 24, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Téléchargement terminé !',
                    style: AppTypography.title.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],

            if (status == DownloadStatus.error) ...[
              Row(
                children: [
                  Icon(LucideIcons.alertCircle,
                      size: 24, color: AppColors.critical),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      error ?? 'Erreur lors du téléchargement',
                      style: AppTypography.body.copyWith(
                        color: AppColors.critical,
                      ),
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
        padding: const EdgeInsets.all(AppSpacing.base),
        child: switch (status) {
          DownloadStatus.idle => FilledButton(
              onPressed: () => _startDownload(ref),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.blueOptique,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.download, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Télécharger',
                      style: AppTypography.title
                          .copyWith(color: Colors.white)),
                ],
              ),
            ),
          DownloadStatus.downloading => FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          DownloadStatus.complete => FilledButton(
              onPressed: () => context.go('/'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.blueOptique,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('C\'est parti !',
                      style: AppTypography.title
                          .copyWith(color: Colors.white)),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(LucideIcons.arrowRight, size: 20),
                ],
              ),
            ),
          DownloadStatus.error => FilledButton(
              onPressed: () => _startDownload(ref),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.blueOptique,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.refreshCw, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Réessayer',
                      style: AppTypography.title
                          .copyWith(color: Colors.white)),
                ],
              ),
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
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _RecapRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.blueOptique),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(value,
              style: AppTypography.body
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
