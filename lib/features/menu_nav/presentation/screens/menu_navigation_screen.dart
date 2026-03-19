import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';
import '../../../../shared/presentation/providers/scene_providers.dart';
import '../../domain/use_cases/resolve_menu_path.dart';

class MenuNavigationScreen extends ConsumerWidget {
  final String settingId;

  const MenuNavigationScreen({super.key, required this.settingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(settingsResultProvider);
    final cacheAsync = ref.watch(cameraDataCacheProvider);
    final lang = ref.watch(firmwareLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comment régler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go('/results/setting/$settingId'),
        ),
      ),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (result) {
          if (result == null) {
            return const Center(child: Text('Aucun résultat'));
          }
          final setting = result.findSetting(settingId);
          if (setting == null) {
            return Center(
                child: Text('Réglage "$settingId" non trouvé'));
          }

          return cacheAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (cache) {
              final navPath = cache.getNavPath(settingId);
              const resolver = ResolveMenuPath();
              final display = resolver.resolve(
                settingId: settingId,
                setting: setting,
                navPath: navPath,
                menuTree: cache.menuTree,
                bodyName: cache.body.name,
                lang: lang,
              );

              if (display == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Chemin de menu non disponible pour ce réglage.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return _MenuNavContent(display: display);
            },
          );
        },
      ),
    );
  }
}

class _MenuNavContent extends StatelessWidget {
  final MenuNavDisplay display;

  const _MenuNavContent({required this.display});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(display.header,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(display.subheader,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),

        // Dial access (highest priority)
        if (display.dialSection != null) ...[
          _SectionCard(
            icon: Icons.radio_button_checked,
            title: display.dialSection!.title,
            child: Text(display.dialSection!.instruction,
                style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 12),
        ],

        // Quick access (Fn menu)
        if (display.quickAccessSection != null) ...[
          _SectionCard(
            icon: Icons.flash_on,
            title: display.quickAccessSection!.title,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: display.quickAccessSection!.steps
                  .asMap()
                  .entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StepBadge(number: e.key + 1),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(e.value,
                                    style: theme.textTheme.bodyMedium)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Full menu path
        if (display.fullMenuSection != null) ...[
          _SectionCard(
            icon: Icons.menu,
            title: display.fullMenuSection!.title,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Press MENU" step
                Row(
                  children: [
                    _StepBadge(number: 0),
                    const SizedBox(width: 8),
                    Text(display.fullMenuSection!.pressMenuLabel,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                // Breadcrumb steps
                ...display.fullMenuSection!.steps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StepBadge(number: step.stepNumber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(step.label,
                                style: theme.textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Tips
        if (display.tips.isNotEmpty) ...[
          Text('Conseils', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...display.tips.map((tip) => Card(
                color: theme.colorScheme.tertiaryContainer,
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 18,
                          color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tip.text,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onTertiaryContainer)),
                      ),
                    ],
                  ),
                ),
              )),
        ],

        const SizedBox(height: 24),

        // Copy button
        OutlinedButton.icon(
          onPressed: () {
            final text = _buildCopyText(display);
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copié dans le presse-papier')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copier les instructions'),
        ),
      ],
    );
  }

  String _buildCopyText(MenuNavDisplay display) {
    final buf = StringBuffer();
    buf.writeln(display.header);
    buf.writeln(display.subheader);
    buf.writeln();
    if (display.dialSection != null) {
      buf.writeln('${display.dialSection!.title}:');
      buf.writeln(display.dialSection!.instruction);
      buf.writeln();
    }
    if (display.quickAccessSection != null) {
      buf.writeln('${display.quickAccessSection!.title}:');
      for (var i = 0; i < display.quickAccessSection!.steps.length; i++) {
        buf.writeln('${i + 1}. ${display.quickAccessSection!.steps[i]}');
      }
      buf.writeln();
    }
    if (display.fullMenuSection != null) {
      buf.writeln('${display.fullMenuSection!.title}:');
      buf.writeln('0. ${display.fullMenuSection!.pressMenuLabel}');
      for (final step in display.fullMenuSection!.steps) {
        buf.writeln('${step.stepNumber}. ${step.label}');
      }
    }
    return buf.toString();
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int number;

  const _StepBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
