import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';
import '../../../../shared/presentation/providers/scene_providers.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/error_display.dart';
import '../../../../shared/presentation/widgets/nav_step_card.dart';
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
        title: Text('Comment régler', style: AppTypography.headline),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/results/setting/$settingId'),
        ),
      ),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorDisplay(
          failure: mapToFailure(e),
          onAction: () => ref.invalidate(settingsResultProvider),
        ),
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
            error: (e, _) => ErrorDisplay(
              failure: mapToFailure(e),
              onAction: () => ref.invalidate(settingsResultProvider),
            ),
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
                    padding: EdgeInsets.all(AppSpacing.xxl),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // Header
        Text(display.header, style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          display.subheader,
          style: AppTypography.caption.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Dial access
        if (display.dialSection != null) ...[
          _SectionCard(
            icon: LucideIcons.disc,
            title: display.dialSection!.title,
            isDark: isDark,
            child: Text(display.dialSection!.instruction,
                style: AppTypography.body),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Quick access (Fn menu)
        if (display.quickAccessSection != null) ...[
          _SectionCard(
            icon: LucideIcons.zap,
            title: display.quickAccessSection!.title,
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: display.quickAccessSection!.steps
                  .asMap()
                  .entries
                  .map((e) => NavStepCard(
                        stepNumber: e.key + 1,
                        text: e.value,
                        isLast: e.key ==
                            display.quickAccessSection!.steps.length - 1,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Full menu path — timeline
        if (display.fullMenuSection != null) ...[
          _SectionCard(
            icon: LucideIcons.menu,
            title: display.fullMenuSection!.title,
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavStepCard(
                  stepNumber: 0,
                  text: display.fullMenuSection!.pressMenuLabel,
                ),
                ...display.fullMenuSection!.steps.map((step) =>
                    NavStepCard(
                      stepNumber: step.stepNumber,
                      text: step.label,
                      isLast: step.stepNumber ==
                          display.fullMenuSection!.steps.last.stepNumber,
                    )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Breadcrumb in mono
        if (display.fullMenuSection != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Text(
              display.fullMenuSection!.steps
                  .map((s) => s.label)
                  .join(' > '),
              style: AppTypography.mono.copyWith(
                color: AppColors.blueOptique,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Tips
        if (display.tips.isNotEmpty) ...[
          Text('CONSEILS', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          ...display.tips.map((tip) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.blueOptique10,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.lightbulb,
                        size: 16, color: AppColors.blueOptique),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(tip.text,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.blueOptique)),
                    ),
                  ],
                ),
              )),
        ],

        const SizedBox(height: AppSpacing.xl),

        // Copy button
        OutlinedButton(
          onPressed: () {
            final text = _buildCopyText(display);
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copié dans le presse-papier')),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.copy, size: 18),
              const SizedBox(width: AppSpacing.sm),
              const Text('Copier les instructions'),
            ],
          ),
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
  final bool isDark;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightSurface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.blueOptique),
              const SizedBox(width: AppSpacing.sm),
              Text(title,
                  style: AppTypography.title
                      .copyWith(color: AppColors.blueOptique)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
