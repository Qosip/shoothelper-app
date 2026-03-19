import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final bodyId = ref.watch(selectedBodyIdProvider);
    final selectedLang = ref.watch(selectedLanguageProvider);
    final theme = Theme.of(context);

    final body = catalog?.findBody(bodyId ?? '');
    final languages = body?.languages ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Langue des menus'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding/lens'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dans quelle langue sont les menus de ton ${body?.displayName ?? "appareil"} ?',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ...languages.map((lang) {
              final isSelected = lang == selectedLang;
              return Card(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : null,
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => ref
                      .read(selectedLanguageProvider.notifier)
                      .state = lang,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(_langFlag(lang),
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_langName(lang),
                              style: theme.textTheme.titleMedium),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: theme.colorScheme.primary),
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
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: selectedLang != null
              ? () => context.go('/onboarding/download')
              : null,
          child: const Text('Suivant'),
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
