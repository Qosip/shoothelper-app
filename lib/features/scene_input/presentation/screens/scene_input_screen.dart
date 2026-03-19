import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../shared/presentation/providers/scene_providers.dart';
import '../providers/scene_input_draft_provider.dart';
import '../widgets/enum_chip_selector.dart';

class SceneInputScreen extends ConsumerWidget {
  const SceneInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(sceneInputDraftProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau shoot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === Level 1: Required ===
          Text('Décris ta scène',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),

          EnumChipSelector<ShootType>(
            label: 'Type',
            values: ShootType.values,
            selected: draft.shootType,
            onSelected: ref.read(sceneInputDraftProvider.notifier).setShootType,
            displayName: _shootTypeLabel,
          ),
          const SizedBox(height: 16),

          EnumChipSelector<Environment>(
            label: 'Environnement',
            values: Environment.values,
            selected: draft.environment,
            onSelected:
                ref.read(sceneInputDraftProvider.notifier).setEnvironment,
            displayName: _environmentLabel,
          ),
          const SizedBox(height: 16),

          EnumChipSelector<Subject>(
            label: 'Sujet',
            values: Subject.values,
            selected: draft.subject,
            onSelected: ref.read(sceneInputDraftProvider.notifier).setSubject,
            displayName: _subjectLabel,
          ),
          const SizedBox(height: 16),

          EnumChipSelector<Intention>(
            label: 'Intention',
            values: Intention.values,
            selected: draft.intention,
            onSelected: ref.read(sceneInputDraftProvider.notifier).setIntention,
            displayName: _intentionLabel,
          ),
          const SizedBox(height: 24),

          // === Level 2: Optional ===
          _ExpandableSection(
            title: 'Options avancées',
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
              const SizedBox(height: 12),
              EnumChipSelector<Support>(
                label: 'Support',
                values: Support.values,
                selected: draft.support,
                onSelected:
                    ref.read(sceneInputDraftProvider.notifier).setSupport,
                displayName: _supportLabel,
              ),
              const SizedBox(height: 12),
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
          const SizedBox(height: 12),

          // === Level 3: Overrides ===
          _ExpandableSection(
            title: 'Overrides',
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
              const SizedBox(height: 12),
              EnumChipSelector<WbOverride>(
                label: 'Balance des blancs',
                values: WbOverride.values,
                selected: draft.wbOverride,
                onSelected:
                    ref.read(sceneInputDraftProvider.notifier).setWbOverride,
                displayName: _wbLabel,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // === Calculate button ===
          FilledButton.icon(
            onPressed: draft.isLevel1Complete
                ? () {
                    ref.read(submittedSceneProvider.notifier).state =
                        draft.toSceneInput();
                    context.go('/results');
                  }
                : null,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculer'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
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

/// Expandable section widget (ephemeral state stays in widget).
class _ExpandableSection extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const _ExpandableSection({
    required this.title,
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
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 8),
                Text(widget.title,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}
