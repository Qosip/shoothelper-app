import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/data/data_sources/local/gear_profile_store.dart';
import '../../../../shared/presentation/providers/gear_profile_store_provider.dart';
import '../../../../shared/presentation/providers/gear_providers.dart';
import '../../../../shared/presentation/providers/gear_profile_provider.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';

/// Bottom sheet to switch between gear profiles or create a new one.
class ProfileSelectorSheet extends ConsumerWidget {
  const ProfileSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gearProfileStoreProvider);
    final profiles = store.profiles;
    final activeId = ref.watch(activeProfileIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text('MES KITS', style: AppTypography.overline),
            const SizedBox(height: AppSpacing.md),
            ...profiles.map((profile) {
              final isActive = profile.id == activeId;
              return _ProfileTile(
                profile: profile,
                isActive: isActive,
                isDark: isDark,
                onTap: () async {
                  await store.setActiveProfile(profile.id);
                  ref.invalidate(activeProfileIdProvider);
                  // Sync legacy profile source
                  final legacy = ref.read(gearProfileProvider);
                  await legacy.setBody(profile.bodyId);
                  await legacy.setActiveLens(profile.activeLensId);
                  await legacy.setLanguage(profile.language);
                  ref.invalidate(gearProfileProvider);
                  ref.invalidate(cameraDataCacheProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                onDelete: profiles.length > 1
                    ? () async {
                        await store.deleteProfile(profile.id);
                        ref.invalidate(activeProfileIdProvider);
                        if (context.mounted) Navigator.pop(context);
                      }
                    : null,
              );
            }),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => _createProfile(context, ref),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.plus, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Nouveau kit', style: AppTypography.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProfile(BuildContext context, WidgetRef ref) async {
    final store = ref.read(gearProfileStoreProvider);
    final legacy = ref.read(gearProfileProvider);
    final id = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    final profile = GearProfileData(
      id: id,
      name: 'Kit ${store.profiles.length + 1}',
      bodyId: legacy.bodyId ?? 'sony_a6700',
      lensIds: legacy.lensIds,
      activeLensId: legacy.activeLensId ?? legacy.lensIds.firstOrNull ?? '',
      language: legacy.language,
    );
    await store.saveProfile(profile);
    await store.setActiveProfile(id);
    ref.invalidate(activeProfileIdProvider);
    if (context.mounted) Navigator.pop(context);
  }
}

class _ProfileTile extends StatelessWidget {
  final GearProfileData profile;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.blueOptique.withValues(alpha: 0.1)
            : (isDark ? AppColors.darkSurface1 : AppColors.lightSurface1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: isActive
            ? Border.all(color: AppColors.blueOptique, width: 1.5)
            : null,
      ),
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              Icon(
                LucideIcons.briefcase,
                size: 20,
                color: isActive ? AppColors.blueOptique : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTypography.title.copyWith(
                        color: isActive ? AppColors.blueOptique : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${profile.bodyId} · ${profile.lensIds.length} objectif(s)',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(LucideIcons.checkCircle,
                    size: 20, color: AppColors.blueOptique),
              if (onDelete != null && !isActive)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(LucideIcons.trash2,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
