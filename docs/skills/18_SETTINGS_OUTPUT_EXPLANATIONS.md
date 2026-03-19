# Settings Output & Explanations — ShootHelper

> **Skill 18/22** · Affichage des résultats, hiérarchie, système d'explications
> Version 1.0 · Mars 2026
> Réf : 02_USER_FLOWS.md, 06_SETTINGS_ENGINE.md, 07_I18N_MENU_LOCALIZATION.md

---

## 1. Rôle de cet écran

L'écran Résultats est l'**aboutissement** de l'app. L'utilisateur a décrit sa scène, le moteur a calculé — et maintenant il faut afficher les réglages de manière à ce qu'un débutant :

1. **Sache quoi régler** en un coup d'œil (les valeurs)
2. **Comprenne pourquoi** s'il le souhaite (les explications)
3. **Sache où le trouver** sur son appareil (le lien vers Menu Navigation)
4. **Voie les compromis** si le moteur a dû faire des concessions
5. **Puisse explorer des alternatives** pour apprendre

Tout ça dans un écran qui ne ressemble pas à un mur de texte.

---

## 2. Hiérarchie d'affichage — 3 niveaux de détail

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  NIVEAU 0 — Résumé express (visible immédiatement)              │
│  ──────────────────────────────────────────────                 │
│  Les 4 réglages du triangle d'exposition en gros, en une ligne. │
│  L'utilisateur voit M | f/2.8 | 1/250s | ISO 200 d'un coup     │
│  d'œil. Suffisant pour régler son appareil si il est pressé.    │
│                                                                 │
│  NIVEAU 1 — Liste complète (scroll)                             │
│  ────────────────────────────────                               │
│  Tous les réglages en liste, chacun avec sa valeur et une       │
│  explication courte d'une ligne. L'utilisateur parcourt pour    │
│  voir tous les réglages recommandés.                            │
│                                                                 │
│  NIVEAU 2 — Détail d'un réglage (tap)                           │
│  ──────────────────────────────────                             │
│  Écran dédié avec explication complète, alternatives, cascade   │
│  de changements, et lien vers la navigation menu.               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Niveau 0 — Résumé express

### 3.1. Design

```
┌──────────────────────────────────────┐
│ ← Modifier la scène          📋     │
│                                      │
│ TES RÉGLAGES                         │
│ Sony A6700 + Sigma 18-50mm f/2.8     │
│ Portrait · Ext Jour · Flou arrière   │
│                                      │
│ ┌────────────────────────────────┐   │
│ │  M    f/2.8   1/250s   ISO 200│   │
│ └────────────────────────────────┘   │
│                                      │
│ Confidence: ● Élevée                 │
│                                      │
└──────────────────────────────────────┘
```

### 3.2. Composant ExposureSummaryCard

```dart
// features/results/presentation/widgets/exposure_summary_card.dart

class ExposureSummaryCard extends StatelessWidget {
  final SettingsResult result;
  final Body body;
  final Lens lens;
  final SceneInput scene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extraire les 4 réglages clés
    final mode = result.findSetting('exposure_mode');
    final aperture = result.findSetting('aperture');
    final shutter = result.findSetting('shutter_speed');
    final iso = result.findSetting('iso');

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ligne gear + scène
            Text(
              '${body.displayName} + ${lens.displayName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _buildSceneSummary(scene, context),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Les 4 valeurs en gros
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ValueBlock(label: 'MODE', value: mode?.valueDisplay ?? '—'),
                _ValueBlock(label: 'OUVERT.', value: aperture?.valueDisplay ?? '—'),
                _ValueBlock(label: 'VITESSE', value: shutter?.valueDisplay ?? '—'),
                _ValueBlock(label: 'ISO', value: iso?.valueDisplay ?? '—'),
              ],
            ),
            const SizedBox(height: 12),

            // Badge de confiance
            _ConfidenceBadge(confidence: result.confidence),
          ],
        ),
      ),
    );
  }

  String _buildSceneSummary(SceneInput scene, BuildContext context) {
    final parts = [
      scene.subject.label(context),
      scene.environment.label(context),
      scene.intention.label(context),
    ];
    return parts.join(' · ');
  }
}

class _ValueBlock extends StatelessWidget {
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
```

### 3.3. Badge de confiance

```dart
class _ConfidenceBadge extends StatelessWidget {
  final Confidence confidence;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (confidence) {
      Confidence.high => (Colors.green, 'Résultat fiable', Icons.check_circle_outline),
      Confidence.medium => (Colors.orange, 'Affine ta scène pour plus de précision', Icons.info_outline),
      Confidence.low => (Colors.red, 'Compromis importants — voir détails', Icons.warning_amber_rounded),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
```

---

## 4. Niveau 1 — Liste complète des réglages

### 4.1. Ordre d'affichage

Les réglages sont affichés dans un ordre **logique pour un photographe**, pas dans l'ordre alphabétique ou l'ordre interne du moteur.

```
ORDRE D'AFFICHAGE :

1. Mode exposition      (M / A / S / P)
2. Ouverture            (f/2.8)
3. Vitesse              (1/250s)
4. ISO                  (200)
   ── séparateur "Triangle d'exposition" ci-dessus ──
5. Balance blancs       (Auto / 5500K)
6. Mode AF              (AF-C)
7. Zone AF              (Eye-AF)
8. Mode de mesure       (Matricielle)
9. Compensation expo    (0.0 EV) — affiché seulement si ≠ 0
10. Format fichier      (RAW)
11. Stabilisation       (ON/OFF) — affiché seulement si IBIS présent
12. Mode drive          (Single) — affiché seulement si ≠ Single
```

Les réglages 9-12 sont **conditionnellement masqués** quand ils sont à leur valeur par défaut non-informative. Pas besoin d'afficher "Compensation: 0.0" ou "Drive: Single" — c'est du bruit. Ils apparaissent dès qu'ils ont une valeur non-triviale.

```dart
// features/results/domain/use_cases/filter_display_settings.dart

class FilterDisplaySettings {
  /// Filtre les réglages à afficher dans la liste Niveau 1
  List<SettingRecommendation> execute(List<SettingRecommendation> all) {
    return all.where((s) {
      // Toujours afficher le triangle + AF + WB + mesure + format
      if (_alwaysShow.contains(s.settingId)) return true;

      // Afficher conditionnellement les autres
      return switch (s.settingId) {
        'exposure_compensation' => s.value != 0.0,
        'stabilization_body' => true, // Toujours utile de savoir ON/OFF
        'drive_mode' => s.value != 'single',
        _ => true,
      };
    }).toList();
  }

  static const _alwaysShow = {
    'exposure_mode', 'aperture', 'shutter_speed', 'iso',
    'white_balance_mode', 'af_mode', 'af_area', 'metering_mode', 'file_format',
  };
}
```

### 4.2. SettingRow — Un réglage dans la liste

```dart
// features/results/presentation/widgets/setting_row.dart

class SettingRow extends StatelessWidget {
  final SettingRecommendation setting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Indicateurs visuels
            if (setting.isCompromised)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
              ),
            if (setting.isOverride)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.tune, size: 16, color: theme.colorScheme.tertiary),
              ),

            // Nom du réglage + explication courte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _settingLabel(setting.settingId, context),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    setting.explanationShort,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Valeur
            Text(
              setting.valueDisplay,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _settingLabel(String settingId, BuildContext context) {
    // Noms lisibles en langue app (Couche 1, pas firmware)
    return switch (settingId) {
      'exposure_mode' => context.l10n.settingExposureMode,
      'aperture' => context.l10n.settingAperture,
      'shutter_speed' => context.l10n.settingShutterSpeed,
      'iso' => context.l10n.settingIso,
      'white_balance_mode' => context.l10n.settingWhiteBalance,
      'af_mode' => context.l10n.settingAfMode,
      'af_area' => context.l10n.settingAfArea,
      'metering_mode' => context.l10n.settingMetering,
      'exposure_compensation' => context.l10n.settingExposureComp,
      'file_format' => context.l10n.settingFileFormat,
      'stabilization_body' => context.l10n.settingStabilization,
      'drive_mode' => context.l10n.settingDriveMode,
      _ => settingId,
    };
  }
}
```

### 4.3. Bandeau de compromis

```dart
// features/results/presentation/widgets/compromise_banner.dart

class CompromiseBanner extends StatelessWidget {
  final List<Compromise> compromises;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (compromises.isEmpty) return const SizedBox.shrink();

    final worst = compromises.reduce((a, b) =>
        a.severity.index > b.severity.index ? a : b);

    final (bgColor, icon) = switch (worst.severity) {
      CompromiseSeverity.info => (Colors.blue.withOpacity(0.1), Icons.info_outline),
      CompromiseSeverity.warning => (Colors.orange.withOpacity(0.1), Icons.warning_amber_rounded),
      CompromiseSeverity.critical => (Colors.red.withOpacity(0.1), Icons.error_outline),
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                compromises.length == 1
                    ? compromises.first.message
                    : '${compromises.length} compromis effectués — tap pour voir',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. Niveau 2 — Écran détail d'un réglage

### 5.1. Structure de l'écran

```
┌──────────────────────────────────────┐
│ ← Résultats                          │
│                                      │
│ ┌────────────────────────────────┐   │
│ │           f/2.8                │   │
│ │         OUVERTURE              │   │
│ └────────────────────────────────┘   │
│                                      │
│ ── Pourquoi ce réglage ────────────  │
│                                      │
│ Ouverture grande ouverte (f/2.8)     │
│ pour maximiser le flou d'arrière-    │
│ plan sur ton portrait. C'est         │
│ l'ouverture max de ton Sigma         │
│ 18-50mm.                             │
│                                      │
│ ▼ En savoir plus                     │
│ ┌────────────────────────────────┐   │
│ │ À f/2.8, la profondeur de      │   │
│ │ champ est d'environ 30cm à     │   │
│ │ 3m de distance (à 50mm).       │   │
│ │                                │   │
│ │ Si tu passes à f/4 :           │   │
│ │ → PDC ~45cm, moins de flou     │   │
│ │ → Compenser : ISO 400 OU       │   │
│ │   vitesse 1/125s               │   │
│ │                                │   │
│ │ Si tu ouvres plus :            │   │
│ │ → Ton objectif ne descend pas  │   │
│ │   en dessous de f/2.8          │   │
│ └────────────────────────────────┘   │
│                                      │
│ ── Alternatives ───────────────────  │
│                                      │
│ ┌────────────────────────────────┐   │
│ │ f/4  → Plus de netteté en     │   │
│ │        profondeur              │   │
│ │   ISO 200 → 400               │   │
│ │   Vitesse inchangée            │   │
│ └────────────────────────────────┘   │
│ ┌────────────────────────────────┐   │
│ │ f/5.6 → PDC ~80cm             │   │
│ │   ISO 200 → 800               │   │
│ │   Vitesse inchangée            │   │
│ └────────────────────────────────┘   │
│                                      │
│ ── Compromis ──────────────────────  │
│ (section visible uniquement si       │
│  ce réglage a un compromis)          │
│                                      │
│ ┌──────────────────────────────┐     │
│ │  📍 Où régler sur mon A6700   │     │
│ └──────────────────────────────┘     │
│                                      │
└──────────────────────────────────────┘
```

### 5.2. Composant SettingDetailScreen

```dart
// features/results/presentation/screens/setting_detail_screen.dart

class SettingDetailScreen extends HookConsumerWidget {
  final String settingId;

  const SettingDetailScreen({required this.settingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(settingsResultProvider).valueOrNull;
    final setting = result?.settings.firstWhere((s) => s.settingId == settingId);
    final body = ref.watch(currentBodyProvider);

    if (setting == null || body == null) {
      return const Scaffold(body: ErrorDisplay(failure: UnknownFailure()));
    }

    final detailExpanded = useState(false);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du réglage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Valeur en gros
            _HeroValue(setting: setting),
            const SizedBox(height: 24),

            // Explication courte
            _SectionTitle(context.l10n.detailWhyThisSetting),
            const SizedBox(height: 8),
            Text(setting.explanationShort,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),

            // Override badge
            if (setting.isOverride)
              _OverrideBadge(),

            // Explication détaillée (expandable)
            _ExpandableDetail(
              expanded: detailExpanded.value,
              onToggle: () => detailExpanded.value = !detailExpanded.value,
              content: setting.explanationDetail,
            ),
            const SizedBox(height: 24),

            // Alternatives
            if (setting.alternatives.isNotEmpty) ...[
              _SectionTitle(context.l10n.detailAlternatives),
              const SizedBox(height: 8),
              ...setting.alternatives.map((alt) =>
                  _AlternativeCard(alternative: alt, currentValue: setting.valueDisplay)),
              const SizedBox(height: 24),
            ],

            // Compromis lié à ce réglage
            if (setting.isCompromised) ...[
              _SectionTitle(context.l10n.detailCompromise),
              const SizedBox(height: 8),
              ...result!.compromises
                  .where((c) => c.affectedSettings.contains(settingId))
                  .map((c) => _CompromiseDetail(compromise: c)),
              const SizedBox(height: 24),
            ],

            // CTA Navigation menu
            _MenuNavButton(
              bodyName: body.displayName,
              settingId: settingId,
              onTap: () => context.go('/menu-nav/$settingId'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
```

### 5.3. La valeur "héro"

La valeur du réglage est affichée en gros, centré, comme un chiffre clé. C'est la première chose que l'œil voit.

```dart
class _HeroValue extends StatelessWidget {
  final SettingRecommendation setting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Text(
            setting.valueDisplay,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: setting.isCompromised
                  ? Colors.orange
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _settingLabel(setting.settingId, context).toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 5.4. Override badge

Quand l'utilisateur a forcé une valeur via le Niveau 3 du Scene Input, un badge le rappelle.

```dart
class _OverrideBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune, size: 14, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(width: 6),
          Text(
            'Valeur que tu as choisie manuellement',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 6. Système d'explications

### 6.1. Architecture

Les explications sont générées par le `ExplanationGenerator` (couche Domain, features/settings_engine). Elles sont **templates-based** avec des variables injectées à partir du contexte.

```
ExplanationGenerator
  │
  │ Inputs :
  │   - setting_id + value (le réglage recommandé)
  │   - EngineContext (body, lens, scene, EV, focale...)
  │   - Compromises (s'il y en a pour ce réglage)
  │
  │ Outputs :
  │   - explanation_short : String (1 phrase)
  │   - explanation_detail : String (paragraphe complet)
  │
  └── Utilise des templates i18n (Couche 1, langue app)
      avec injection de variables dynamiques
```

### 6.2. Templates d'explication complets

Chaque réglage a un template court et un template détaillé. Les templates sont dans les fichiers ARB (i18n Couche 1).

```json
// l10n/app_fr.arb (extraits explications)
{
  "explainApertureShort_bokeh": "Ouverture {value} grande ouverte pour maximiser le flou d'arrière-plan avec ton {lens}.",
  "explainApertureShort_sharpness": "Ouverture {value} au sweet spot de netteté de ton {lens}.",
  "explainApertureShort_lowLight": "Ouverture {value} grande ouverte pour capter le maximum de lumière.",
  "explainApertureShort_freeze": "Ouverture {value} grande ouverte pour compenser la vitesse élevée.",
  "explainApertureShort_blur": "Ouverture {value} fermée pour réduire la lumière et permettre une pose longue.",

  "explainApertureDetail_bokeh": "À {value} et {focal}mm sur {sensorType}, la profondeur de champ est d'environ {dofCm}cm à {distanceM}m de distance. Tout ce qui est en dehors de cette zone sera flou.\n\nC'est l'ouverture maximale de ton {lens}. Pour encore plus de flou, il faudrait un objectif type 50mm f/1.4 ou 85mm f/1.8.",
  "explainApertureDetail_sharpness": "Le sweet spot de ton {lens} est autour de {value} — c'est l'ouverture où la netteté est maximale au centre de l'image. En dessous de {value}, la diffraction commence à réduire la netteté sur ton capteur {sensorType}.",

  "explainShutterShort_freeze": "Vitesse {value} pour figer le mouvement de ton sujet.",
  "explainShutterShort_handheld": "Vitesse {value} pour éviter le flou de bougé à main levée à {focal}mm.",
  "explainShutterShort_tripod": "Vitesse {value} possible grâce au trépied.",
  "explainShutterShort_astro": "Vitesse {value} calculée par la règle NPF pour des étoiles ponctuelles à {focal}mm.",
  "explainShutterShort_video": "Vitesse {value} selon la règle du double (shutter angle 180° à {fps}fps).",

  "explainShutterDetail_handheld": "La règle de base est 1/{focalEq}s (1 / focale équivalente). Avec la stabilisation de ton {bodyOrLens} ({stabStops} stops), tu peux descendre à {safeSpeed}s. On recommande {value} pour garder une marge de sécurité.",

  "explainIsoShort_low": "ISO {value} — bruit quasi inexistant.",
  "explainIsoShort_moderate": "ISO {value} — bruit très faible.",
  "explainIsoShort_acceptable": "ISO {value} — bruit visible mais acceptable.",
  "explainIsoShort_noisy": "ISO {value} — bruit notable, shooter en RAW recommandé pour le réduire en post.",
  "explainIsoShort_veryNoisy": "ISO {value} — bruit élevé. Compromis nécessaire pour cette scène.",

  "explainIsoDetail": "Ton {body} gère bien le bruit jusqu'à ISO {usableMax}. Au-delà, le bruit devient visible sur un crop 100%. À ISO {value}, {noiseAssessment}.\n\nEn RAW, tu pourras réduire le bruit avec un logiciel comme Lightroom (débruitage) ou un outil spécialisé comme DxO PureRAW.",

  "explainAfShort_afs": "AF ponctuel — verrouille la mise au point une fois. Idéal pour un sujet immobile.",
  "explainAfShort_afc": "AF continu — suit ton sujet en mouvement. Maintiens le déclencheur enfoncé à mi-course.",
  "explainAfShort_mf": "Mise au point manuelle — contrôle total. Utilise le zoom d'aide pour vérifier la netteté.",

  "explainWbShort_auto": "Balance des blancs auto — suffisant en RAW, ajustable en post.",
  "explainWbShort_preset": "Balance des blancs {preset} ({kelvin}K) pour des couleurs fidèles à cette lumière.",

  "explainMeteringShort_multi": "Mesure matricielle — évalue toute la scène pour une exposition équilibrée.",
  "explainMeteringShort_center": "Mesure centre pondéré — priorise le centre du cadre pour exposer le sujet.",
  "explainMeteringShort_spot": "Mesure spot — mesure uniquement sur le point AF. Contrôle précis.",
  "explainMeteringShort_silhouette": "Mesure spot sur le fond lumineux — sous-expose volontairement le sujet pour créer la silhouette.",

  "explainFormatShort_raw": "RAW capture toute l'information du capteur. Tu pourras tout ajuster en post sans perte de qualité.",
  "explainFormatShort_jpeg": "JPEG — fichier léger, prêt à partager. Moins de marge de correction en post.",

  "explainStabShort_on": "Stabilisation activée — compense les micro-mouvements à main levée.",
  "explainStabShort_off": "Stabilisation désactivée — sur trépied, elle peut introduire des vibrations parasites."
}
```

### 6.3. ExplanationGenerator — Implémentation

```dart
// features/settings_engine/domain/engine/explanation_generator.dart

class ExplanationGenerator {
  final AppLocalizations l10n;

  ExplanationGenerator(this.l10n);

  ExplanationPair generate({
    required String settingId,
    required dynamic value,
    required EngineContext ctx,
  }) {
    return switch (settingId) {
      'aperture' => _explainAperture(value as FStop, ctx),
      'shutter_speed' => _explainShutter(value as ShutterSpeed, ctx),
      'iso' => _explainIso(value as int, ctx),
      'af_mode' => _explainAfMode(value as String, ctx),
      'af_area' => _explainAfArea(value as String, ctx),
      'metering_mode' => _explainMetering(value as String, ctx),
      'white_balance_mode' => _explainWb(value, ctx),
      'file_format' => _explainFormat(value as String, ctx),
      'stabilization_body' => _explainStab(value as bool, ctx),
      'exposure_mode' => _explainExposureMode(value as String, ctx),
      'exposure_compensation' => _explainExposureComp(value as double, ctx),
      'drive_mode' => _explainDrive(value as String, ctx),
      _ => ExplanationPair(short: value.toString(), detail: ''),
    };
  }

  ExplanationPair _explainAperture(FStop value, EngineContext ctx) {
    final short = switch (ctx.scene.intention) {
      Intention.bokeh => l10n.explainApertureShort_bokeh(
          value: value.display, lens: ctx.lens.displayName),
      Intention.maxSharpness => l10n.explainApertureShort_sharpness(
          value: value.display, lens: ctx.lens.displayName),
      Intention.lowLight => l10n.explainApertureShort_lowLight(
          value: value.display, lens: ctx.lens.displayName),
      Intention.freezeMotion => l10n.explainApertureShort_freeze(
          value: value.display, lens: ctx.lens.displayName),
      Intention.motionBlur => l10n.explainApertureShort_blur(
          value: value.display, lens: ctx.lens.displayName),
    };

    final dofCm = _calculateDofCm(value, ctx);
    final detail = switch (ctx.scene.intention) {
      Intention.bokeh => l10n.explainApertureDetail_bokeh(
          value: value.display,
          focal: ctx.resolvedFocalMm.toString(),
          sensorType: ctx.body.sensorSize.label,
          dofCm: dofCm.round().toString(),
          distanceM: ctx.resolvedDistanceM.toStringAsFixed(1),
          lens: ctx.lens.displayName),
      _ => l10n.explainApertureDetail_sharpness(
          value: value.display,
          lens: ctx.lens.displayName,
          sensorType: ctx.body.sensorSize.label),
    };

    return ExplanationPair(short: short, detail: detail);
  }

  ExplanationPair _explainIso(int value, EngineContext ctx) {
    final usableMax = ctx.body.spec.sensor.isoUsableMax;
    final short = switch (value) {
      <= 400 => l10n.explainIsoShort_low(value: value.toString()),
      _ when value <= usableMax ~/ 2 =>
        l10n.explainIsoShort_moderate(value: value.toString()),
      _ when value <= usableMax =>
        l10n.explainIsoShort_acceptable(value: value.toString()),
      _ when value <= usableMax * 2 =>
        l10n.explainIsoShort_noisy(value: value.toString()),
      _ => l10n.explainIsoShort_veryNoisy(value: value.toString()),
    };

    final noiseAssessment = value <= usableMax
        ? 'le bruit est gérable'
        : 'le bruit sera visible, surtout dans les zones sombres';

    final detail = l10n.explainIsoDetail(
      body: ctx.body.displayName,
      usableMax: usableMax.toString(),
      value: value.toString(),
      noiseAssessment: noiseAssessment,
    );

    return ExplanationPair(short: short, detail: detail);
  }

  // ... etc pour chaque réglage
}

class ExplanationPair {
  final String short;
  final String detail;
  const ExplanationPair({required this.short, required this.detail});
}
```

---

## 7. Alternatives et cascade

### 7.1. Affichage d'une alternative

Chaque alternative montre la valeur proposée, ce qu'on gagne, ce qu'on perd, et les changements en cascade sur les autres réglages.

```dart
// features/results/presentation/widgets/alternative_card.dart

class AlternativeCard extends StatelessWidget {
  final Alternative alternative;
  final String currentValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : valeur alternative
            Row(
              children: [
                Text(
                  alternative.valueDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '(au lieu de $currentValue)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Trade-off
            Text(
              alternative.tradeOff,
              style: theme.textTheme.bodyMedium,
            ),

            // Changements en cascade
            if (alternative.cascadeChanges.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...alternative.cascadeChanges.map((change) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.subdirectory_arrow_right, size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${_settingLabel(change.settingId, context)} : '
                      '${change.fromValue} → ${change.toValue}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 7.2. Exemples concrets d'alternatives

**Pour Ouverture f/2.8 (intention bokeh) :**

```
Alternative 1 :
  f/4 (au lieu de f/2.8)
  "Plus de netteté en profondeur — la zone nette passe de ~30cm à ~45cm"
  → ISO : 200 → 400
  → Vitesse : inchangée

Alternative 2 :
  f/5.6 (au lieu de f/2.8)
  "Netteté sur tout le visage — zone nette ~80cm. Moins de flou d'arrière-plan."
  → ISO : 200 → 800
  → Vitesse : inchangée
```

**Pour ISO 3200 (low-light, compromis bruit) :**

```
Alternative 1 :
  ISO 1600 (au lieu de 3200)
  "Moins de bruit, mais risque de flou si le sujet bouge"
  → Vitesse : 1/125s → 1/60s

Alternative 2 :
  ISO 6400 (au lieu de 3200)
  "Plus de marge de vitesse pour figer le mouvement, mais bruit plus visible"
  → Vitesse : 1/125s → 1/250s
```

---

## 8. Copier les réglages

### 8.1. Bouton 📋

Le bouton copie dans le presse-papier un résumé texte de tous les réglages — utile pour les noter quelque part ou les partager.

```dart
// features/results/domain/use_cases/format_settings_for_clipboard.dart

class FormatSettingsForClipboard {
  String execute(SettingsResult result, Body body, Lens lens, SceneInput scene) {
    final buffer = StringBuffer();

    buffer.writeln('ShootHelper — ${body.displayName} + ${lens.displayName}');
    buffer.writeln('${scene.subject.name} · ${scene.environment.name} · ${scene.intention.name}');
    buffer.writeln('');

    for (final setting in result.settings) {
      final label = _labelFor(setting.settingId);
      buffer.writeln('$label : ${setting.valueDisplay}');
    }

    if (result.compromises.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('⚠️ Compromis :');
      for (final c in result.compromises) {
        buffer.writeln('- ${c.message}');
      }
    }

    return buffer.toString();
  }
}
```

**Résultat copié :**

```
ShootHelper — A6700 + Sigma 18-50mm f/2.8
Portrait · Extérieur Jour · Flou arrière-plan

Mode : M
Ouverture : f/2.8
Vitesse : 1/250s
ISO : 200
Balance blancs : Auto (5500K)
Mode AF : AF-C
Zone AF : Eye-AF
Mesure : Matricielle
Format : RAW
Stabilisation : ON
```

### 8.2. Feedback

Après le tap sur 📋, un snackbar s'affiche : "Réglages copiés" pendant 2 secondes. Pas de popup, pas de modal — un retour discret.

```dart
IconButton(
  icon: const Icon(Icons.copy),
  onPressed: () {
    final text = ref.read(formatSettingsForClipboardProvider)
        .execute(result, body, lens, scene);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réglages copiés'),
        duration: Duration(seconds: 2),
      ),
    );
  },
)
```

---

## 9. Assemblage de l'écran Results complet

```dart
// features/results/presentation/screens/results_screen.dart

class ResultsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(settingsResultProvider);
    final body = ref.watch(currentBodyProvider);
    final lens = ref.watch(currentLensProvider);
    final scene = ref.watch(submittedSceneProvider);

    return resultAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: ErrorDisplay(failure: _mapFailure(e))),
      data: (result) {
        if (result == null || body == null || lens == null || scene == null) {
          return const Scaffold(body: _EmptyState());
        }

        final displaySettings = ref.read(filterDisplaySettingsProvider)
            .execute(result.settings);

        return Scaffold(
          appBar: AppBar(
            leading: TextButton(
              onPressed: () => context.go('/scene-input'),
              child: const Text('← Modifier'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copier les réglages',
                onPressed: () => _copyToClipboard(context, ref, result, body, lens, scene),
              ),
            ],
          ),
          body: ListView(
            children: [
              // Niveau 0 : Résumé express
              Padding(
                padding: const EdgeInsets.all(16),
                child: ExposureSummaryCard(
                  result: result, body: body, lens: lens, scene: scene,
                ),
              ),

              // Bandeau compromis
              if (result.compromises.isNotEmpty)
                CompromiseBanner(
                  compromises: result.compromises,
                  onTap: () => _scrollToCompromisedSetting(result),
                ),

              // Niveau 1 : Liste des réglages
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Tous les réglages',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              ...displaySettings.map((setting) => SettingRow(
                setting: setting,
                onTap: () => context.go('/results/detail/${setting.settingId}'),
              )),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 10. Scénarios de test

### 10.1. Tests d'affichage

| # | Scénario | Vérification |
|---|----------|-------------|
| T1 | Résultat normal (portrait, bokeh, outdoor day) | ExposureSummaryCard affiche M, f/2.8, 1/250s, ISO 200. Badge "fiable". |
| T2 | Résultat avec 1 compromis (ISO haute) | Bandeau orange visible. Setting ISO a l'icône ⚠️. |
| T3 | Résultat avec compromis critical | Bandeau rouge. Badge confiance "Compromis importants". |
| T4 | Résultat sans comp. expo ni drive spécial | Settings "Compensation" et "Drive" absents de la liste |
| T5 | Résultat avec comp. expo +1.3 EV | Setting "Compensation" visible dans la liste avec "+1.3 EV" |
| T6 | Tap sur un réglage | Navigation vers SettingDetailScreen avec le bon settingId |
| T7 | Tap 📋 | Texte copié dans le presse-papier, snackbar "Réglages copiés" |
| T8 | Setting overridé par l'utilisateur (Niveau 3) | Badge "Valeur que tu as choisie" visible dans le détail |

### 10.2. Tests des explications

| # | Input | Explication courte attendue (début) |
|---|-------|--------------------------------------|
| T9 | f/2.8, bokeh | "Ouverture f/2.8 grande ouverte pour maximiser le flou…" |
| T10 | f/8, max_sharpness | "Ouverture f/8 au sweet spot de netteté…" |
| T11 | ISO 200 | "ISO 200 — bruit quasi inexistant." |
| T12 | ISO 6400, body usable_max=6400 | "ISO 6400 — bruit visible mais acceptable." |
| T13 | ISO 12800, body usable_max=6400 | "ISO 12800 — bruit notable, shooter en RAW…" |
| T14 | 1/250s, handheld, 50mm | "Vitesse 1/250s pour éviter le flou de bougé…" |
| T15 | 12s, astro, 18mm | "Vitesse 12s calculée par la règle NPF…" |
| T16 | AF-C, sport | "AF continu — suit ton sujet en mouvement." |

### 10.3. Tests des alternatives

| # | Réglage principal | Alternative | Cascade attendue |
|---|-------------------|-------------|------------------|
| T17 | f/2.8 (bokeh) | f/4 | ISO 200 → 400 |
| T18 | ISO 3200 (low-light) | ISO 1600 | Vitesse 1/125s → 1/60s |
| T19 | 1/500s (freeze) | 1/250s | ISO 3200 → 1600 |

---

## 11. Principes de rédaction des explications

### 11.1. Ton

Les explications parlent à un **débutant curieux**. Pas de jargon non expliqué, pas de condescendance non plus. Le ton est celui d'un ami photographe un peu plus expérimenté.

| Principe | Exemple ✅ | Contre-exemple ❌ |
|----------|-----------|-------------------|
| Direct, 2ème personne | "Ton objectif ne descend pas en dessous de f/2.8" | "L'objectif de l'utilisateur a une ouverture maximale de f/2.8" |
| Conséquence pratique | "Le bruit sera visible dans les zones sombres" | "Le rapport signal/bruit diminue à haute sensibilité ISO" |
| Si/alors concret | "Si tu passes à f/4, l'ISO monte à 400" | "La modification de l'ouverture impacte les autres paramètres d'exposition" |
| Nommer le matériel | "Ton Sigma 18-50mm" | "L'objectif sélectionné" |

### 11.2. Structure courte vs détaillée

**Explication courte (1 phrase)** : La valeur + pourquoi pour cette scène. Le lecteur doit comprendre le raisonnement en 5 secondes.

**Explication détaillée (paragraphe)** : Conséquence pratique + "et si je changeais" + limites du matériel. Le lecteur doit comprendre les trade-offs pour prendre une décision éclairée.

### 11.3. Toujours mentionner le matériel

Les explications mentionnent systématiquement le nom du boîtier ou de l'objectif quand c'est pertinent. "Bruit visible sur ton A6700" est plus utile que "Bruit visible" — ça ancre l'information dans le contexte du matériel de l'utilisateur.

---

*Ce document est la référence pour l'implémentation de l'écran Résultats et de tout le système d'explications. Combiné avec le skill 19 (Menu Navigation Mapper) qui prend le relais quand l'utilisateur tape "Où régler sur mon appareil", il couvre tout le flow post-calcul.*
