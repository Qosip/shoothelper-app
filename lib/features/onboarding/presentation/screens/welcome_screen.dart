import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/use_cases/load_catalog.dart';
import '../providers/onboarding_providers.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(Icons.camera_alt_outlined,
                  size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text('ShootHelper',
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Tes réglages photo optimaux\nen quelques secondes.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  const loader = LoadCatalog();
                  final catalog = await loader();
                  ref.read(catalogProvider.notifier).state = catalog;
                  if (context.mounted) {
                    context.go('/onboarding/body');
                  }
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Commencer'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
