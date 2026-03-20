import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../shared/presentation/providers/scene_providers.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/expand_toggle.dart';
import '../../../../shared/presentation/widgets/bottom_sticky_bar.dart';
import '../../../../shared/presentation/widgets/section_divider.dart';
import '../providers/scene_input_draft_provider.dart';
import '../widgets/enum_chip_selector.dart';

class SceneInputScreen extends ConsumerWidget {
  const SceneInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(sceneInputDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nouveau shoot', style: AppTypography.headline),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              100, // space for sticky bar
            ),
            children: [
              // === Level 1: Required ===
              Text('Décris ta scène', style: AppTypography.headline),
              const SizedBox(height: AppSpacing.base),

              EnumChipSelector<ShootType>(
                label: 'Type',
                values: ShootType.values,
                selected: draft.shootType,
                onSelected:
                    ref.read(sceneInputDraftProvider.notifier).setShootType,
                displayName: _shootTypeLabel,
              ),
              const SizedBox(height: AppSpacing.base),

              EnumChipSelector<Environment>(
                label: 'Environnement',
                values: Environment.values,
                selected: draft.environment,
                onSelected:
                    ref.read(sceneInputDraftProvider.notifier).setEnvironment,
                displayName: _environmentLabel,
              ),
              const SizedBox(height: AppSpacing.base),

              EnumChipSelector<Subject>(
                label: 'Sujet',
                values: Subject.values,
                selected: draft.subject,
                onSelected:
                    ref.read(sceneInputDraftProvider.notifier).setSubject,
                displayName: _subjectLabel,
              ),
              const SizedBox(height: AppSpacing.base),

              EnumChipSelector<Intention>(
                label: 'Intention',
                values: Intention.values,
                selected: draft.intention,
                onSelected:
                    ref.read(sceneInputDraftProvider.notifier).setIntention,
                displayName: _intentionLabel,
              ),

              const SizedBox(height: AppSpacing.xl),
              const SectionDivider(label: 'AFFINER'),
              const SizedBox(height: AppSpacing.sm),

              // === Level 2: Optional ===
              _ExpandableSection(
                title: 'Options avancées',
                badgeCount: _countLevel2(draft),
                children: [
                  EnumChipSelector<LightCondition>(
                    label: 'Lumière',
                    values: LightCondition.values,
                    selected: draft.lightCondition,
                    onSelected: ref
                        .read(sceneInputDraftProvider.notifier)
                        .setLightCondition,
                    displayName: _lightConditionLabel,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  EnumChipSelector<Support>(
                    label: 'Support',
                    values: Support.values,
                    selected: draft.support,
                    onSelected:
                        ref.read(sceneInputDraftProvider.notifier).setSupport,
                    displayName: _supportLabel,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  EnumChipSelector<SubjectMotion>(
                    label: 'Mouvement du sujet',
                    values: SubjectMotion.values,
                    selected: draft.subjectMotion,
                    onSelected: ref
                        .read(sceneInputDraftProvider.notifier)
                        .setSubjectMotion,
                    displayName: _subjectMotionLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // === Level 3: Overrides ===
              _ExpandableSection(
                title: 'Overrides',
                badgeCount: _countLevel3(draft),
                children: [
                  EnumChipSelector<DofPreference>(
                    label: 'Profondeur de champ',
                    values: DofPreference.values,
                    selected: draft.dofPreference,
                    onSelected: ref
                        .read(sceneInputDraftProvider.notifier)
                        .setDofPreference,
                    displayName: _dofLabel,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  EnumChipSelector<WbOverride>(
                    label: 'Balance des blancs',
                    values: WbOverride.values,
                    selected: draft.wbOverride,
                    onSelected: ref
                        .read(sceneInputDraftProvider.notifier)
                        .setWbOverride,
                    displayName: _wbLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),

          // === Sticky bottom CTA ===
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomStickyBar(
              child: FilledButton(
                onPressed: draft.isLevel1Complete
                    ? () {
                        ref.read(submittedSceneProvider.notifier).state =
                            draft.toSceneInput();
                        context.go('/results');
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.calculator, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Calculer les réglages',
                        style: AppTypography.title
                            .copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int _countLevel2(dynamic draft) {
    int c = 0;
    if (draft.lightCondition != null) c++;
    if (draft.support != null) c++;
    if (draft.subjectMotion != null) c++;
    return c;
  }

  static int _countLevel3(dynamic draft) {
    int c = 0;
    if (draft.dofPreference != null) c++;
    if (draft.wbOverride != null) c++;
    return c;
  }

  // --- Label helpers ---
  static String _shootTypeLabel(ShootType v) => switch (v) {
        ShootType.photo => 'Photo',
        ShootType.video => 'Vidéo',
      };

  static String _environmentLabel(Environment v) => switch (v) {
        Environment.outdoorDay => 'Extérieur jour',
        Environment.outdoorNight => 'Extérieur nuit',
        Environment.indoorBright => 'Intérieur lumineux',
        Environment.indoorDark => 'Intérieur sombre',
        Environment.studio => 'Studio',
      };

  static String _subjectLabel(Subject v) => switch (v) {
        Subject.landscape => 'Paysage',
        Subject.portrait => 'Portrait',
        Subject.street => 'Street',
        Subject.architecture => 'Architecture',
        Subject.macro => 'Macro',
        Subject.astro => 'Astro',
        Subject.sport => 'Sport',
        Subject.wildlife => 'Animalier',
        Subject.product => 'Produit',
      };

  static String _intentionLabel(Intention v) => switch (v) {
        Intention.maxSharpness => 'Netteté max',
        Intention.bokeh => 'Bokeh',
        Intention.freezeMotion => 'Figer le mouvement',
        Intention.motionBlur => 'Filé de mouvement',
        Intention.lowLight => 'Basse lumière',
      };

  static String _lightConditionLabel(LightCondition v) => switch (v) {
        LightCondition.directSun => 'Soleil direct',
        LightCondition.overcast => 'Couvert',
        LightCondition.shade => 'Ombre',
        LightCondition.goldenHour => 'Golden hour',
        LightCondition.blueHour => 'Blue hour',
        LightCondition.starryNight => 'Nuit étoilée',
        LightCondition.neon => 'Néon',
        LightCondition.tungsten => 'Tungstène',
        LightCondition.led => 'LED',
      };

  static String _supportLabel(Support v) => switch (v) {
        Support.handheld => 'Main levée',
        Support.tripod => 'Trépied',
        Support.monopod => 'Monopode',
        Support.gimbal => 'Gimbal',
      };

  static String _subjectMotionLabel(SubjectMotion v) => switch (v) {
        SubjectMotion.still => 'Immobile',
        SubjectMotion.slow => 'Lent',
        SubjectMotion.fast => 'Rapide',
        SubjectMotion.veryFast => 'Très rapide',
      };

  static String _dofLabel(DofPreference v) => switch (v) {
        DofPreference.shallow => 'Faible (bokeh)',
        DofPreference.medium => 'Moyenne',
        DofPreference.deep => 'Profonde',
      };

  static String _wbLabel(WbOverride v) => switch (v) {
        WbOverride.auto => 'Auto',
        WbOverride.daylight => 'Jour',
        WbOverride.shade => 'Ombre',
        WbOverride.cloudy => 'Nuageux',
        WbOverride.tungsten => 'Tungstène',
        WbOverride.fluorescent => 'Fluorescent',
        WbOverride.flash => 'Flash',
      };
}

/// Expandable section using ExpandToggle + AnimatedCrossFade.
class _ExpandableSection extends StatefulWidget {
  final String title;
  final int badgeCount;
  final List<Widget> children;

  const _ExpandableSection({
    required this.title,
    this.badgeCount = 0,
    required this.children,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpandToggle(
          label: widget.title,
          isExpanded: _expanded,
          badgeCount: widget.badgeCount > 0 ? widget.badgeCount : null,
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              top: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
