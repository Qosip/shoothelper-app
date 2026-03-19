# Scene Input System — ShootHelper

> **Skill 17/22** · Paramètres de scène, UX progressive, filtrage contextuel
> Version 1.0 · Mars 2026
> Réf : 01_PRD.md, 02_USER_FLOWS.md, 06_SETTINGS_ENGINE.md, 11_STATE_MANAGEMENT.md

---

## 1. Le défi UX

Le Scene Input est l'écran où l'utilisateur passe le plus de temps. C'est aussi le plus risqué en termes d'UX : trop simple → résultats génériques sans valeur. Trop complexe → l'utilisateur abandonne.

**L'objectif** : un débutant doit pouvoir obtenir des réglages utiles en **4 taps** (Niveau 1). Un photographe curieux doit pouvoir affiner sa description sans limites (Niveaux 2-3). Même écran, même flow — c'est la progressive disclosure qui fait le travail.

**Principes :**

1. **4 taps minimum, pas 0** — L'utilisateur doit faire un effort minimal de description. "Calcule tout pour moi" sans contexte donnerait des résultats inutiles.
2. **Chaque tap a de la valeur** — Chaque paramètre renseigné améliore significativement la précision du résultat. Pas de champ "pour la forme".
3. **Tout est visible, rien n'est caché dans un menu** — Chips, pas de dropdowns. L'utilisateur voit toutes les options d'un coup.
4. **Le bouton "Calculer" est toujours accessible** — Sticky en bas de l'écran. L'utilisateur peut cliquer à tout moment, même au milieu du Niveau 2.
5. **Pas de texte libre** — Tout est structuré. Pas de "décris ta scène en mots". Le moteur a besoin de données discrètes, pas de prose.

---

## 2. Catalogue complet des paramètres

### 2.1. Niveau 1 — Obligatoire (4 paramètres)

Chaque paramètre est une sélection unique parmi des chips.

#### Type de shoot

```
PARAMÈTRE : shoot_type
SÉLECTION : unique
REQUIS    : oui

VALEURS :
┌──────────────────────────────────┐
│  📷 Photo      │   🎥 Vidéo     │
└──────────────────────────────────┘

Impact moteur :
  photo → règles d'exposition classiques
  video → règle du double (shutter angle 180°), framerate implied
```

#### Environnement

```
PARAMÈTRE : environment
SÉLECTION : unique
REQUIS    : oui

VALEURS :
┌──────────┐ ┌──────────┐ ┌──────────┐
│ ☀️ Ext.  │ │ 🌙 Ext.  │ │ 💡 Int.  │
│   Jour   │ │   Nuit   │ │   Clair  │
└──────────┘ └──────────┘ └──────────┘
┌──────────┐ ┌──────────┐
│ 🔅 Int.  │ │ 🎬 Studio│
│  Sombre  │ │          │
└──────────┘ └──────────┘

Impact moteur :
  Détermine le EV de base (table §3.3 du skill 06)
  outdoor_day  → EV 14    outdoor_night → EV 4
  indoor_bright → EV 9    indoor_dark   → EV 6
  studio → EV 11
```

#### Sujet

```
PARAMÈTRE : subject
SÉLECTION : unique
REQUIS    : oui

VALEURS (chips scrollables horizontalement) :
┌─────────┐ ┌─────────┐ ┌────────┐ ┌──────────────┐
│ 🏔 Pays.│ │ 👤 Portr│ │ 🚶 Str.│ │ 🏛 Architect.│
└─────────┘ └─────────┘ └────────┘ └──────────────┘
┌────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐
│ 🔍 Mac.│ │ ⭐ Ast.│ │ ⚽ Sport │ │ 🦅 Anim. │ │ 📦 Prod.│
└────────┘ └────────┘ └──────────┘ └──────────┘ └─────────┘

Impact moteur :
  Détermine la focale cible, la zone AF, le mode AF, le drive,
  et influence l'ouverture optimale.

Valeurs :
  landscape, portrait, street, architecture, macro, astro,
  sport, wildlife, product
```

#### Intention

```
PARAMÈTRE : intention
SÉLECTION : unique
REQUIS    : oui

VALEURS :
┌────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ 🔬 Netteté │ │ 🌀 Flou arrière │ │ ⚡ Figer mvt    │
│    max      │ │    plan         │ │                 │
└────────────┘ └─────────────────┘ └─────────────────┘
┌─────────────────┐ ┌────────────────┐
│ 💨 Filé mvt     │ │ 🌃 Low-light   │
│                 │ │    perf        │
└─────────────────┘ └────────────────┘

Impact moteur :
  Détermine la PRIORITÉ du triangle d'exposition.
  bokeh         → ouverture fixée en premier (max)
  max_sharpness → ouverture fixée en premier (sweet spot)
  freeze_motion → vitesse fixée en premier (rapide)
  motion_blur   → vitesse fixée en premier (lente)
  low_light     → ouverture max + vitesse min acceptable
```

### 2.2. Niveau 2 — Optionnel (6 paramètres + 2 contraintes)

Chaque paramètre non renseigné = le moteur utilise sa valeur par défaut intelligente (déduite du Niveau 1).

#### Conditions de lumière

```
PARAMÈTRE : light_condition
SÉLECTION : unique
REQUIS    : non

VALEURS :
  ☀️ Soleil direct   🌤 Ombre         ☁️ Couvert
  🌅 Golden hour     🌆 Blue hour     🌌 Nuit étoilée
  💡 Néon            💡 Tungstène     💡 LED

SI NON RENSEIGNÉ :
  Le moteur déduit de environment :
  outdoor_day → moyenne soleil/couvert (EV ~14)
  outdoor_night → moyenne nuit urbaine (EV ~4)
  etc.

IMPACT : Affine l'EV cible (+/- 3 stops de précision vs environment seul)
         + influence le preset balance des blancs
```

#### Mouvement du sujet

```
PARAMÈTRE : subject_motion
SÉLECTION : unique
REQUIS    : non

VALEURS :
  🧍 Immobile    🚶 Lent    🏃 Rapide    🏎️ Très rapide

SI NON RENSEIGNÉ :
  Le moteur déduit de subject :
  landscape/architecture/product → immobile
  portrait → immobile (par défaut)
  street → lent
  sport → rapide
  wildlife → rapide
  astro → immobile (les étoiles bougent lentement)
  macro → immobile

IMPACT : Détermine la vitesse minimum dictée par le sujet
```

#### Distance du sujet

```
PARAMÈTRE : subject_distance
SÉLECTION : unique
REQUIS    : non

VALEURS :
  🔬 < 50cm    📏 1-3m    📐 3-10m    🔭 > 10m    ♾️ Infini

SI NON RENSEIGNÉ :
  Le moteur déduit de subject :
  macro → very_close
  portrait → close (1-3m)
  street → medium (3-10m)
  landscape/astro → infinity
  sport/wildlife → far (>10m)
  architecture → far
  product → close

IMPACT : Affecte le calcul de profondeur de champ
         + validation distance min de MAP de l'objectif
```

#### Mood / Rendu souhaité

```
PARAMÈTRE : mood
SÉLECTION : unique
REQUIS    : non

VALEURS :
  🎭 Dramatique    🌸 Doux/pastel    ⚫ High contrast
  🌿 Naturel       👤 Silhouette

SI NON RENSEIGNÉ : naturel (pas d'ajustement d'exposition)

IMPACT : Ajuste la compensation d'exposition
  dramatique    → -0.5 EV
  soft          → +0.3 EV
  high_contrast → comp. expo 0, mode mesure spot
  natural       → aucun ajustement
  silhouette    → -2 EV, mesure sur le fond
```

#### Support

```
PARAMÈTRE : support
SÉLECTION : unique
REQUIS    : non

VALEURS :
  🤚 Main levée    📐 Trépied    🦯 Monopode    🎥 Gimbal

SI NON RENSEIGNÉ : handheld (cas le plus courant)

IMPACT : Détermine la vitesse minimum de sécurité (bougé)
  handheld → 1/focale (avec bonus stabilisation)
  tripod   → pas de limite + stabilisation OFF recommandée
  monopod  → 1/focale × 0.5
  gimbal   → 1/30s minimum
```

#### Contraintes (ISO max, vitesse min)

```
PARAMÈTRE : constraint_iso_max
TYPE      : slider numérique (activé par checkbox)
REQUIS    : non
RANGE     : body.spec.iso_range.min → body.spec.iso_range.max
CRANS     : valeurs ISO standard (100, 125, 160, 200, ..., 51200)
DÉFAUT    : non activé (le moteur choisit librement)

PARAMÈTRE : constraint_shutter_min
TYPE      : slider numérique (activé par checkbox)
REQUIS    : non
RANGE     : body.spec.shutter.electronic.min → 30s
CRANS     : valeurs de vitesse standard (1/8000 ... 30s)
DÉFAUT    : non activé

IMPACT : Le moteur respecte ces contraintes. Si impossible → compromis
         critique (skill 15, C5).

UX : Les sliders sont DÉSACTIVÉS par défaut. L'utilisateur coche
     la checkbox pour les activer. Ça évite les contraintes accidentelles.
```

### 2.3. Niveau 3 — Avancé / Override (5 paramètres)

Les paramètres Niveau 3 **overrident le calcul automatique du moteur**. Le moteur ne recalcule pas ces valeurs — il les prend telles quelles et vérifie la compatibilité.

#### Température couleur (WB override)

```
PARAMÈTRE : wb_override
TYPE      : radio + slider conditionnel
REQUIS    : non

OPTIONS :
  ○ Auto (laisser le moteur choisir)     ← défaut
  ○ Preset : chips [Daylight] [Cloudy] [Shade] [Tungsten] [Fluorescent]
  ○ Manuel : slider 2500K — 10000K

IMPACT : Override le calcul WB du moteur.
         Le moteur indique "Valeur forcée par l'utilisateur" dans l'explication.
```

#### Profondeur de champ

```
PARAMÈTRE : dof_preference
SÉLECTION : unique (chips) + input numérique optionnel
REQUIS    : non

VALEURS :
  🔵 Shallow (flou max)    🟡 Medium    🟢 Deep (netteté max)

OPTION AVANCÉE :
  ☐ Préciser en mètres :
    Début zone nette : [___] m
    Fin zone nette :   [___] m

SI NON RENSEIGNÉ : déduit de intention
  bokeh → shallow
  max_sharpness → deep
  autres → medium

IMPACT : Influence le choix d'ouverture indépendamment de l'intention.
```

#### Zone AF (override)

```
PARAMÈTRE : af_area_override
SÉLECTION : unique
REQUIS    : non

VALEURS :
  ⊕ Centre    ▣ Zone large    🎯 Suivi    👁 Eye-AF

FILTRAGE : les chips non supportés par le boîtier sont grisés
           avec tooltip "Non disponible sur ton {body}" (skill 15, D1)

IMPACT : Override le calcul de zone AF. Le moteur vérifie la compatibilité
         et peut auto-switch si nécessaire (ex: Eye-AF → AF-C obligatoire).
```

#### Bracketing

```
PARAMÈTRE : bracketing
SÉLECTION : unique
REQUIS    : non

VALEURS :
  ✖ Aucun    📊 Exposition    🔍 Focus

FILTRAGE : Focus bracketing grisé si non supporté par le boîtier

IMPACT : Modifie le mode drive + nombre de prises recommandé
```

#### Format fichier

```
PARAMÈTRE : file_format_override
SÉLECTION : unique
REQUIS    : non

VALEURS :
  📄 RAW    🖼️ JPEG    📄+🖼️ RAW+JPEG

DÉFAUT : non renseigné → le moteur recommande RAW

IMPACT : Si JPEG → la balance des blancs et le mood ont plus d'importance
         (pas de correction post en JPEG)
```

---

## 3. Intelligence contextuelle

Le système ne se contente pas d'afficher des options statiques. Il **adapte l'UI** en fonction de ce que l'utilisateur a déjà sélectionné.

### 3.1. Pré-sélection intelligente (Niveau 2)

Quand l'utilisateur remplit le Niveau 1, certains paramètres du Niveau 2 sont **pré-sélectionnés** (mais modifiables) pour réduire le nombre de taps.

```dart
// features/scene_input/domain/use_cases/suggest_scene_defaults.dart

class SuggestSceneDefaults {
  /// Retourne des suggestions de Niveau 2 basées sur le Niveau 1
  SceneInputDraftState suggest(SceneInputDraftState current) {
    if (!current.isLevel1Complete) return current;

    return current.copyWith(
      // Mouvement du sujet
      subjectMotion: current.subjectMotion ?? _suggestMotion(current.subject!),

      // Distance du sujet
      subjectDistance: current.subjectDistance ?? _suggestDistance(current.subject!),

      // Support
      support: current.support ?? _suggestSupport(current.subject!, current.environment!),

      // Note : light_condition et mood ne sont PAS pré-sélectionnés
      // car ils sont trop subjectifs et le risque de mauvaise suggestion est élevé
    );
  }

  SubjectMotion _suggestMotion(Subject subject) => switch (subject) {
    Subject.landscape || Subject.architecture || Subject.product => SubjectMotion.still,
    Subject.portrait => SubjectMotion.still,
    Subject.street => SubjectMotion.slow,
    Subject.macro => SubjectMotion.still,
    Subject.astro => SubjectMotion.still,
    Subject.sport => SubjectMotion.fast,
    Subject.wildlife => SubjectMotion.fast,
  };

  SubjectDistance _suggestDistance(Subject subject) => switch (subject) {
    Subject.macro => SubjectDistance.veryClose,
    Subject.portrait || Subject.product => SubjectDistance.close,
    Subject.street => SubjectDistance.medium,
    Subject.architecture => SubjectDistance.far,
    Subject.sport || Subject.wildlife => SubjectDistance.far,
    Subject.landscape || Subject.astro => SubjectDistance.infinity,
  };

  Support _suggestSupport(Subject subject, Environment env) => switch (subject) {
    Subject.astro => Support.tripod,
    _ => Support.handheld,
  };
}
```

### 3.2. Affichage des suggestions

Les valeurs pré-sélectionnées sont visuellement différentes des sélections explicites de l'utilisateur : un **style "suggéré"** (contour pointillé ou couleur plus claire) vs un **style "confirmé"** (plein).

```dart
// features/scene_input/presentation/widgets/smart_chip.dart

class SmartChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isSuggestion; // true = pré-sélectionné par l'intelligence
  final VoidCallback? onTap;
  final bool enabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip ?? '',
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: enabled ? (_) => onTap?.call() : null,
        backgroundColor: !enabled
            ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
            : null,
        selectedColor: isSuggestion
            ? theme.colorScheme.primaryContainer.withOpacity(0.5) // Suggéré = plus léger
            : theme.colorScheme.primaryContainer,                  // Confirmé = plein
        side: isSuggestion
            ? BorderSide(color: theme.colorScheme.primary, style: BorderStyle.solid, width: 0.5)
            : null,
        showCheckmark: !isSuggestion,
      ),
    );
  }
}
```

**UX subtile** : quand l'utilisateur tap un chip pré-sélectionné, il passe en "confirmé" (visuel change). S'il tap un chip différent dans la même catégorie, le suggéré est remplacé. L'utilisateur perçoit que l'app "a compris" son contexte mais le laisse corriger.

### 3.3. Filtrage contextuel des options

Certaines combinaisons de Niveau 1 rendent des options de Niveau 2 non pertinentes. Au lieu de les cacher (ce qui désoriente), on les **reordonne** pour mettre les plus pertinentes en premier.

```dart
// features/scene_input/domain/use_cases/get_contextual_options.dart

class GetContextualOptions {
  /// Retourne les conditions de lumière ordonnées par pertinence
  List<LightCondition> getLightConditions(Environment env) => switch (env) {
    Environment.outdoorDay => [
      LightCondition.directSun,
      LightCondition.overcast,
      LightCondition.shade,
      LightCondition.goldenHour,
      // Puis les moins probables
      LightCondition.blueHour,
      LightCondition.led,
      LightCondition.neon,
      LightCondition.tungsten,
      LightCondition.starryNight,
    ],
    Environment.outdoorNight => [
      LightCondition.starryNight,
      LightCondition.blueHour,
      LightCondition.neon,
      LightCondition.led,
      LightCondition.tungsten,
      // Puis les moins probables
      LightCondition.directSun,
      LightCondition.overcast,
      LightCondition.shade,
      LightCondition.goldenHour,
    ],
    Environment.indoorBright => [
      LightCondition.led,
      LightCondition.neon,
      LightCondition.tungsten,
      LightCondition.directSun,  // fenêtre avec soleil
      LightCondition.overcast,
      LightCondition.shade,
      LightCondition.goldenHour,
      LightCondition.blueHour,
      LightCondition.starryNight,
    ],
    Environment.indoorDark => [
      LightCondition.tungsten,
      LightCondition.led,
      LightCondition.neon,
      LightCondition.shade,
      LightCondition.overcast,
      LightCondition.directSun,
      LightCondition.goldenHour,
      LightCondition.blueHour,
      LightCondition.starryNight,
    ],
    Environment.studio => [
      LightCondition.led,
      LightCondition.tungsten,
      LightCondition.neon,
      LightCondition.directSun,
      LightCondition.overcast,
      LightCondition.shade,
      LightCondition.goldenHour,
      LightCondition.blueHour,
      LightCondition.starryNight,
    ],
  };

  /// Retourne les moods ordonnés par pertinence selon le sujet
  List<Mood> getMoods(Subject subject) => switch (subject) {
    Subject.portrait => [Mood.natural, Mood.soft, Mood.dramatic, Mood.highContrast, Mood.silhouette],
    Subject.landscape => [Mood.natural, Mood.dramatic, Mood.highContrast, Mood.soft, Mood.silhouette],
    Subject.street => [Mood.natural, Mood.dramatic, Mood.highContrast, Mood.soft, Mood.silhouette],
    Subject.astro => [Mood.natural, Mood.dramatic, Mood.highContrast, Mood.soft, Mood.silhouette],
    _ => Mood.values,
  };
}
```

### 3.4. Hint contextuel

Un texte court sous chaque catégorie explique pourquoi ce paramètre est utile. Le texte change selon le contexte.

```dart
// features/scene_input/domain/use_cases/get_contextual_hints.dart

class GetContextualHints {
  /// Hint pour la section "Conditions de lumière"
  String getLightHint(Environment env) => switch (env) {
    Environment.outdoorDay =>
      'Précise la lumière pour affiner l\'EV. Soleil direct ≠ golden hour.',
    Environment.outdoorNight =>
      'Le type d\'éclairage nocturne change la balance des blancs.',
    Environment.indoorBright =>
      'Le type de lampe affecte les couleurs de ta photo.',
    Environment.indoorDark =>
      'Chaque source de lumière a une température différente.',
    Environment.studio =>
      'Précise le type d\'éclairage pour la balance des blancs.',
  };

  /// Hint pour la section "Support"
  String getSupportHint(Subject subject) => switch (subject) {
    Subject.astro =>
      'L\'astrophoto nécessite un trépied pour les poses longues.',
    Subject.landscape =>
      'Un trépied permet des vitesses lentes et un ISO minimal.',
    _ =>
      'Le support affecte la vitesse minimum pour éviter le flou.',
  };

  /// Hint pour la section "Contraintes"
  String getConstraintHint() =>
    'Force des limites que le moteur respectera. Utile si tu connais '
    'les limites de ton matériel.';
}
```

---

## 4. Architecture widget

### 4.1. Arbre de widgets de l'écran Scene Input

```
SceneInputScreen (ConsumerWidget)
│
├── AppBar (← Retour)
│
├── SingleChildScrollView
│   │
│   ├── _Level1Section (toujours visible)
│   │   ├── SectionHeader("Décris ta scène")
│   │   ├── ShootTypeSelector
│   │   │   └── Row of 2 SmartChips (Photo / Vidéo)
│   │   ├── EnvironmentSelector
│   │   │   └── Wrap of 5 SmartChips
│   │   ├── SubjectSelector
│   │   │   └── Horizontal scrollable Wrap of 9 SmartChips
│   │   └── IntentionSelector
│   │       └── Wrap of 5 SmartChips
│   │
│   ├── _Level2Expandable (AnimatedCrossFade)
│   │   ├── ExpandToggle("Affiner davantage ▼")
│   │   └── AnimatedCrossFade(
│   │       collapsed: SizedBox.shrink(),
│   │       expanded: _Level2Content(
│   │         ├── LightConditionSelector (contextual ordering)
│   │         ├── MotionSelector (with suggestion styling)
│   │         ├── DistanceSelector (with suggestion styling)
│   │         ├── MoodSelector (contextual ordering)
│   │         ├── SupportSelector (with suggestion styling)
│   │         └── ConstraintSection
│   │             ├── IsoConstraintToggle + Slider
│   │             └── ShutterConstraintToggle + Slider
│   │       )
│   │   )
│   │
│   └── _Level3Expandable (AnimatedCrossFade)
│       ├── ExpandToggle("Paramètres avancés ▼")
│       └── AnimatedCrossFade(
│           expanded: _Level3Content(
│             ├── WbOverrideSection (radio + preset chips + slider)
│             ├── DofPreferenceSelector (chips + optional meters input)
│             ├── AfAreaOverrideSelector (chips, gear-filtered)
│             ├── BracketingSelector (chips, gear-filtered)
│             └── FileFormatOverrideSelector (chips)
│           )
│       )
│
└── StickyBottomBar
    └── CalculateButton (disabled si Niveau 1 incomplet)
```

### 4.2. Expand/Collapse — State local

```dart
// features/scene_input/presentation/screens/scene_input_screen.dart

class SceneInputScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // State local pour les expand/collapse — pas dans Riverpod
    final level2Expanded = useState(false);
    final level3Expanded = useState(false);

    final draft = ref.watch(sceneInputDraftProvider);
    final canCalc = ref.watch(canCalculateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Décris ta scène'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Niveau 1 (toujours visible)
                  const _ShootTypeSection(),
                  const SizedBox(height: 20),
                  const _EnvironmentSection(),
                  const SizedBox(height: 20),
                  const _SubjectSection(),
                  const SizedBox(height: 20),
                  const _IntentionSection(),
                  const SizedBox(height: 24),

                  // Toggle Niveau 2
                  _ExpandToggle(
                    label: 'Affiner davantage',
                    expanded: level2Expanded.value,
                    onTap: () => level2Expanded.value = !level2Expanded.value,
                    badge: _countLevel2Filled(draft),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: const _Level2Content(),
                    crossFadeState: level2Expanded.value
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),

                  // Toggle Niveau 3 (visible uniquement si Niveau 2 expanded)
                  if (level2Expanded.value) ...[
                    const SizedBox(height: 16),
                    _ExpandToggle(
                      label: 'Paramètres avancés',
                      expanded: level3Expanded.value,
                      onTap: () => level3Expanded.value = !level3Expanded.value,
                      badge: _countLevel3Filled(draft),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: const _Level3Content(),
                      crossFadeState: level3Expanded.value
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],

                  const SizedBox(height: 100), // Espace pour le sticky button
                ],
              ),
            ),
          ),

          // Sticky CTA en bas
          _StickyCalculateBar(
            enabled: canCalc,
            onTap: () {
              ref.read(sceneInputDraftProvider.notifier).submit();
              context.go('/results');
            },
          ),
        ],
      ),
    );
  }

  int _countLevel2Filled(SceneInputDraftState draft) {
    var count = 0;
    if (draft.lightCondition != null) count++;
    if (draft.subjectMotion != null) count++;
    if (draft.subjectDistance != null) count++;
    if (draft.mood != null) count++;
    if (draft.support != null) count++;
    if (draft.constraintIsoMax != null) count++;
    if (draft.constraintShutterMin != null) count++;
    return count;
  }

  int _countLevel3Filled(SceneInputDraftState draft) {
    var count = 0;
    if (draft.wbOverride != null) count++;
    if (draft.dofPreference != null) count++;
    if (draft.afAreaOverride != null) count++;
    if (draft.bracketing != null) count++;
    if (draft.fileFormatOverride != null) count++;
    return count;
  }
}
```

### 4.3. Le badge compteur

Les expand toggles affichent un badge avec le nombre de paramètres remplis dans la section. Ça donne un feedback visuel même quand la section est fermée.

```
▼ Affiner davantage (3)        ← 3 paramètres renseignés
▼ Paramètres avancés (1)       ← 1 paramètre renseigné
```

```dart
class _ExpandToggle extends StatelessWidget {
  final String label;
  final bool expanded;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(expanded ? Icons.expand_less : Icons.expand_more),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            if (badge > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$badge', style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 5. Sliders de contraintes

Les sliders ISO et vitesse sont les composants les plus complexes de l'écran.

### 5.1. ISO Constraint Slider

```dart
// features/scene_input/presentation/widgets/iso_constraint_slider.dart

class IsoConstraintSlider extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(sceneInputDraftProvider);
    final body = ref.watch(currentBodyProvider);
    final enabled = useState(draft.constraintIsoMax != null);

    // Valeurs ISO standard du boîtier
    final isoStops = body != null
        ? IsoValue.standardValues
            .where((v) => v >= body.spec.sensor.isoRange.min
                       && v <= body.spec.sensor.isoRange.max)
            .toList()
        : IsoValue.standardValues;

    final currentIndex = useState(
      draft.constraintIsoMax != null
          ? isoStops.indexOf(isoStops.reduce((a, b) =>
              (a - draft.constraintIsoMax!).abs() < (b - draft.constraintIsoMax!).abs() ? a : b))
          : isoStops.length - 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: enabled.value,
              onChanged: (v) {
                enabled.value = v!;
                if (!v) {
                  ref.read(sceneInputDraftProvider.notifier).setIsoConstraint(null);
                } else {
                  ref.read(sceneInputDraftProvider.notifier)
                      .setIsoConstraint(isoStops[currentIndex.value]);
                }
              },
            ),
            Text('ISO max', style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            if (enabled.value)
              Text(
                'ISO ${isoStops[currentIndex.value]}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        if (enabled.value)
          Slider(
            value: currentIndex.value.toDouble(),
            min: 0,
            max: (isoStops.length - 1).toDouble(),
            divisions: isoStops.length - 1,
            label: 'ISO ${isoStops[currentIndex.value]}',
            onChanged: (v) {
              currentIndex.value = v.round();
              ref.read(sceneInputDraftProvider.notifier)
                  .setIsoConstraint(isoStops[v.round()]);
            },
          ),
        if (enabled.value && body != null)
          _NoiseIndicator(
            currentIso: isoStops[currentIndex.value],
            usableMax: body.spec.sensor.isoUsableMax,
          ),
      ],
    );
  }
}

/// Barre colorée qui montre la zone de bruit
class _NoiseIndicator extends StatelessWidget {
  final int currentIso;
  final int usableMax;

  @override
  Widget build(BuildContext context) {
    final ratio = currentIso / usableMax;
    final color = ratio <= 0.5
        ? Colors.green
        : ratio <= 1.0
            ? Colors.orange
            : Colors.red;
    final label = ratio <= 0.5
        ? 'Bruit quasi invisible'
        : ratio <= 1.0
            ? 'Bruit acceptable'
            : 'Bruit visible';

    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
```

Le slider utilise des **crans discrets** (valeurs ISO standard), pas un slider continu. L'indicateur de bruit coloré en dessous donne un feedback immédiat : vert = tranquille, orange = acceptable, rouge = bruit visible.

---

## 6. Persistance du draft entre navigations

### 6.1. Comportement

```
Scene Input → Calculer → Résultats → "Modifier la scène"
→ Retour à Scene Input avec TOUTES les valeurs conservées

Scene Input → Back (sans calculer) → Home → Nouveau shoot
→ Scene Input avec les valeurs RÉINITIALISÉES
```

Le draft est dans un Riverpod Notifier (skill 11). Il survit à la navigation vers Résultats (le provider reste en vie via `keepAlive`). Il est reset quand l'utilisateur tape "Nouveau shoot" depuis le Home.

```dart
// features/scene_input/presentation/providers/scene_input_providers.dart

@Riverpod(keepAlive: true) // ← survit à la navigation
class SceneInputDraft extends _$SceneInputDraft {
  // ...
}
```

### 6.2. Retour depuis Résultats avec modifications

Quand l'utilisateur revient de l'écran Résultats via "Modifier la scène", le draft est intact. Il peut modifier un paramètre et recalculer.

Le flux est géré par le router — pas de logique spéciale dans le widget :

```dart
// Dans ResultsScreen :
TextButton(
  onPressed: () => context.go('/scene-input'),  // Le draft est toujours là
  child: const Text('← Modifier la scène'),
)
```

---

## 7. Validation

### 7.1. Validation Niveau 1

La validation est continue et temps réel — pas de validation "on submit".

```dart
// Le bouton Calculer reflète l'état de complétion en temps réel
@riverpod
bool canCalculate(Ref ref) {
  final draft = ref.watch(sceneInputDraftProvider);
  return draft.isLevel1Complete;
}

// Le bouton est visuellement disabled tant que les 4 champs ne sont pas remplis
_StickyCalculateBar(
  enabled: canCalc,
  // ...
)
```

Pas de message d'erreur "Remplis tous les champs" — le bouton disabled est suffisant. L'écran est assez simple pour que l'utilisateur voie ce qu'il manque.

### 7.2. Validation des contraintes

Les sliders sont bornés par les specs du boîtier — impossible de sélectionner une valeur hors range. Si l'utilisateur met une contrainte ISO max très basse + une contrainte vitesse très haute, le moteur le détectera au calcul et affichera un compromis (skill 15, C5).

### 7.3. Validation cross-field

Certaines combinaisons de Niveau 1 méritent un hint visuel immédiat dans l'UI :

```dart
// features/scene_input/domain/use_cases/get_scene_warnings.dart

class GetSceneWarnings {
  /// Retourne des warnings contextuels basés sur la sélection actuelle
  List<SceneWarning> getWarnings(SceneInputDraftState draft, Body? body, Lens? lens) {
    final warnings = <SceneWarning>[];

    // Astro + main levée
    if (draft.subject == Subject.astro && draft.support == Support.handheld) {
      warnings.add(const SceneWarning(
        message: 'L\'astrophoto nécessite un trépied pour les poses longues.',
        severity: WarningSeverity.high,
      ));
    }

    // Macro + objectif non-macro
    if (draft.subject == Subject.macro && lens != null) {
      if (lens.spec.focus.minFocusDistanceM > 0.3) {
        warnings.add(SceneWarning(
          message: 'Ton ${lens.displayName} a une distance min de MAP de '
              '${lens.spec.focus.minFocusDistanceM}m. Un objectif macro '
              'serait idéal pour cette utilisation.',
          severity: WarningSeverity.medium,
        ));
      }
    }

    // Sport/wildlife + focale courte
    if ((draft.subject == Subject.sport || draft.subject == Subject.wildlife) && lens != null) {
      final maxFocal = lens.spec.focalLength.maxMm;
      if (maxFocal < 100) {
        warnings.add(SceneWarning(
          message: 'Ton ${lens.displayName} (max ${maxFocal}mm) est assez court '
              'pour le ${draft.subject == Subject.sport ? "sport" : "animalier"}. '
              'Un téléobjectif (200mm+) est recommandé.',
          severity: WarningSeverity.low,
        ));
      }
    }

    return warnings;
  }
}

@freezed
class SceneWarning with _$SceneWarning {
  const factory SceneWarning({
    required String message,
    required WarningSeverity severity,
  }) = _SceneWarning;
}

enum WarningSeverity { low, medium, high }
```

Les warnings sont affichés comme des bandeaux discrets sous les sections concernées — informatifs, pas bloquants :

```dart
if (warnings.isNotEmpty)
  ...warnings.map((w) => _WarningBanner(
    message: w.message,
    severity: w.severity,
  )),
```

---

## 8. Scénarios de test

### 8.1. Tests UX (widget tests)

| # | Scénario | Vérification |
|---|----------|-------------|
| T1 | Tap Photo + Ext Jour + Portrait + Bokeh | Bouton "Calculer" activé |
| T2 | Seulement 3 paramètres remplis | Bouton "Calculer" disabled |
| T3 | Expand Niveau 2 | 6 sections de paramètres visibles |
| T4 | Expand Niveau 2 puis collapse | Sections masquées, badge compteur visible |
| T5 | Sélection Astro → expand Niveau 2 | Support pré-sélectionné "Trépied" (style suggestion) |
| T6 | Modifier le support suggéré | Style passe de "suggestion" à "confirmé" |
| T7 | Activer contrainte ISO → slider visible | Slider affiché, borné par specs du boîtier |
| T8 | Eye-AF chip quand boîtier sans Eye-AF | Chip grisé avec tooltip |
| T9 | Calculer → Résultats → "Modifier" → retour | Tous les champs conservés |
| T10 | Home → "Nouveau shoot" | Draft réinitialisé (aucune sélection) |
| T11 | Portrait sélectionné | Chips Niveau 2 réordonnés (Natural en premier pour Mood) |
| T12 | Astro + Main levée | Warning affiché "Trépied nécessaire" |
| T13 | Macro + objectif non-macro | Warning affiché distance MAP |

### 8.2. Tests du suggest_defaults

```dart
void main() {
  group('SuggestSceneDefaults', () {
    final suggest = SuggestSceneDefaults();

    test('astro → suggest tripod', () {
      final draft = SceneInputDraftState(
        shootType: ShootType.photo,
        environment: Environment.outdoorNight,
        subject: Subject.astro,
        intention: Intention.maxSharpness,
      );
      final result = suggest.suggest(draft);
      expect(result.support, Support.tripod);
      expect(result.subjectMotion, SubjectMotion.still);
      expect(result.subjectDistance, SubjectDistance.infinity);
    });

    test('sport → suggest fast motion', () {
      final draft = SceneInputDraftState(
        shootType: ShootType.photo,
        environment: Environment.outdoorDay,
        subject: Subject.sport,
        intention: Intention.freezeMotion,
      );
      final result = suggest.suggest(draft);
      expect(result.subjectMotion, SubjectMotion.fast);
      expect(result.subjectDistance, SubjectDistance.far);
      expect(result.support, Support.handheld);
    });

    test('ne pas overrider une valeur déjà set par l\'utilisateur', () {
      final draft = SceneInputDraftState(
        shootType: ShootType.photo,
        environment: Environment.outdoorDay,
        subject: Subject.sport,
        intention: Intention.freezeMotion,
        support: Support.monopod, // Explicitement choisi par l'utilisateur
      );
      final result = suggest.suggest(draft);
      expect(result.support, Support.monopod); // Pas overridé
    });
  });
}
```

---

## 9. Résumé — Flow utilisateur complet

```
L'utilisateur arrive sur Scene Input.
L'écran affiche 4 groupes de chips (Niveau 1).

Tap : 📷 Photo
Tap : ☀️ Ext Jour
Tap : 👤 Portrait
Tap : 🌀 Flou arrière-plan

→ Le bouton "Calculer mes réglages" s'active.
→ 4 taps. Le débutant peut s'arrêter là.

Optionnel : l'utilisateur tape "Affiner davantage ▼"
→ Niveau 2 s'expand avec animation douce.
→ Mouvement du sujet pré-sélectionné "Immobile" (style suggestion).
→ Distance pré-sélectionné "1-3m" (style suggestion).
→ Support pré-sélectionné "Main levée" (style suggestion).

L'utilisateur tape "Golden hour" dans Conditions de lumière.
L'utilisateur laisse les suggestions des autres champs.

Le badge affiche "(4)" sur le toggle Niveau 2.

Tap : "Calculer mes réglages →"

→ Le draft est converti en SceneInput validé.
→ Le SceneInput est soumis au provider partagé.
→ Navigation vers /results.
→ Le moteur calcule en < 1ms.
→ L'écran Résultats s'affiche avec les réglages optimisés
   pour un portrait en extérieur golden hour avec flou d'arrière-plan.
```

---

*Ce document est la référence pour l'implémentation de tout l'écran Scene Input. Combiné avec le skill 06 (Settings Engine) qui consomme le SceneInput, et le skill 11 (State Management) qui gère le draft, il couvre le cycle complet de la description de scène.*
