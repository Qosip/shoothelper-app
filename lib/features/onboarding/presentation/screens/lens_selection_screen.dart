import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_providers.dart';

class LensSelectionScreen extends ConsumerWidget {
  const LensSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final bodyId = ref.watch(selectedBodyIdProvider);
    final selectedLensIds = ref.watch(selectedLensIdsProvider);
    final theme = Theme.of(context);

    final body = catalog?.findBody(bodyId ?? '');
    final lenses = body?.lenses ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisis tes objectifs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding/body'),
        ),
      ),
      body: lenses.isEmpty
          ? const Center(child: Text('Aucun objectif disponible'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lenses.length,
              itemBuilder: (context, index) {
                final lens = lenses[index];
                final isSelected = selectedLensIds.contains(lens.id);
                return Card(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : null,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      final notifier =
                          ref.read(selectedLensIdsProvider.notifier);
                      if (isSelected) {
                        notifier.state = selectedLensIds
                            .where((id) => id != lens.id)
                            .toList();
                      } else {
                        notifier.state = [...selectedLensIds, lens.id];
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lens_outlined,
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
                                Text(lens.displayName,
                                    style: theme.textTheme.titleMedium),
                                if (lens.isKitLens)
                                  Text('Objectif kit',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme
                                                  .primary)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: theme.colorScheme.primary)
                          else
                            Icon(Icons.circle_outlined,
                                color:
                                    theme.colorScheme.onSurfaceVariant),
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
          onPressed: selectedLensIds.isNotEmpty
              ? () => context.go('/onboarding/language')
              : null,
          child: const Text('Suivant'),
        ),
      ),
    );
  }
}
