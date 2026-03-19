import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyAsync = ref.watch(currentBodyProvider);
    final lensAsync = ref.watch(currentLensProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShootHelper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gear card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mon matériel',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    bodyAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Erreur: $e'),
                      data: (body) => Row(
                        children: [
                          Icon(Icons.camera_alt,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(body.name,
                              style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    lensAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => Text('Erreur: $e'),
                      data: (lens) => Row(
                        children: [
                          Icon(Icons.lens,
                              color: theme.colorScheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          Text(lens.displayName,
                              style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Main action button
            FilledButton.icon(
              onPressed: () => context.go('/scene-input'),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Nouveau shoot'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
