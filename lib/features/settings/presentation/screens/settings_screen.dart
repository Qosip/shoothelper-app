import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';
import '../../../../shared/presentation/providers/gear_profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyAsync = ref.watch(currentBodyProvider);
    final lensAsync = ref.watch(currentLensProvider);
    final lang = ref.watch(firmwareLanguageProvider);
    final profile = ref.watch(gearProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Body section
          Text('Boîtier', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading:
                  Icon(Icons.camera_alt, color: theme.colorScheme.primary),
              title: bodyAsync.when(
                loading: () => const Text('Chargement...'),
                error: (_, __) => const Text('Erreur'),
                data: (body) => Text(body.name),
              ),
              subtitle: const Text('Changer de boîtier nécessite un re-téléchargement'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Phase 6 — navigate to body change flow
              },
            ),
          ),
          const SizedBox(height: 24),

          // Lenses section
          Text('Objectifs', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                lensAsync.when(
                  loading: () => const ListTile(
                    title: Text('Chargement...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('Erreur de chargement'),
                  ),
                  data: (lens) {
                    final allLensIds = profile.lensIds;
                    return ref.watch(cameraDataCacheProvider).when(
                          loading: () => ListTile(
                            title: Text(lens.displayName),
                          ),
                          error: (_, __) => ListTile(
                            title: Text(lens.displayName),
                          ),
                          data: (cache) => Column(
                            children: allLensIds.map((id) {
                              final l = cache.allLenses.cast<dynamic>().firstWhere(
                                    (ls) => ls.id == id,
                                    orElse: () => null,
                                  );
                              final isActive = id == profile.activeLensId;
                              return ListTile(
                                leading: Icon(
                                  isActive
                                      ? Icons.check_circle
                                      : Icons.lens_outlined,
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : null,
                                  size: 20,
                                ),
                                title: Text(
                                  l?.displayName ?? id,
                                  style: isActive
                                      ? TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : null,
                                ),
                                trailing: allLensIds.length > 1 && !isActive
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () async {
                                          await profile.removeLens(id);
                                          ref.invalidate(gearProfileProvider);
                                        },
                                      )
                                    : null,
                                onTap: isActive
                                    ? null
                                    : () async {
                                        await profile.setActiveLens(id);
                                        ref.invalidate(gearProfileProvider);
                                        ref.invalidate(cameraDataCacheProvider);
                                      },
                              );
                            }).toList(),
                          ),
                        );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Language section
          Text('Langue des menus', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _LanguageTile(
                  label: 'Français',
                  flag: '🇫🇷',
                  code: 'fr',
                  selected: lang == 'fr',
                  onTap: () => _setLanguage(ref, 'fr'),
                ),
                _LanguageTile(
                  label: 'English',
                  flag: '🇬🇧',
                  code: 'en',
                  selected: lang == 'en',
                  onTap: () => _setLanguage(ref, 'en'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Changement instantané, pas de re-téléchargement nécessaire.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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

class _LanguageTile extends StatelessWidget {
  final String label;
  final String flag;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.flag,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: selected
            ? TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              )
            : null,
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: selected ? null : onTap,
    );
  }
}
