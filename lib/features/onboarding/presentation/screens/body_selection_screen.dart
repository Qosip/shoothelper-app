import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_providers.dart';

class BodySelectionScreen extends ConsumerWidget {
  const BodySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final selectedId = ref.watch(selectedBodyIdProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisis ton boîtier'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: catalog == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: catalog.bodies.length,
              itemBuilder: (context, index) {
                final body = catalog.bodies[index];
                final isSelected = body.id == selectedId;
                return Card(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : null,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedBodyIdProvider.notifier).state =
                          body.id;
                      // Pre-select language based on device locale
                      final locale =
                          Localizations.localeOf(context).languageCode;
                      final lang = body.languages.contains(locale)
                          ? locale
                          : body.languages.first;
                      ref.read(selectedLanguageProvider.notifier).state =
                          lang;
                      // Reset lens selection
                      ref.read(selectedLensIdsProvider.notifier).state = [];
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(body.displayName,
                                    style: theme.textTheme.titleMedium),
                                Text(
                                  '${_sensorLabel(body.sensorSize)} · ${body.lenses.length} objectif(s)',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: theme.colorScheme
                                              .onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: selectedId != null
              ? () => context.go('/onboarding/lens')
              : null,
          child: const Text('Suivant'),
        ),
      ),
    );
  }

  static String _sensorLabel(String s) => switch (s) {
        'aps-c' => 'APS-C',
        'full-frame' => 'Plein format',
        'micro-four-thirds' => 'Micro 4/3',
        _ => s,
      };
}
