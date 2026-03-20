import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
import '../../domain/use_cases/load_catalog.dart';
import '../providers/onboarding_providers.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(LucideIcons.camera,
                  size: 80, color: AppColors.blueOptique),
              const SizedBox(height: AppSpacing.xl),
              Text('ShootHelper', style: AppTypography.display),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tes réglages photo optimaux\nen quelques secondes.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  const loader = LoadCatalog();
                  final catalog = await loader();
                  ref.read(catalogProvider.notifier).state = catalog;
                  if (context.mounted) {
                    context.go('/onboarding/body');
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.blueOptique,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Commencer',
                        style: AppTypography.title
                            .copyWith(color: Colors.white)),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(LucideIcons.arrowRight, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
