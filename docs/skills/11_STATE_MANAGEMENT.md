# State Management — ShootHelper

> **Skill 11/22** · Riverpod patterns, circulation du state, local vs global
> Version 1.0 · Mars 2026
> Réf : 08_TECH_STACK_DECISION.md, 09_APP_ARCHITECTURE.md, 10_MODULE_FEATURE_ARCHITECTURE.md

---

## 1. Décision : Riverpod 2.x (code-gen)

Déjà tranché dans le skill 08, mais voici le résumé du pourquoi :

| Critère | Riverpod | Provider | BLoC | Alternatives (GetX, MobX) |
|---------|----------|----------|------|---------------------------|
| Testabilité | ★★★★★ Override de tout | ★★★☆☆ | ★★★★☆ | ★★☆☆☆ |
| Injection de dépendances | Natif (ref.watch/read) | Externe nécessaire | Externe nécessaire | Partielle |
| Compile-time safety | ✅ Avec code-gen | ❌ | ✅ | ❌ |
| Complexité | Moyenne | Faible | Haute | Faible mais fragile |
| Adapté au projet | ★★★★★ | ★★★☆☆ Trop limité | ★★★☆☆ Overkill | ★★☆☆☆ |

**Riverpod avec code generation** (`riverpod_annotation` + `riverpod_generator`). La code-gen élimine le boilerplate et force des patterns cohérents. Chaque provider est une fonction ou classe annotée `@riverpod`.

---

## 2. Cartographie complète du state

Avant de parler patterns, il faut lister **tout** le state de l'app et classifier chaque morceau.

### 2.1. Inventaire exhaustif

```
┌─────────────────────────────────────────────────────────────────┐
│                    TOUT LE STATE DE SHOOTHELPER                  │
│                                                                 │
│  PERSISTENT (survit au kill de l'app)                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ • GearProfile (boîtier, objectifs, langue firmware)       │ │
│  │ • Data packs téléchargés (fichiers JSON sur le filesystem)│ │
│  │ • Onboarding complété (bool)                              │ │
│  │ • Langue de l'app (si override manuel, V2)                │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  SESSION (survit à la navigation, pas au kill)                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ • Body chargé en mémoire (parsé depuis JSON)              │ │
│  │ • Lens actif chargé en mémoire                            │ │
│  │ • SceneInput en cours de construction                     │ │
│  │ • SettingsResult calculé                                  │ │
│  │ • Objectif actif sélectionné (si multi-objectifs)         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ÉPHÉMÈRE (local à un écran, disparaît à la navigation)        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ • Recherche en cours (champ texte body/lens search)       │ │
│  │ • Expansion/collapse des sections Niveau 2/3              │ │
│  │ • Expansion d'une explication détaillée                   │ │
│  │ • Progression du download (pourcentage)                   │ │
│  │ • Scroll position                                         │ │
│  │ • Formulaire de contrainte ISO/vitesse (slider value)     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2. Classification et solution par type

| Type | Durée de vie | Stockage | Mécanisme Riverpod |
|------|-------------|----------|-------------------|
| **Persistent** | Survit au kill | SharedPreferences + fichiers locaux | Provider qui lit/écrit via un repository |
| **Session** | Durée de la session app | Mémoire (Riverpod) | StateProvider, NotifierProvider, FutureProvider |
| **Éphémère** | Durée d'un écran | State local du widget | `useState` (hooks) ou `StatefulWidget`, PAS dans Riverpod |

**Règle d'or : le state éphémère ne va PAS dans Riverpod.** Un champ de recherche, un toggle d'expansion, un scroll position — c'est du state local au widget. Le mettre dans Riverpod pollue le graphe de providers et crée des rebuilds inutiles.

---

## 3. Providers globaux (shared)

Ces providers vivent dans `shared/presentation/providers/` et servent de contrat entre features (skill 10).

### 3.1. Infrastructure — Repositories

```dart
// shared/presentation/providers/repository_providers.dart

/// Data sources
@riverpod
JsonDataSource jsonDataSource(Ref ref) {
  return JsonDataSource(fileManager: ref.watch(fileManagerProvider));
}

@riverpod
PreferencesSource preferencesSource(Ref ref) {
  return PreferencesSource();
}

@riverpod
FileManager fileManager(Ref ref) {
  return FileManager();
}

@riverpod
DataPackApi dataPackApi(Ref ref) {
  return DataPackApi(dio: Dio());
}

/// Repositories (typés sur les interfaces Domain)
@riverpod
GearRepository gearRepository(Ref ref) {
  return GearRepositoryImpl(
    jsonDataSource: ref.watch(jsonDataSourceProvider),
    preferencesSource: ref.watch(preferencesSourceProvider),
  );
}

@riverpod
DataPackRepository dataPackRepository(Ref ref) {
  return DataPackRepositoryImpl(
    api: ref.watch(dataPackApiProvider),
    fileManager: ref.watch(fileManagerProvider),
  );
}
```

**Pourquoi `@riverpod` (code-gen) plutôt que `Provider` manuel ?** Le code-gen génère les providers avec le bon type, le bon dispose, et force la cohérence. Moins de boilerplate, moins d'erreurs.

### 3.2. Gear — Le profil matériel

```dart
// shared/presentation/providers/gear_providers.dart

/// Profil gear persisté (boîtier, objectifs, langue firmware)
/// Source de vérité : SharedPreferences
@riverpod
class CurrentGear extends _$CurrentGear {
  @override
  Future<GearProfile?> build() async {
    final repo = ref.watch(gearRepositoryProvider);
    return repo.loadGearProfile();
  }

  /// Met à jour le profil et persiste
  Future<void> updateProfile(GearProfile profile) async {
    final repo = ref.read(gearRepositoryProvider);
    await repo.saveGearProfile(profile);
    state = AsyncData(profile);
  }

  /// Change l'objectif actif (pas de persistence — session only)
  Future<void> switchActiveLens(String lensId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(activeLensId: lensId);
    await updateProfile(updated);
  }
}

/// Body chargé en mémoire (dérivé du gear profile)
/// Se recalcule automatiquement quand le gear change
@riverpod
Future<Body?> currentBody(Ref ref) async {
  final gear = await ref.watch(currentGearProvider.future);
  if (gear == null) return null;
  final repo = ref.watch(gearRepositoryProvider);
  return repo.getBody(gear.bodyId);
}

/// Lens actif chargé en mémoire
@riverpod
Future<Lens?> currentLens(Ref ref) async {
  final gear = await ref.watch(currentGearProvider.future);
  if (gear == null) return null;
  final repo = ref.watch(gearRepositoryProvider);
  return repo.getLens(gear.activeLensId);
}

/// Langue firmware (raccourci)
@riverpod
Future<String> firmwareLanguage(Ref ref) async {
  final gear = await ref.watch(currentGearProvider.future);
  return gear?.firmwareLanguage ?? 'en';
}
```

### 3.3. Scène — Le pont scene_input → settings_engine

```dart
// shared/presentation/providers/scene_providers.dart

/// La scène soumise (prête pour le calcul)
/// Écrite par scene_input, lue par settings_engine
@riverpod
class SubmittedScene extends _$SubmittedScene {
  @override
  SceneInput? build() => null;

  void submit(SceneInput scene) {
    state = scene;
  }

  void clear() {
    state = null;
  }
}
```

### 3.4. Résultats — Le pont settings_engine → results → menu_nav

```dart
// shared/presentation/providers/results_providers.dart

/// Le résultat de calcul, recalculé automatiquement
/// quand la scène ou le gear change
@riverpod
Future<SettingsResult?> settingsResult(Ref ref) async {
  final scene = ref.watch(submittedSceneProvider);
  if (scene == null) return null;

  final body = await ref.watch(currentBodyProvider.future);
  final lens = await ref.watch(currentLensProvider.future);
  if (body == null || lens == null) return null;

  final gear = (await ref.watch(currentGearProvider.future))!;
  final engine = ref.watch(calculateSettingsProvider);
  return engine.execute(gear, scene);
}
```

---

## 4. Providers par feature

### 4.1. Feature: scene_input

```dart
// features/scene_input/presentation/providers/scene_input_providers.dart

/// State local de la scène EN COURS DE CONSTRUCTION (pas encore soumise)
/// C'est le "brouillon" — l'utilisateur peut modifier les paramètres
/// avant de cliquer "Calculer"
@riverpod
class SceneInputDraft extends _$SceneInputDraft {
  @override
  SceneInputDraftState build() => const SceneInputDraftState();

  // ─── Niveau 1 (obligatoire) ───
  void setShootType(ShootType type) =>
      state = state.copyWith(shootType: type);

  void setEnvironment(Environment env) =>
      state = state.copyWith(environment: env);

  void setSubject(Subject subject) =>
      state = state.copyWith(subject: subject);

  void setIntention(Intention intention) =>
      state = state.copyWith(intention: intention);

  // ─── Niveau 2 (optionnel) ───
  void setLightCondition(LightCondition? v) =>
      state = state.copyWith(lightCondition: v);

  void setSubjectMotion(SubjectMotion? v) =>
      state = state.copyWith(subjectMotion: v);

  void setSubjectDistance(SubjectDistance? v) =>
      state = state.copyWith(subjectDistance: v);

  void setMood(Mood? v) =>
      state = state.copyWith(mood: v);

  void setSupport(Support? v) =>
      state = state.copyWith(support: v);

  void setIsoConstraint(int? max) =>
      state = state.copyWith(constraintIsoMax: max);

  void setShutterConstraint(String? min) =>
      state = state.copyWith(constraintShutterMin: min);

  // ─── Niveau 3 (override) ───
  void setWbOverride(WbOverride? v) =>
      state = state.copyWith(wbOverride: v);

  void setDofPreference(DofPreference? v) =>
      state = state.copyWith(dofPreference: v);

  void setAfAreaOverride(AfAreaOverride? v) =>
      state = state.copyWith(afAreaOverride: v);

  // ─── Actions ───

  /// Valide le brouillon et soumet la scène pour calcul
  void submit() {
    if (!state.isLevel1Complete) return; // Garde : 4 champs obligatoires

    final sceneInput = state.toSceneInput();
    ref.read(submittedSceneProvider.notifier).submit(sceneInput);
  }

  void reset() => state = const SceneInputDraftState();
}

/// Vérifie si le bouton "Calculer" est activable
@riverpod
bool canCalculate(Ref ref) {
  final draft = ref.watch(sceneInputDraftProvider);
  return draft.isLevel1Complete;
}
```

```dart
// features/scene_input/domain/entities/scene_input_draft_state.dart
@freezed
class SceneInputDraftState with _$SceneInputDraftState {
  const SceneInputDraftState._();

  const factory SceneInputDraftState({
    ShootType? shootType,
    Environment? environment,
    Subject? subject,
    Intention? intention,
    LightCondition? lightCondition,
    SubjectMotion? subjectMotion,
    SubjectDistance? subjectDistance,
    Mood? mood,
    Support? support,
    int? constraintIsoMax,
    String? constraintShutterMin,
    WbOverride? wbOverride,
    DofPreference? dofPreference,
    AfAreaOverride? afAreaOverride,
  }) = _SceneInputDraftState;

  /// Les 4 champs Niveau 1 sont remplis
  bool get isLevel1Complete =>
      shootType != null &&
      environment != null &&
      subject != null &&
      intention != null;

  /// Convertit le brouillon en entité SceneInput validée
  SceneInput toSceneInput() {
    assert(isLevel1Complete);
    return SceneInput(
      shootType: shootType!,
      environment: environment!,
      subject: subject!,
      intention: intention!,
      lightCondition: lightCondition,
      subjectMotion: subjectMotion,
      subjectDistance: subjectDistance,
      mood: mood,
      support: support,
      constraintIsoMax: constraintIsoMax,
      constraintShutterMin: constraintShutterMin,
      wbOverride: wbOverride,
      dofPreference: dofPreference,
      afAreaOverride: afAreaOverride,
    );
  }
}
```

**Pourquoi un SceneInputDraftState séparé de SceneInput ?**

- `SceneInputDraftState` a des champs nullable partout (l'utilisateur n'a pas encore tout rempli)
- `SceneInput` a des champs required pour le Niveau 1 (le moteur exige ces données)
- La méthode `toSceneInput()` fait la conversion validée du brouillon vers l'entité finale
- Ça empêche le moteur de recevoir un input incomplet

### 4.2. Feature: settings_engine

```dart
// features/settings_engine/presentation/providers/engine_providers.dart

/// Le use case CalculateSettings
@riverpod
CalculateSettings calculateSettings(Ref ref) {
  return CalculateSettings(
    gearRepo: ref.watch(gearRepositoryProvider),
  );
}

// Le provider settingsResultProvider est dans shared/ (§3.4)
// car il est consommé par results et menu_nav
```

Le settings_engine est la feature avec le **moins de providers** — un seul pour le use case. Le résultat est exposé via le provider partagé `settingsResultProvider`.

### 4.3. Feature: results

```dart
// features/results/presentation/providers/results_feature_providers.dart

/// Index du réglage sélectionné pour le détail
@riverpod
class SelectedSettingIndex extends _$SelectedSettingIndex {
  @override
  int? build() => null;

  void select(int index) => state = index;
  void clear() => state = null;
}

/// Le réglage sélectionné (dérivé du résultat + index)
@riverpod
SettingRecommendation? selectedSetting(Ref ref) {
  final result = ref.watch(settingsResultProvider).valueOrNull;
  final index = ref.watch(selectedSettingIndexProvider);
  if (result == null || index == null) return null;
  if (index >= result.settings.length) return null;
  return result.settings[index];
}
```

### 4.4. Feature: menu_nav

```dart
// features/menu_nav/presentation/providers/menu_nav_providers.dart

/// Paramètres de la résolution de chemin menu
@freezed
class MenuNavParams with _$MenuNavParams {
  const factory MenuNavParams({
    required String bodyId,
    required String settingId,
    required dynamic value,
    required String firmwareLanguage,
  }) = _MenuNavParams;
}

/// Résolution du chemin menu pour un réglage
/// Family provider : une instance par combinaison de paramètres
@riverpod
Future<MenuNavDisplay> menuNavDisplay(Ref ref, MenuNavParams params) async {
  final resolveMenuPath = ref.watch(resolveMenuPathProvider);
  return resolveMenuPath.execute(
    bodyId: params.bodyId,
    settingId: params.settingId,
    value: params.value,
    firmwareLanguage: params.firmwareLanguage,
  );
}

@riverpod
ResolveMenuPath resolveMenuPath(Ref ref) {
  return ResolveMenuPath(gearRepo: ref.watch(gearRepositoryProvider));
}
```

### 4.5. Feature: onboarding

```dart
// features/onboarding/presentation/providers/onboarding_providers.dart

/// Étape courante de l'onboarding
@riverpod
class OnboardingStep extends _$OnboardingStep {
  @override
  int build() => 0; // 0 = welcome, 1 = body, 2 = lens, 3 = language, 4 = recap

  void next() => state = state + 1;
  void back() => state = (state - 1).clamp(0, 4);
  void goTo(int step) => state = step;
}

/// Boîtier sélectionné pendant l'onboarding (pas encore persisté)
@riverpod
class SelectedBody extends _$SelectedBody {
  @override
  Body? build() => null;
  void select(Body body) => state = body;
}

/// Objectifs sélectionnés pendant l'onboarding
@riverpod
class SelectedLenses extends _$SelectedLenses {
  @override
  List<Lens> build() => [];

  void toggle(Lens lens) {
    if (state.any((l) => l.id == lens.id)) {
      state = state.where((l) => l.id != lens.id).toList();
    } else {
      state = [...state, lens];
    }
  }
}

/// Langue firmware sélectionnée pendant l'onboarding
@riverpod
class SelectedFirmwareLanguage extends _$SelectedFirmwareLanguage {
  @override
  String? build() => null;
  void select(String lang) => state = lang;
}

/// Liste des boîtiers supportés (chargée depuis les data packs)
@riverpod
Future<List<Body>> supportedBodies(Ref ref) async {
  final useCase = GetSupportedBodies(
    dataPackRepo: ref.watch(dataPackRepositoryProvider),
  );
  return useCase.execute();
}

/// Objectifs compatibles avec le boîtier sélectionné
@riverpod
Future<List<Lens>> compatibleLenses(Ref ref) async {
  final body = ref.watch(selectedBodyProvider);
  if (body == null) return [];
  final useCase = GetCompatibleLenses(
    gearRepo: ref.watch(gearRepositoryProvider),
  );
  return useCase.execute(body.id);
}

/// Finalisation de l'onboarding : persiste le profil et déclenche le download
@riverpod
class OnboardingCompletion extends _$OnboardingCompletion {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> complete() async {
    state = const AsyncLoading();
    try {
      final body = ref.read(selectedBodyProvider)!;
      final lenses = ref.read(selectedLensesProvider);
      final lang = ref.read(selectedFirmwareLanguageProvider)!;

      // 1. Télécharger le data pack
      final downloadUseCase = ref.read(downloadDataPackProvider);
      await downloadUseCase.execute(bodyId: body.id, lensIds: lenses.map((l) => l.id).toList());

      // 2. Sauvegarder le profil gear
      final profile = GearProfile(
        bodyId: body.id,
        lensIds: lenses.map((l) => l.id).toList(),
        activeLensId: lenses.first.id,
        firmwareLanguage: lang,
      );
      await ref.read(currentGearProvider.notifier).updateProfile(profile);

      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}
```

### 4.6. Feature: data_pack

```dart
// features/data_pack/presentation/providers/data_pack_providers.dart

/// Progression du téléchargement
@riverpod
class DownloadProgress extends _$DownloadProgress {
  @override
  DownloadState build() => const DownloadState.idle();

  void start(String bodyId, List<String> lensIds) async {
    state = const DownloadState.downloading(progress: 0, currentItem: '');
    try {
      final repo = ref.read(dataPackRepositoryProvider);
      await repo.downloadDataPack(
        bodyId: bodyId,
        lensIds: lensIds,
        onProgress: (progress, currentItem) {
          state = DownloadState.downloading(
            progress: progress,
            currentItem: currentItem,
          );
        },
      );
      state = const DownloadState.completed();
    } catch (e) {
      state = DownloadState.error(message: e.toString());
    }
  }
}

@freezed
class DownloadState with _$DownloadState {
  const factory DownloadState.idle() = _Idle;
  const factory DownloadState.downloading({
    required double progress,
    required String currentItem,
  }) = _Downloading;
  const factory DownloadState.completed() = _Completed;
  const factory DownloadState.error({required String message}) = _Error;
}

@riverpod
DownloadDataPack downloadDataPack(Ref ref) {
  return DownloadDataPack(
    dataPackRepo: ref.watch(dataPackRepositoryProvider),
    fileManager: ref.watch(fileManagerProvider),
  );
}
```

---

## 5. Graphe réactif complet

Voici comment tout le state est connecté. Les flèches montrent les dépendances `ref.watch` — quand un provider change, tout ce qui en dépend est recalculé.

```
SharedPreferences (disk)
  │
  ▼
currentGearProvider ◄──── onboardingCompletionProvider (écrit)
  │                 ◄──── gear feature (écrit)
  │
  ├──► currentBodyProvider ──────┐
  │                              │
  ├──► currentLensProvider ──────┤
  │                              │
  └──► firmwareLanguageProvider  │
                                 │
                                 ▼
submittedSceneProvider ──► settingsResultProvider
  ▲                              │
  │                              ├──► resultsScreen (watch)
sceneInputDraftProvider          │
  ▲                              ├──► selectedSettingProvider
  │                              │       │
scene_input UI (write)           │       ▼
                                 │    settingDetailScreen
                                 │
                                 └──► menuNavDisplayProvider
                                         │
                                         ▼
                                      menuNavigationScreen
```

**Propriété clé** : quand l'utilisateur change d'objectif (`switchActiveLens`), le changement cascade automatiquement :
1. `currentGearProvider` émet un nouveau `GearProfile`
2. `currentLensProvider` émet le nouveau `Lens`
3. `settingsResultProvider` se recalcule si une scène est soumise
4. `resultsScreen` se rebuild avec les nouveaux réglages
5. `menuNavDisplayProvider` se recalcule si un réglage est sélectionné

Tout ça sans un seul callback, sans un seul event bus. C'est la magie de Riverpod : le graphe réactif propage les changements automatiquement.

---

## 6. State local (éphémère)

Le state éphémère **ne va PAS dans Riverpod**. Il vit dans le widget.

### 6.1. Avec flutter_hooks (recommandé)

```dart
// features/scene_input/presentation/widgets/environment_selector.dart
class EnvironmentSelector extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // State local : animation du hint
    final animController = useAnimationController(duration: const Duration(milliseconds: 300));

    // State global : la sélection va dans Riverpod
    final draft = ref.watch(sceneInputDraftProvider);
    final notifier = ref.read(sceneInputDraftProvider.notifier);

    return Wrap(
      spacing: 8,
      children: Environment.values.map((env) {
        return ShootChip(
          label: env.label(context),  // i18n Couche 1
          selected: draft.environment == env,
          onTap: () => notifier.setEnvironment(env),
        );
      }).toList(),
    );
  }
}
```

### 6.2. Avec StatefulWidget (sans hooks)

```dart
// features/results/presentation/widgets/explanation_section.dart
class ExplanationSection extends ConsumerStatefulWidget {
  final SettingRecommendation setting;
  const ExplanationSection({required this.setting});

  @override
  ConsumerState<ExplanationSection> createState() => _ExplanationSectionState();
}

class _ExplanationSectionState extends ConsumerState<ExplanationSection> {
  // State local : expansion toggle
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.setting.explanationShort),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(_isExpanded ? 'Réduire' : 'Comprendre en détail'),
        ),
        if (_isExpanded) Text(widget.setting.explanationDetail),
      ],
    );
  }
}
```

### 6.3. Règle de décision : Riverpod ou local ?

```
╔══════════════════════════════════════════════════════════════════╗
║  QUESTION : Est-ce que ce state doit survivre à la navigation ? ║
║                                                                  ║
║  OUI → Riverpod (provider dans shared/ ou features/)             ║
║  NON → State local (StatefulWidget ou Hook)                      ║
║                                                                  ║
║  QUESTION : Est-ce que ce state est lu par un autre widget       ║
║             qui n'est PAS un descendant direct ?                 ║
║                                                                  ║
║  OUI → Riverpod                                                  ║
║  NON → State local                                               ║
╚══════════════════════════════════════════════════════════════════╝
```

Exemples :

| State | Survit à la nav ? | Lu par un non-descendant ? | → |
|-------|--------------------|---------------------------|---|
| Sujet sélectionné (portrait) | Oui (utilisé par le moteur) | Oui | Riverpod |
| Expansion d'un détail | Non | Non | Local |
| Champ de recherche boîtier | Non | Non | Local |
| Progression du download | Oui (affiché sur plusieurs écrans) | Oui | Riverpod |
| Slide value du constraint ISO | Non (tant que pas validé) | Non | Local |
| SceneInput soumise | Oui | Oui (moteur + résultats) | Riverpod |

---

## 7. Patterns Riverpod utilisés

### 7.1. Catalogue des types de providers

| Type | Usage dans ShootHelper | Exemple |
|------|----------------------|---------|
| `@riverpod` (fonction) | Donnée dérivée en lecture seule, recalculée quand les deps changent | `currentBodyProvider`, `settingsResultProvider` |
| `@riverpod` class (Notifier) | State mutable avec actions | `CurrentGear`, `SceneInputDraft`, `DownloadProgress` |
| `FutureProvider` (via `@riverpod` async function) | Donnée async (lecture fichier, calcul) | `supportedBodiesProvider`, `menuNavDisplayProvider` |
| Family provider (via paramètre) | Instance par paramètre | `menuNavDisplayProvider(MenuNavParams)` |

### 7.2. ref.watch vs ref.read vs ref.listen

```dart
// ref.watch — pour les DÉPENDANCES RÉACTIVES
// Le provider se recalcule quand la dépendance change
@riverpod
Future<Body?> currentBody(Ref ref) async {
  final gear = await ref.watch(currentGearProvider.future); // ← watch
  // ...
}

// ref.read — pour les ACTIONS PONCTUELLES (dans les callbacks)
void onTapCalculate() {
  ref.read(sceneInputDraftProvider.notifier).submit(); // ← read
}

// ref.listen — pour les SIDE EFFECTS (navigation, snackbar, analytics)
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(settingsResultProvider, (prev, next) {
    if (next.hasValue && next.value != null && prev?.value == null) {
      context.go('/results'); // ← Navigation automatique quand le résultat arrive
    }
  });
  // ...
}
```

**Règle** :
- `ref.watch` dans `build()` et dans les providers → réactivité
- `ref.read` dans les callbacks (`onTap`, `onPressed`) → action ponctuelle
- `ref.listen` dans `build()` → side effects (navigation, toast)

### 7.3. AsyncValue — Gestion des états loading/error/data

Riverpod wrappe automatiquement les FutureProviders dans `AsyncValue<T>`. On l'exploite systématiquement :

```dart
// Pattern standard pour afficher un async provider
class ResultsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(settingsResultProvider);

    return resultAsync.when(
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: ErrorDisplay(error: error, onRetry: () => ref.invalidate(settingsResultProvider)),
      ),
      data: (result) {
        if (result == null) return const _EmptyState();
        return _ResultsContent(result: result);
      },
    );
  }
}
```

**Jamais de `FutureBuilder` ou `StreamBuilder`** dans l'app. Riverpod les remplace via `AsyncValue.when()`, qui est plus sûr (pas de rebuild infini, pas de perte de state).

---

## 8. Invalidation et refresh

### 8.1. Quand invalider un provider ?

| Situation | Action | Méthode |
|-----------|--------|---------|
| L'utilisateur change de boîtier | Tout le gear chain se recalcule | Automatique via `ref.watch` |
| L'utilisateur change d'objectif actif | `currentLens` + résultats se recalculent | `currentGear.switchActiveLens()` → cascade auto |
| L'utilisateur modifie la scène et recalcule | Nouveaux résultats | `submittedScene.submit()` → cascade auto |
| L'utilisateur force un refresh (pull-to-refresh) | Recalcul forcé | `ref.invalidate(settingsResultProvider)` |
| Le data pack est mis à jour | Les données body/lens changent | `ref.invalidate(currentBodyProvider)` |
| L'utilisateur revient à l'écran scene_input | Le draft doit persister (pas de clear) | Rien à faire — le provider garde son state |

### 8.2. Dispose automatique

Riverpod avec code-gen dispose automatiquement les providers quand plus aucun widget ne les écoute. Pour les providers qui doivent rester en vie (le gear profile), on utilise `keepAlive: true` :

```dart
@Riverpod(keepAlive: true)
class CurrentGear extends _$CurrentGear {
  // Ce provider vit tant que l'app tourne
  // même si aucun widget ne le watch actuellement
}
```

Providers avec `keepAlive: true` dans ShootHelper :
- `currentGearProvider` (le profil gear doit rester en mémoire)
- `submittedSceneProvider` (la scène doit survivre à la navigation results ↔ detail)
- `settingsResultProvider` (les résultats doivent survivre à la navigation)

Tous les autres providers sont auto-disposed quand leur écran disparaît.

---

## 9. Testing du state

### 9.1. Override de providers en test

```dart
void main() {
  group('ResultsScreen', () {
    testWidgets('affiche les réglages quand le résultat est prêt', (tester) async {
      final mockResult = SettingsResult(
        settings: [
          SettingRecommendation(
            settingId: 'aperture',
            value: FStop(2.8),
            valueDisplay: 'f/2.8',
            explanationShort: 'Ouverture max pour le flou.',
            // ...
          ),
        ],
        compromises: [],
        sceneSummary: 'Portrait extérieur jour',
        confidence: Confidence.high,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override le provider avec une valeur mockée
            settingsResultProvider.overrideWith((_) async => mockResult),
          ],
          child: const MaterialApp(home: ResultsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('f/2.8'), findsOneWidget);
      expect(find.text('Ouverture max pour le flou.'), findsOneWidget);
    });
  });
}
```

### 9.2. Test d'un Notifier isolé

```dart
void main() {
  group('SceneInputDraft', () {
    test('isLevel1Complete retourne false si un champ manque', () {
      final container = ProviderContainer();
      final notifier = container.read(sceneInputDraftProvider.notifier);

      notifier.setShootType(ShootType.photo);
      notifier.setEnvironment(Environment.outdoorDay);
      notifier.setSubject(Subject.portrait);
      // Pas d'intention → incomplet

      final draft = container.read(sceneInputDraftProvider);
      expect(draft.isLevel1Complete, isFalse);
    });

    test('isLevel1Complete retourne true quand tout est rempli', () {
      final container = ProviderContainer();
      final notifier = container.read(sceneInputDraftProvider.notifier);

      notifier.setShootType(ShootType.photo);
      notifier.setEnvironment(Environment.outdoorDay);
      notifier.setSubject(Subject.portrait);
      notifier.setIntention(Intention.bokeh);

      final draft = container.read(sceneInputDraftProvider);
      expect(draft.isLevel1Complete, isTrue);
    });
  });
}
```

---

## 10. Anti-patterns state management

| Anti-pattern | Exemple | Pourquoi c'est un problème | Solution |
|-------------|---------|--------------------------|----------|
| **State éphémère dans Riverpod** | Provider pour un toggle d'expansion | Pollue le graphe, rebuilds inutiles | `useState` hook ou `StatefulWidget` |
| **ref.read dans build()** | `final x = ref.read(provider)` dans `build` | Pas de rebuild quand le provider change → UI obsolète | `ref.watch` dans build, `ref.read` dans callbacks |
| **Mutation directe d'un state** | `ref.read(listProvider).add(item)` | Contourne la réactivité, le widget ne rebuild pas | `ref.read(provider.notifier).addItem(item)` |
| **Provider God** | Un seul Notifier qui gère tout l'app state | Impossible à tester, rebuild à chaque changement | Un provider par responsabilité |
| **FutureBuilder au lieu d'AsyncValue** | `FutureBuilder(future: ref.read(p).future)` | Perd l'état au rebuild, pas de cache | `ref.watch(provider).when(...)` |
| **Listen sans garde** | `ref.listen` qui navigue sans vérifier prev != next | Navigation double, boucle | Toujours vérifier `prev` avant d'agir |
| **Provider circulaire** | A watch B watch C watch A | Crash runtime | Restructurer le graphe (extraire un provider commun) |
| **Oublier keepAlive** | Le gear provider est dispose quand on va dans settings | Perte du state, re-fetch inutile | `@Riverpod(keepAlive: true)` pour les providers critiques |

---

*Ce document est la référence pour toute l'implémentation du state. Combiné avec les skills 09 (Architecture) et 10 (Modules), il répond à "où mettre le state", "quel type de provider", et "comment les données circulent d'un écran à l'autre".*
