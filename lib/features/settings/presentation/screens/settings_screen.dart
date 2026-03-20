import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/domain/entities/optical_filter.dart';
import '../../../../shared/presentation/providers/filter_providers.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';
import '../../../../shared/presentation/providers/gear_profile_provider.dart';
import '../../../../shared/presentation/providers/theme_provider.dart';
import '../../../gear/presentation/widgets/filter_management_sheet.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyAsync = ref.watch(currentBodyProvider);
    final lensAsync = ref.watch(currentLensProvider);
    final lang = ref.watch(firmwareLanguageProvider);
    final profile = ref.watch(gearProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final filters = ref.watch(userFiltersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Réglages', style: AppTypography.headline),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Body section
          Text('BOÎTIER', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface1 : AppColors.lightSurface1,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.camera, size: 24, color: AppColors.blueOptique),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bodyAsync.when(
                        loading: () => Text('Chargement...', style: AppTypography.body),
                        error: (_, __) => Text('Erreur', style: AppTypography.body),
                        data: (body) => Text(body.displayName, style: AppTypography.title),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Changer de boîtier nécessite un re-téléchargement',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Lenses section
          Text('OBJECTIFS', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface1 : AppColors.lightSurface1,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            clipBehavior: Clip.antiAlias,
            child: lensAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.base),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Text('Erreur de chargement', style: AppTypography.body),
              ),
              data: (lens) {
                final allLensIds = profile.lensIds;
                return ref.watch(cameraDataCacheProvider).when(
                      loading: () => _LensTile(
                        name: lens.displayName,
                        isActive: true,
                        isDark: isDark,
                      ),
                      error: (_, __) => _LensTile(
                        name: lens.displayName,
                        isActive: true,
                        isDark: isDark,
                      ),
                      data: (cache) => Column(
                        children: allLensIds.map((id) {
                          final l = cache.allLenses.cast<dynamic>().firstWhere(
                                (ls) => ls.id == id,
                                orElse: () => null,
                              );
                          final isActive = id == profile.activeLensId;
                          return _LensTile(
                            name: l?.displayName ?? id,
                            isActive: isActive,
                            isDark: isDark,
                            canRemove: allLensIds.length > 1 && !isActive,
                            onTap: isActive
                                ? null
                                : () async {
                                    await profile.setActiveLens(id);
                                    ref.invalidate(gearProfileProvider);
                                    ref.invalidate(cameraDataCacheProvider);
                                  },
                            onRemove: () async {
                              await profile.removeLens(id);
                              ref.invalidate(gearProfileProvider);
                            },
                          );
                        }).toList(),
                      ),
                    );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Language section
          Text('LANGUE DES MENUS', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface1 : AppColors.lightSurface1,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _LanguageTile(
                  label: 'Français',
                  flag: '🇫🇷',
                  selected: lang == 'fr',
                  isDark: isDark,
                  onTap: () => _setLanguage(ref, 'fr'),
                ),
                _LanguageTile(
                  label: 'English',
                  flag: '🇬🇧',
                  selected: lang == 'en',
                  isDark: isDark,
                  onTap: () => _setLanguage(ref, 'en'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Changement instantané, pas de re-téléchargement nécessaire.',
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Theme section
          Text('APPARENCE', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface1 : AppColors.lightSurface1,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _ThemeTile(
                  icon: LucideIcons.smartphone,
                  label: 'Système',
                  selected: themeMode == ThemeMode.system,
                  isDark: isDark,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                ),
                _ThemeTile(
                  icon: LucideIcons.sun,
                  label: 'Clair',
                  selected: themeMode == ThemeMode.light,
                  isDark: isDark,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                ),
                _ThemeTile(
                  icon: LucideIcons.moon,
                  label: 'Sombre',
                  selected: themeMode == ThemeMode.dark,
                  isDark: isDark,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Filters section
          Text('FILTRES OPTIQUES', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          if (filters.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface1 : AppColors.lightSurface1,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: filters.map((f) => _FilterTile(
                  filter: f,
                  isDark: isDark,
                  onDelete: () {
                    ref.read(filterStoreProvider).removeFilter(f.id);
                    ref.invalidate(userFiltersProvider);
                  },
                )).toList(),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const FilterManagementSheet(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.plus, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text('Ajouter un filtre', style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setLanguage(WidgetRef ref, String lang) {
    final profile = ref.read(gearProfileProvider);
    profile.setLanguage(lang);
    ref.read(firmwareLanguageProvider.notifier).state = lang;
  }
}

class _LensTile extends StatelessWidget {
  final String name;
  final bool isActive;
  final bool isDark;
  final bool canRemove;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _LensTile({
    required this.name,
    required this.isActive,
    required this.isDark,
    this.canRemove = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              isActive ? LucideIcons.checkCircle : LucideIcons.circle,
              size: 20,
              color: isActive
                  ? AppColors.blueOptique
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                name,
                style: AppTypography.body.copyWith(
                  color: isActive ? AppColors.blueOptique : null,
                  fontWeight: isActive ? FontWeight.w600 : null,
                ),
              ),
            ),
            if (canRemove)
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.flag,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selected ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: selected ? AppColors.blueOptique : null,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ),
            if (selected)
              Icon(LucideIcons.checkCircle, size: 20, color: AppColors.blueOptique),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selected ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? AppColors.blueOptique
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: selected ? AppColors.blueOptique : null,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ),
            if (selected)
              Icon(LucideIcons.checkCircle, size: 20, color: AppColors.blueOptique),
          ],
        ),
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final OpticalFilter filter;
  final bool isDark;
  final VoidCallback onDelete;

  const _FilterTile({
    required this.filter,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (filter) {
      NdFilter(stops: final s) => '$s stops · ${filter.filterDiameterMm}mm',
      NdVariableFilter(minStops: final min, maxStops: final max) =>
        '$min-$max stops · ${filter.filterDiameterMm}mm',
      CplFilter(lightLoss: final l) =>
        '${l.toStringAsFixed(1)} stops · ${filter.filterDiameterMm}mm',
      UvFilter() => '${filter.filterDiameterMm}mm',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.disc, size: 20, color: AppColors.blueOptique),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(filter.name, style: AppTypography.body),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              LucideIcons.x,
              size: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
