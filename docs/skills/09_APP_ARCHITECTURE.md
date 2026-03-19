# App Architecture & Design Patterns — ShootHelper

> **Skill 09/22** · Clean Architecture, couches, SOLID, injection de dépendances
> Version 1.0 · Mars 2026
> Réf : 08_TECH_STACK_DECISION.md, 04_CAMERA_DATA_ARCHITECTURE.md

---

## 1. Philosophie

L'architecture de ShootHelper repose sur un objectif simple : **pouvoir ajouter une feature, changer une source de données, ou remplacer un composant UI sans toucher au reste de l'app.**

Pour un side project solo, ça semble over-engineered. Mais dans 6 mois, quand tu voudras ajouter le mode vidéo avancé ou changer le moteur de settings, tu seras content que chaque pièce soit dans sa boîte. L'architecture n'est pas un luxe — c'est ce qui fait qu'un side project survit au-delà du MVP.

**Approche choisie : Clean Architecture adaptée Flutter**, avec 3 couches strictes et Riverpod comme colonne vertébrale.

---

## 2. Les 3 couches

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              PRESENTATION                             │  │
│  │  Widgets · Screens · ViewModels (Notifiers)           │  │
│  │  Ce que l'utilisateur voit et touche                  │  │
│  └──────────────────────┬────────────────────────────────┘  │
│                         │ dépend de                         │
│  ┌──────────────────────▼────────────────────────────────┐  │
│  │              DOMAIN                                   │  │
│  │  Entities · Use Cases · Repository interfaces         │  │
│  │  La logique métier pure — ZÉRO dépendance framework   │  │
│  └──────────────────────┬────────────────────────────────┘  │
│                         │ dépend de                         │
│  ┌──────────────────────▼────────────────────────────────┐  │
│  │              DATA                                     │  │
│  │  Repository impls · Data sources · Models · DTOs      │  │
│  │  L'accès aux données (fichiers, réseau, BDD)          │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.1. Règle de dépendance (THE rule)

```
PRESENTATION → DOMAIN ← DATA

La couche Domain ne dépend de RIEN.
La couche Presentation dépend de Domain.
La couche Data dépend de Domain (implémente ses interfaces).
Presentation ne dépend JAMAIS de Data directement.
```

**Concrètement :**

- Domain définit une interface `GearRepository`
- Data fournit l'implémentation `GearRepositoryImpl` (qui lit du JSON)
- Presentation consomme `GearRepository` (l'interface) via Riverpod, sans savoir que c'est du JSON derrière
- Si demain tu remplaces le JSON par SQLite, tu changes Data. Presentation ne bouge pas. Domain ne bouge pas.

### 2.2. Ce que contient chaque couche

#### Domain (le noyau)

```
Contient :
  ✅ Entities (Body, Lens, SceneInput, SettingsResult, SettingDef…)
  ✅ Use Cases (CalculateSettings, ResolveMenuPath, GetCompatibleLenses…)
  ✅ Repository interfaces (abstract classes)
  ✅ Value objects (FStop, ShutterSpeed, IsoValue…)
  ✅ Exceptions métier (GearNotFoundError, IncompatibleLensError…)

Ne contient PAS :
  ❌ import 'package:flutter/…'
  ❌ import 'package:riverpod/…'
  ❌ import 'dart:io'
  ❌ Aucune dépendance framework, aucune dépendance I/O
```

Le domain est du **Dart pur**. Tu pourrais le copier dans un projet Dart CLI et il compilerait. C'est la garantie qu'il est testable, portable et indépendant.

#### Data (l'infrastructure)

```
Contient :
  ✅ Repository implementations (GearRepositoryImpl…)
  ✅ Data sources (LocalJsonDataSource, RemoteDataPackSource…)
  ✅ Models / DTOs (BodyModel, LensModel — avec fromJson/toJson)
  ✅ Mappers (BodyModel → Body entity)
  ✅ File I/O, HTTP, SharedPreferences

Dépend de :
  ✅ Domain (implémente ses interfaces)
  ✅ Packages I/O (dio, path_provider, shared_preferences…)
```

#### Presentation (l'UI)

```
Contient :
  ✅ Screens (widgets de page : HomeScreen, SceneInputScreen…)
  ✅ Widgets (composants réutilisables : SettingCard, MenuBreadcrumb…)
  ✅ ViewModels / Notifiers (logique d'état UI via Riverpod)
  ✅ Router configuration (GoRouter)

Dépend de :
  ✅ Domain (entities, use cases via Riverpod)
  ✅ Flutter SDK
  ✅ Riverpod
```

---

## 3. Structure de dossiers

```
lib/
├── main.dart                           # Point d'entrée, ProviderScope, MaterialApp
├── app.dart                            # Configuration MaterialApp + GoRouter
│
├── core/                               # Utilitaires partagés (toutes couches)
│   ├── constants/
│   │   ├── app_constants.dart          # Constantes globales
│   │   └── photography_constants.dart  # Tables EV, valeurs f-stop standard, etc.
│   ├── errors/
│   │   ├── failures.dart               # Classes d'erreur abstraites
│   │   └── exceptions.dart             # Exceptions custom
│   ├── extensions/
│   │   └── string_extensions.dart
│   └── utils/
│       ├── exposure_math.dart          # Fonctions mathématiques pures (log2, EV…)
│       └── json_utils.dart
│
├── domain/                             # ======= COUCHE DOMAIN =======
│   ├── entities/
│   │   ├── body.dart                   # Body entity (immutable)
│   │   ├── body_spec.dart
│   │   ├── lens.dart
│   │   ├── lens_spec.dart
│   │   ├── menu_tree.dart
│   │   ├── menu_item.dart
│   │   ├── controls.dart
│   │   ├── setting_def.dart
│   │   ├── setting_nav_path.dart
│   │   ├── scene_input.dart
│   │   ├── settings_result.dart
│   │   ├── setting_recommendation.dart
│   │   ├── compromise.dart
│   │   └── gear_profile.dart           # Profil gear de l'utilisateur
│   │
│   ├── value_objects/
│   │   ├── f_stop.dart                 # Ouverture typée avec validation
│   │   ├── shutter_speed.dart          # Vitesse typée (fraction ou secondes)
│   │   ├── iso_value.dart              # ISO typé avec validation range
│   │   └── ev_value.dart               # Exposure Value
│   │
│   ├── repositories/                   # Interfaces (abstract classes)
│   │   ├── gear_repository.dart
│   │   ├── data_pack_repository.dart
│   │   └── settings_repository.dart
│   │
│   ├── use_cases/
│   │   ├── calculate_settings.dart     # Le Settings Engine (skill 06)
│   │   ├── resolve_menu_path.dart      # Résolution chemin menu (skill 07)
│   │   ├── get_compatible_lenses.dart
│   │   ├── download_data_pack.dart
│   │   ├── get_supported_bodies.dart
│   │   └── switch_firmware_language.dart
│   │
│   └── engine/                         # Sous-modules du Settings Engine
│       ├── exposure_calculator.dart     # Triangle d'exposition
│       ├── af_resolver.dart            # Arbre décision AF
│       ├── metering_resolver.dart      # Arbre décision mesure
│       ├── wb_resolver.dart            # Arbre décision WB
│       ├── compromise_detector.dart    # Détection compromis
│       ├── explanation_generator.dart  # Génération textes explicatifs
│       └── astro_calculator.dart       # Règle NPF, cas spécial astro
│
├── data/                               # ======= COUCHE DATA =======
│   ├── models/                         # DTOs avec serialization
│   │   ├── body_model.dart             # Body JSON ↔ Dart
│   │   ├── body_model.g.dart           # Généré par json_serializable
│   │   ├── lens_model.dart
│   │   ├── menu_tree_model.dart
│   │   ├── nav_path_model.dart
│   │   └── manifest_model.dart
│   │
│   ├── mappers/                        # Model ↔ Entity
│   │   ├── body_mapper.dart
│   │   ├── lens_mapper.dart
│   │   └── menu_tree_mapper.dart
│   │
│   ├── data_sources/
│   │   ├── local/
│   │   │   ├── json_data_source.dart   # Lecture des fichiers JSON locaux
│   │   │   ├── preferences_source.dart # SharedPreferences (profil gear)
│   │   │   └── file_manager.dart       # Gestion fichiers data packs
│   │   └── remote/
│   │       └── data_pack_api.dart      # Téléchargement data packs (Dio)
│   │
│   └── repositories/                   # Implémentations concrètes
│       ├── gear_repository_impl.dart
│       ├── data_pack_repository_impl.dart
│       └── settings_repository_impl.dart
│
├── presentation/                       # ======= COUCHE PRESENTATION =======
│   ├── router/
│   │   └── app_router.dart             # GoRouter config + routes
│   │
│   ├── providers/                      # Riverpod providers (pont DI)
│   │   ├── gear_providers.dart         # Providers pour le gear
│   │   ├── scene_providers.dart        # Providers pour la scène en cours
│   │   ├── settings_providers.dart     # Providers pour les résultats
│   │   ├── data_pack_providers.dart    # Providers pour le download
│   │   └── repository_providers.dart   # Providers qui instancient les repos
│   │
│   ├── screens/
│   │   ├── onboarding/
│   │   │   ├── welcome_screen.dart
│   │   │   ├── body_selection_screen.dart
│   │   │   ├── lens_selection_screen.dart
│   │   │   ├── firmware_language_screen.dart
│   │   │   └── recap_download_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── scene_input/
│   │   │   └── scene_input_screen.dart
│   │   ├── results/
│   │   │   ├── results_screen.dart
│   │   │   └── setting_detail_screen.dart
│   │   ├── menu_nav/
│   │   │   └── menu_navigation_screen.dart
│   │   └── settings/
│   │       └── app_settings_screen.dart
│   │
│   ├── widgets/                        # Composants réutilisables
│   │   ├── common/
│   │   │   ├── shoot_chip.dart
│   │   │   ├── section_header.dart
│   │   │   └── loading_indicator.dart
│   │   ├── gear/
│   │   │   ├── body_card.dart
│   │   │   └── lens_card.dart
│   │   ├── scene/
│   │   │   ├── environment_selector.dart
│   │   │   ├── subject_selector.dart
│   │   │   └── constraint_slider.dart
│   │   ├── results/
│   │   │   ├── setting_row.dart
│   │   │   ├── compromise_banner.dart
│   │   │   └── exposure_triangle_card.dart
│   │   └── menu_nav/
│   │       ├── menu_breadcrumb.dart
│   │       ├── nav_step_card.dart
│   │       └── tip_card.dart
│   │
│   └── theme/
│       ├── app_theme.dart              # ThemeData Material 3
│       └── app_colors.dart
│
├── l10n/                               # Internationalisation (Couche 1, skill 07)
│   ├── app_en.arb
│   └── app_fr.arb
│
└── generated/                          # Code généré (build_runner, l10n)
    └── ...
```

---

## 4. Dependency Injection via Riverpod

### 4.1. Pourquoi Riverpod remplace un DI container classique

En Clean Architecture classique (Java/Kotlin), on utilise un container DI (Dagger, GetIt). En Flutter avec Riverpod, **Riverpod EST le container DI**. Il gère :

- L'instanciation des dépendances (repositories, use cases)
- Le lifecycle (dispose automatique)
- Le scoping (providers globaux vs locaux)
- Le testing (override de n'importe quel provider)

On n'a pas besoin de GetIt, Injectable, ou autre. Riverpod suffit.

### 4.2. Graphe de dépendances

```
presentation/providers/repository_providers.dart
  │
  │ Instancie les data sources et repositories
  │
  ▼
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  // Data sources (couche Data)                           │
│  final jsonDataSourceProvider = Provider((ref) {         │
│    return JsonDataSource();                              │
│  });                                                     │
│                                                          │
│  final preferencesSourceProvider = Provider((ref) {      │
│    return PreferencesSource();                           │
│  });                                                     │
│                                                          │
│  final dataPackApiProvider = Provider((ref) {            │
│    return DataPackApi(dio: Dio());                       │
│  });                                                     │
│                                                          │
│  // Repositories (couche Data, typés sur interfaces Domain)
│  final gearRepositoryProvider = Provider<GearRepository>((ref) {
│    return GearRepositoryImpl(                            │
│      jsonDataSource: ref.watch(jsonDataSourceProvider),  │
│      preferencesSource: ref.watch(preferencesSourceProvider),
│    );                                                    │
│  });                                                     │
│                                                          │
│  final dataPackRepositoryProvider = Provider<DataPackRepository>((ref) {
│    return DataPackRepositoryImpl(                        │
│      api: ref.watch(dataPackApiProvider),                │
│      fileManager: ref.watch(fileManagerProvider),        │
│    );                                                    │
│  });                                                     │
│                                                          │
└──────────────────────────────────────────────────────────┘

presentation/providers/settings_providers.dart
  │
  │ Consomme les repositories (via interfaces Domain)
  │
  ▼
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  // Use case provider                                    │
│  final calculateSettingsProvider =                        │
│      Provider<CalculateSettings>((ref) {                 │
│    return CalculateSettings(                             │
│      gearRepo: ref.watch(gearRepositoryProvider),        │
│    );                                                    │
│  });                                                     │
│                                                          │
│  // ViewModel (Notifier) pour l'écran résultats          │
│  final resultsNotifierProvider =                          │
│      AsyncNotifierProvider<ResultsNotifier, SettingsResult?>(
│    ResultsNotifier.new,                                  │
│  );                                                      │
│                                                          │
│  class ResultsNotifier extends AsyncNotifier<SettingsResult?> {
│    @override                                             │
│    FutureOr<SettingsResult?> build() => null;            │
│                                                          │
│    Future<void> calculate(SceneInput scene) async {      │
│      state = const AsyncLoading();                       │
│      final useCase = ref.read(calculateSettingsProvider); │
│      final gear = ref.read(currentGearProvider);         │
│      final result = useCase.execute(gear, scene);        │
│      state = AsyncData(result);                          │
│    }                                                     │
│  }                                                       │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### 4.3. Règle de provider placement

```
RÈGLE : Les providers vivent dans presentation/providers/
        Ils sont le SEUL point de contact entre Presentation et Data.
        
        Un Screen n'importe JAMAIS un repository directement.
        Un Screen lit un provider qui expose un use case ou un notifier.
```

```dart
// ✅ CORRECT — le screen consomme un provider
class ResultsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(resultsNotifierProvider);
    // ...
  }
}

// ❌ INTERDIT — le screen instancie un repository
class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = GearRepositoryImpl(JsonDataSource()); // NON !
    // ...
  }
}
```

---

## 5. Patterns détaillés

### 5.1. Entities (Domain) — Immutables avec Freezed

Toutes les entities sont **immutables** et générées via `freezed`. Pourquoi :
- Pas de mutation accidentelle du state
- `copyWith()` gratuit pour les mises à jour
- `==` et `hashCode` gratuits (value equality)
- Serializable facilement

```dart
// domain/entities/scene_input.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scene_input.freezed.dart';

@freezed
class SceneInput with _$SceneInput {
  const factory SceneInput({
    required ShootType shootType,
    required Environment environment,
    required Subject subject,
    required Intention intention,
    // Niveau 2 (optionnel)
    LightCondition? lightCondition,
    SubjectMotion? subjectMotion,
    SubjectDistance? subjectDistance,
    Mood? mood,
    Support? support,
    int? constraintIsoMax,
    String? constraintShutterMin,
    // Niveau 3 (override)
    WbOverride? wbOverride,
    DofPreference? dofPreference,
    AfAreaOverride? afAreaOverride,
    Bracketing? bracketing,
    FileFormatOverride? fileFormatOverride,
  }) = _SceneInput;
}

enum ShootType { photo, video }
enum Environment { outdoorDay, outdoorNight, indoorBright, indoorDark, studio }
enum Subject { landscape, portrait, street, architecture, macro, astro, sport, wildlife, product }
enum Intention { maxSharpness, bokeh, freezeMotion, motionBlur, lowLight }
// ... etc.
```

### 5.2. Value Objects (Domain) — Types forts

Au lieu de passer des `double` pour les f-stops et des `String` pour les vitesses, on utilise des value objects typés. Ça empêche de confondre un ISO avec une ouverture.

```dart
// domain/value_objects/f_stop.dart
class FStop implements Comparable<FStop> {
  final double value;

  const FStop(this.value) : assert(value > 0);

  /// Valeurs standard 1/3 stop
  static const List<double> standardValues = [
    1.0, 1.1, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.5, 2.8,
    3.2, 3.5, 4.0, 4.5, 5.0, 5.6, 6.3, 7.1, 8.0, 9.0,
    10, 11, 13, 14, 16, 18, 20, 22,
  ];

  /// Arrondi à la valeur standard la plus proche
  FStop roundToNearest() {
    final closest = standardValues.reduce(
      (a, b) => (a - value).abs() < (b - value).abs() ? a : b,
    );
    return FStop(closest);
  }

  /// Différence en stops
  double stopsFrom(FStop other) => 2 * _log2(value / other.value);

  String get display => value >= 10 ? 'f/${value.round()}' : 'f/$value';

  static double _log2(double x) => log(x) / ln2;

  @override
  int compareTo(FStop other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is FStop && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
```

```dart
// domain/value_objects/shutter_speed.dart
class ShutterSpeed implements Comparable<ShutterSpeed> {
  final double seconds;

  const ShutterSpeed(this.seconds) : assert(seconds > 0);

  factory ShutterSpeed.fromFraction(int denominator) =>
      ShutterSpeed(1.0 / denominator);

  String get display {
    if (seconds >= 1) return '${seconds.toStringAsFixed(seconds == seconds.roundToDouble() ? 0 : 1)}s';
    final denom = (1 / seconds).round();
    return '1/${denom}s';
  }

  ShutterSpeed roundToNearest() { /* arrondi aux crans standard */ }

  @override
  int compareTo(ShutterSpeed other) => seconds.compareTo(other.seconds);
}
```

### 5.3. Repository Interface (Domain) → Implementation (Data)

```dart
// domain/repositories/gear_repository.dart
abstract class GearRepository {
  /// Retourne la liste des boîtiers supportés (depuis les data packs locaux)
  Future<List<Body>> getSupportedBodies();

  /// Retourne un boîtier par ID
  Future<Body> getBody(String bodyId);

  /// Retourne les objectifs compatibles avec un boîtier
  Future<List<Lens>> getCompatibleLenses(String bodyId);

  /// Retourne un objectif par ID
  Future<Lens> getLens(String lensId);

  /// Sauvegarde le profil gear de l'utilisateur
  Future<void> saveGearProfile(GearProfile profile);

  /// Charge le profil gear de l'utilisateur
  Future<GearProfile?> loadGearProfile();

  /// Retourne le SettingNavPath pour un réglage sur un boîtier
  Future<SettingNavPath?> getNavPath(String bodyId, String settingId);
}
```

```dart
// data/repositories/gear_repository_impl.dart
class GearRepositoryImpl implements GearRepository {
  final JsonDataSource _jsonDataSource;
  final PreferencesSource _preferencesSource;

  GearRepositoryImpl({
    required JsonDataSource jsonDataSource,
    required PreferencesSource preferencesSource,
  })  : _jsonDataSource = jsonDataSource,
        _preferencesSource = preferencesSource;

  @override
  Future<Body> getBody(String bodyId) async {
    final json = await _jsonDataSource.readBodyJson(bodyId);
    final model = BodyModel.fromJson(json);
    return BodyMapper.toEntity(model);  // Model → Entity
  }

  @override
  Future<void> saveGearProfile(GearProfile profile) async {
    await _preferencesSource.saveGearProfile(profile);
  }

  // ... etc.
}
```

### 5.4. Use Case (Domain) — Une action, une classe

Chaque use case fait **une seule chose** et a une seule méthode publique `execute()`.

```dart
// domain/use_cases/calculate_settings.dart
class CalculateSettings {
  final GearRepository _gearRepo;

  CalculateSettings({required GearRepository gearRepo}) : _gearRepo = gearRepo;

  Future<SettingsResult> execute(GearProfile gear, SceneInput scene) async {
    final body = await _gearRepo.getBody(gear.bodyId);
    final lens = await _gearRepo.getLens(gear.activeLensId);

    // Phase 1 : Contexte
    final context = _buildContext(body, lens, scene);

    // Phase 2 : Réglages indépendants
    final independentSettings = _resolveIndependentSettings(context);

    // Phase 3 : Triangle d'exposition
    final exposureSettings = ExposureCalculator.resolve(context);

    // Phase 4 : Compromis
    final compromises = CompromiseDetector.detect(
      context, independentSettings, exposureSettings,
    );

    // Assemblage
    final allSettings = [...independentSettings, ...exposureSettings];
    final explanations = ExplanationGenerator.generate(
      allSettings, context, compromises,
    );

    return SettingsResult(
      settings: allSettings.map((s) => s.withExplanation(explanations[s.settingId]!)).toList(),
      compromises: compromises,
      sceneSummary: _buildSummary(scene),
      confidence: _assessConfidence(scene, compromises),
    );
  }
}
```

### 5.5. Model + Mapper (Data) — Séparer transport et métier

Le Model est le format JSON. L'Entity est le format métier. Le Mapper convertit entre les deux. Pourquoi cette séparation :

- Le format JSON peut changer (nouveau champ, renommage) sans affecter le domain
- Le domain n'a pas besoin de savoir que les données viennent du JSON
- Les tests du domain n'ont pas besoin de JSON

```dart
// data/models/body_model.dart
@JsonSerializable()
class BodyModel {
  final String id;
  @JsonKey(name: 'brand_id')
  final String brandId;
  @JsonKey(name: 'mount_id')
  final String mountId;
  final String name;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'sensor_size')
  final String sensorSize;
  @JsonKey(name: 'crop_factor')
  final double cropFactor;
  // ... toutes les propriétés JSON

  factory BodyModel.fromJson(Map<String, dynamic> json) =>
      _$BodyModelFromJson(json);
}
```

```dart
// data/mappers/body_mapper.dart
class BodyMapper {
  static Body toEntity(BodyModel model) {
    return Body(
      id: model.id,
      brandId: model.brandId,
      mountId: model.mountId,
      name: model.name,
      displayName: model.displayName,
      sensorSize: SensorSize.fromString(model.sensorSize),
      cropFactor: model.cropFactor,
      spec: BodySpecMapper.toEntity(model.spec),
      controls: ControlsMapper.toEntity(model.controls),
      // ...
    );
  }
}
```

### 5.6. Notifier (Presentation) — ViewModel Riverpod

Les Notifiers sont les ViewModels. Ils orchestrent l'interaction entre l'UI et les use cases.

```dart
// presentation/providers/scene_providers.dart

/// State de la scène en cours de construction
@riverpod
class SceneInputNotifier extends _$SceneInputNotifier {
  @override
  SceneInput build() => const SceneInput(
    shootType: ShootType.photo,
    environment: Environment.outdoorDay,
    subject: Subject.landscape,
    intention: Intention.maxSharpness,
  );

  void setShootType(ShootType type) =>
      state = state.copyWith(shootType: type);

  void setEnvironment(Environment env) =>
      state = state.copyWith(environment: env);

  void setSubject(Subject subject) =>
      state = state.copyWith(subject: subject);

  void setIntention(Intention intention) =>
      state = state.copyWith(intention: intention);

  // Niveau 2
  void setLightCondition(LightCondition? condition) =>
      state = state.copyWith(lightCondition: condition);

  void setSupport(Support? support) =>
      state = state.copyWith(support: support);

  // ... etc.

  void reset() => state = build();
}
```

---

## 6. SOLID appliqué à ShootHelper

### S — Single Responsibility

| Classe | Responsabilité unique |
|--------|----------------------|
| `ExposureCalculator` | Calcule le triangle d'exposition |
| `AfResolver` | Détermine le mode AF |
| `CompromiseDetector` | Détecte les compromis |
| `JsonDataSource` | Lit des fichiers JSON depuis le filesystem |
| `BodyMapper` | Convertit BodyModel ↔ Body |
| `ResultsNotifier` | Gère l'état de l'écran résultats |

Chaque classe a **une raison de changer**. Si le format JSON change, seul `JsonDataSource` + `BodyModel` changent. Si l'algorithme AF change, seul `AfResolver` change.

### O — Open/Closed

Le Settings Engine est extensible sans modification grâce aux **resolver interfaces** :

```dart
// domain/engine/setting_resolver.dart
abstract class SettingResolver {
  String get settingId;
  SettingRecommendation resolve(EngineContext context);
}

// domain/engine/af_resolver.dart
class AfResolver implements SettingResolver {
  @override
  String get settingId => 'af_mode';

  @override
  SettingRecommendation resolve(EngineContext context) {
    // Arbre de décision AF (skill 06)
  }
}
```

Pour ajouter un nouveau réglage (ex: Film Simulation Fuji), tu crées un nouveau `SettingResolver` et tu l'enregistres dans la liste du moteur. Zéro modification du code existant.

```dart
// domain/engine/settings_engine.dart
class SettingsEngine {
  final List<SettingResolver> _resolvers;

  SettingsEngine({required List<SettingResolver> resolvers})
      : _resolvers = resolvers;

  List<SettingRecommendation> resolveAll(EngineContext context) {
    return _resolvers.map((r) => r.resolve(context)).toList();
  }
}

// Enregistrement — ajouter un resolver = une ligne
final engine = SettingsEngine(resolvers: [
  AfResolver(),
  AfAreaResolver(),
  MeteringResolver(),
  WbResolver(),
  DriveResolver(),
  StabilizationResolver(),
  FileFormatResolver(),
  // Ajouter ici pour étendre sans toucher au reste :
  // FilmSimulationResolver(),
]);
```

### L — Liskov Substitution

Toute implémentation de `GearRepository` doit être substituable sans casser le code consommateur. En pratique :

- `GearRepositoryImpl` (JSON local) peut être remplacé par `GearRepositorySqlite` (Drift)
- Les tests utilisent `MockGearRepository` (mocktail)
- Le code consommateur (use cases, notifiers) ne voit que l'interface

### I — Interface Segregation

Les repositories sont découpés par domaine fonctionnel, pas regroupés en un giga-repository :

```
GearRepository        → boîtiers, objectifs, profil
DataPackRepository    → téléchargement, mise à jour data packs
SettingsRepository    → préférences de l'app (pas le calcul)
```

Un écran qui affiche seulement la liste des boîtiers ne dépend que de `GearRepository`, pas du reste.

### D — Dependency Inversion

Le domain définit les interfaces, la data les implémente. Le domain ne connaît pas la data. C'est la **règle de dépendance** (§2.1) — le D de SOLID et le cœur de Clean Architecture sont la même chose.

---

## 7. Flux de données complet (exemple)

Scénario : l'utilisateur appuie sur "Calculer mes réglages".

```
[SceneInputScreen]
  │ {Tap "Calculer"}
  │
  ▼
[ResultsNotifier.calculate(sceneInput)]                    PRESENTATION
  │
  │ ref.read(calculateSettingsProvider)
  │ → récupère le use case CalculateSettings
  │
  ▼
[CalculateSettings.execute(gearProfile, sceneInput)]       DOMAIN
  │
  │ appelle gearRepo.getBody(bodyId)
  │ appelle gearRepo.getLens(lensId)
  │
  ▼
[GearRepositoryImpl.getBody(bodyId)]                       DATA
  │
  │ jsonDataSource.readBodyJson(bodyId)
  │ → lit le fichier JSON local
  │ BodyModel.fromJson(json)
  │ → parse en Model
  │ BodyMapper.toEntity(model)
  │ → convertit en Entity
  │
  ▼ retour de Body entity
[CalculateSettings (suite)]                                DOMAIN
  │
  │ ExposureCalculator.resolve(context)
  │ AfResolver.resolve(context)
  │ CompromiseDetector.detect(...)
  │ ExplanationGenerator.generate(...)
  │
  ▼ retour de SettingsResult
[ResultsNotifier]                                          PRESENTATION
  │
  │ state = AsyncData(result)
  │
  ▼
[ResultsScreen]                                            PRESENTATION
  │
  │ ref.watch(resultsNotifierProvider)
  │ → rebuild avec les données
  │ → affiche la liste de réglages
```

---

## 8. Règles de code

### 8.1. Imports

```dart
// ✅ CORRECT — un fichier Domain importe Domain
import 'package:shoothelper/domain/entities/body.dart';

// ❌ INTERDIT — un fichier Domain importe Data
import 'package:shoothelper/data/models/body_model.dart';

// ❌ INTERDIT — un fichier Domain importe Flutter
import 'package:flutter/material.dart';

// ❌ INTERDIT — un fichier Presentation importe Data directement
import 'package:shoothelper/data/repositories/gear_repository_impl.dart';

// ✅ CORRECT — un fichier Presentation importe Domain (interface)
import 'package:shoothelper/domain/repositories/gear_repository.dart';
```

Ces règles peuvent être enforcées via un linter custom ou un check CI (analyse des imports par couche).

### 8.2. Nommage

| Type | Convention | Exemple |
|------|-----------|---------|
| Entity | PascalCase, nom métier | `Body`, `SceneInput`, `SettingsResult` |
| Value Object | PascalCase, nom technique | `FStop`, `ShutterSpeed`, `IsoValue` |
| Model (DTO) | PascalCase + Model suffix | `BodyModel`, `LensModel` |
| Mapper | PascalCase + Mapper suffix | `BodyMapper`, `LensMapper` |
| Repository interface | PascalCase + Repository | `GearRepository` |
| Repository impl | PascalCase + RepositoryImpl | `GearRepositoryImpl` |
| Use Case | PascalCase, verbe + nom | `CalculateSettings`, `GetCompatibleLenses` |
| Notifier | PascalCase + Notifier | `ResultsNotifier`, `SceneInputNotifier` |
| Provider | camelCase + Provider | `gearRepositoryProvider`, `resultsNotifierProvider` |
| Screen widget | PascalCase + Screen | `HomeScreen`, `ResultsScreen` |
| Composant widget | PascalCase descriptif | `SettingRow`, `MenuBreadcrumb` |
| Fichier | snake_case | `gear_repository.dart`, `body_mapper.dart` |

### 8.3. Organisation des imports dans un fichier

```dart
// 1. Dart SDK
import 'dart:math';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. Packages tiers
import 'package:riverpod/riverpod.dart';

// 4. Imports du projet (par couche, dans l'ordre domain → data → presentation)
import 'package:shoothelper/domain/entities/body.dart';
```

---

## 9. Testing par couche

| Couche | Type de test | Ce qu'on teste | Dépendances |
|--------|-------------|----------------|-------------|
| **Domain** | Unit tests purs | Use Cases, Engine resolvers, Value Objects, calculs | Aucune (Dart pur). Mocks des repositories avec mocktail. |
| **Data** | Unit tests | Mappers (Model → Entity correcte), JsonDataSource (parsing) | Fixtures JSON, fichiers de test |
| **Presentation** | Widget tests | Screens et widgets avec providers mockés | ProviderScope overrides, mocktail |
| **Intégration** | Integration tests | Flows complets (onboarding → résultats) | App réelle ou semi-mockée |

**La majorité des tests (~70%) sont dans Domain** — c'est là que vit la logique critique (Settings Engine). Ces tests sont rapides (pas de Flutter, pas d'I/O) et constituent le filet de sécurité principal.

```dart
// test/domain/engine/exposure_calculator_test.dart
void main() {
  group('ExposureCalculator', () {
    test('bokeh intent opens aperture to max', () {
      final context = EngineContext(
        body: mockBody,
        lens: mockLensF28,
        scene: SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
        ),
      );

      final result = ExposureCalculator.resolve(context);
      final aperture = result.firstWhere((r) => r.settingId == 'aperture');

      expect(aperture.value, equals(FStop(2.8)));
    });
  });
}
```

---

## 10. Anti-patterns à éviter

| Anti-pattern | Pourquoi c'est un problème | Solution ShootHelper |
|-------------|--------------------------|---------------------|
| **God Widget** | Un screen de 500 lignes qui fait tout | Découper en widgets + Notifier. Screen = assemblage. |
| **Business logic dans le widget** | Calcul d'exposition dans un `onPressed` | Toute logique dans Domain (use cases, engine). |
| **Repository qui retourne des Models** | Presentation dépend du format de données | Repository retourne des Entities. Mapper dans Data. |
| **Provider qui fait trop** | Un provider qui fetch + calcule + formate | Un provider par responsabilité. Chaîner via `ref.watch`. |
| **Imports cycliques entre couches** | Domain importe Data | Respecter la règle de dépendance. CI check des imports. |
| **State mutable** | Entity modifiée en place | Freezed (immutable). `copyWith()` pour les mises à jour. |
| **Strings magiques** | `if (mode == "af-c")` partout | Enums partout (`AfMode.afC`). Conversion string ↔ enum dans Data. |
| **Pas de gestion d'erreur** | `Future` sans try/catch | Wrapper `Result<T>` ou `AsyncValue` de Riverpod. |

---

*Ce document est la référence pour tous les skills d'implémentation (10 Module & Feature Architecture, 11 State Management, 12 Local Database, 13 Offline-First). Chaque décision de structure ou de pattern doit être traçable à ce skill.*
