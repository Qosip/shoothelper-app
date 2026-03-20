import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
import '../providers/onboarding_providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final bodyId = ref.watch(selectedBodyIdProvider);
    final selectedLang = ref.watch(selectedLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = catalog?.findBody(bodyId ?? '');
    final languages = body?.languages ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Langue des menus', style: AppTypography.headline),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/onboarding/lens'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dans quelle langue sont les menus de ton ${body?.displayName ?? "appareil"} ?',
              style: AppTypography.body.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...languages.map((lang) {
              final isSelected = lang == selectedLang;
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
                  onTap: () => ref
                      .read(selectedLanguageProvider.notifier)
                      .state = lang,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Row(
                      children: [
                        Text(_langFlag(lang),
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(_langName(lang),
                              style: AppTypography.title),
                        ),
                        if (isSelected)
                          Icon(LucideIcons.checkCircle,
                              size: 20, color: AppColors.blueOptique),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: FilledButton(
          onPressed: selectedLang != null
              ? () => context.go('/onboarding/download')
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

  static String _langName(String lang) => switch (lang) {
        'fr' => 'Français',
        'en' => 'English',
        'de' => 'Deutsch',
        'ja' => '日本語',
        'es' => 'Español',
        'it' => 'Italiano',
        _ => lang,
      };

  static String _langFlag(String lang) => switch (lang) {
        'fr' => '🇫🇷',
        'en' => '🇬🇧',
        'de' => '🇩🇪',
        'ja' => '🇯🇵',
        'es' => '🇪🇸',
        'it' => '🇮🇹',
        _ => '🌐',
      };
}
