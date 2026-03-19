# Testing Strategy — ShootHelper

> **Skill 20/22** · Tests unitaires, intégration, UI, edge cases, CI
> Version 1.0 · Mars 2026
> Réf : Tous les skills précédents (consolidation des scénarios de test)

---

## 1. Philosophie

**Le Settings Engine est le cœur critique** — un mauvais réglage recommandé = perte de confiance totale. Les tests du moteur sont les plus importants de toute l'app. Tout le reste (UI, navigation, download) est secondaire en termes de risque.

**La pyramide de tests de ShootHelper est inversée par rapport à une app classique.** En général, une app a plus de tests UI que de tests unitaires. Ici, c'est l'inverse : le gros du travail est dans le domain (Dart pur, rapide, pas de Flutter).

```
Pyramide de tests ShootHelper :

         ╱╲
        ╱  ╲          Integration tests (5%)
       ╱    ╲         Flows complets, E2E
      ╱──────╲
     ╱        ╲       Widget tests (20%)
    ╱          ╲      Écrans, composants UI
   ╱────────────╲
  ╱              ╲    Unit tests (75%)
 ╱                ╲   Engine, resolvers, value objects, mappers,
╱__________________╲  use cases, data sources
```

---

## 2. Outillage

| Outil | Usage | Package |
|-------|-------|---------|
| **flutter_test** | Unit + widget tests | Intégré Flutter SDK |
| **integration_test** | Tests E2E sur device/emulateur | Intégré Flutter SDK |
| **mocktail** | Mocking (sans code generation) | `mocktail: ^1.0.0` |
| **fake_async** | Contrôle du temps (timers, debounce) | Intégré `dart:async` |
| **golden_toolkit** | Screenshot testing (golden files) | `golden_toolkit: ^0.15.0` (optionnel V2) |

**Pourquoi mocktail plutôt que mockito ?** Mocktail ne nécessite pas de code generation (`build_runner`). Pour un projet solo, moins de build_runner = moins de friction. Et mocktail a une API plus concise.

---

## 3. Structure des dossiers de test

Les tests mirrorent la structure de `lib/`. Chaque fichier testable a un fichier test correspondant.

```
test/
├── core/
│   ├── utils/
│   │   └── exposure_math_test.dart
│   └── errors/
│       └── failures_test.dart
│
├── shared/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── body_test.dart
│   │   │   └── scene_input_test.dart
│   │   └── value_objects/
│   │       ├── f_stop_test.dart
│   │       ├── shutter_speed_test.dart
│   │       └── iso_value_test.dart
│   └── data/
│       ├── models/
│       │   ├── body_model_test.dart
│       │   └── lens_model_test.dart
│       ├── mappers/
│       │   ├── body_mapper_test.dart
│       │   └── menu_tree_mapper_test.dart
│       ├── data_sources/
│       │   ├── local/
│       │   │   ├── json_data_source_test.dart
│       │   │   ├── camera_data_cache_test.dart
│       │   │   └── file_manager_test.dart
│       │   └── remote/
│       │       └── data_pack_api_test.dart
│       └── repositories/
│           └── gear_repository_impl_test.dart
│
├── features/
│   ├── settings_engine/
│   │   └── domain/
│   │       ├── engine/
│   │       │   ├── settings_engine_test.dart        # Tests intégration moteur
│   │       │   ├── exposure_calculator_test.dart     # Triangle d'exposition
│   │       │   ├── resolvers/
│   │       │   │   ├── af_mode_resolver_test.dart
│   │       │   │   ├── af_area_resolver_test.dart
│   │       │   │   ├── metering_resolver_test.dart
│   │       │   │   ├── wb_resolver_test.dart
│   │       │   │   ├── drive_resolver_test.dart
│   │       │   │   ├── stabilization_resolver_test.dart
│   │       │   │   ├── file_format_resolver_test.dart
│   │       │   │   └── exposure_mode_resolver_test.dart
│   │       │   ├── compromise_detector_test.dart
│   │       │   ├── alternative_generator_test.dart
│   │       │   ├── astro_calculator_test.dart
│   │       │   └── explanation_generator_test.dart
│   │       └── use_cases/
│   │           └── calculate_settings_test.dart
│   │
│   ├── scene_input/
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── suggest_scene_defaults_test.dart
│   │   │       ├── get_contextual_options_test.dart
│   │   │       └── get_scene_warnings_test.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── scene_input_providers_test.dart
│   │       └── screens/
│   │           └── scene_input_screen_test.dart
│   │
│   ├── results/
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── filter_display_settings_test.dart
│   │   │       └── format_settings_for_clipboard_test.dart
│   │   └── presentation/
│   │       ├── widgets/
│   │       │   ├── setting_row_test.dart
│   │       │   ├── compromise_banner_test.dart
│   │       │   └── exposure_summary_card_test.dart
│   │       └── screens/
│   │           ├── results_screen_test.dart
│   │           └── setting_detail_screen_test.dart
│   │
│   ├── menu_nav/
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       └── resolve_menu_path_test.dart
│   │   └── presentation/
│   │       └── screens/
│   │           └── menu_navigation_screen_test.dart
│   │
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── onboarding_providers_test.dart
│   │       └── screens/
│   │           └── body_selection_screen_test.dart
│   │
│   ├── data_pack/
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── download_data_pack_test.dart
│   │   │       └── check_data_pack_update_test.dart
│   │   └── presentation/
│   │       └── providers/
│   │           └── download_progress_test.dart
│   │
│   └── gear/
│       └── presentation/
│           └── screens/
│               └── app_settings_screen_test.dart
│
├── fixtures/                            # Données de test (JSON)
│   ├── bodies/
│   │   ├── sony_a6700.json              # Body complet pour tests
│   │   ├── canon_r50.json
│   │   └── sony_a6700_minimal.json      # Body avec minimum de champs
│   ├── lenses/
│   │   ├── sigma_18-50_f2.8.json
│   │   └── variable_aperture_lens.json  # Zoom à ouverture variable
│   ├── menu_trees/
│   │   ├── sony_a6700_menu_tree.json
│   │   └── canon_r50_menu_tree.json
│   ├── nav_paths/
│   │   ├── sony_a6700_nav_paths.json
│   │   └── canon_r50_nav_paths.json
│   └── shared/
│       └── setting_defs.json
│
├── helpers/
│   ├── test_fixtures.dart               # Chargement des fixtures JSON
│   ├── mock_providers.dart              # Overrides Riverpod pour tests
│   ├── mock_bodies.dart                 # Body factories pour tests rapides
│   ├── mock_lenses.dart                 # Lens factories
│   ├── mock_scenes.dart                 # SceneInput factories
│   └── widget_test_helpers.dart         # Helpers pour pump widgets avec providers
│
└── integration_test/
    ├── app_test.dart                    # Test E2E principal
    ├── onboarding_flow_test.dart
    └── shoot_flow_test.dart             # Scène → Résultats → Menu Nav
```

---

## 4. Fixtures & Factories

### 4.1. Fixtures JSON

Les fixtures sont des fichiers JSON réels (extraits des data packs ou simplifiés) stockés dans `test/fixtures/`. Ils servent aux tests de parsing, de mapping, et d'intégration.

```dart
// test/helpers/test_fixtures.dart

class TestFixtures {
  static Future<Map<String, dynamic>> loadJson(String path) async {
    final file = File('test/fixtures/$path');
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  static Future<Body> loadBody(String bodyId) async {
    final json = await loadJson('bodies/$bodyId.json');
    return BodyMapper.toEntity(BodyModel.fromJson(json));
  }

  static Future<Lens> loadLens(String lensId) async {
    final json = await loadJson('lenses/$lensId.json');
    return LensMapper.toEntity(LensModel.fromJson(json));
  }

  static Future<MenuTree> loadMenuTree(String bodyId) async {
    final json = await loadJson('menu_trees/${bodyId}_menu_tree.json');
    return MenuTreeMapper.toEntity(MenuTreeModel.fromJson(json));
  }
}
```

### 4.2. Factories (objets Dart pour tests rapides)

Pour les tests unitaires qui n'ont pas besoin de JSON complet, des factories créent des objets minimalistes.

```dart
// test/helpers/mock_bodies.dart

class MockBodies {
  /// Sony A6700 simplifié — les champs utiles pour le moteur
  static Body sonyA6700({
    int isoUsableMax = 6400,
    bool hasIbis = true,
    double ibisStops = 5.0,
    bool hasEyeAf = true,
  }) {
    return Body(
      id: 'sony_a6700',
      brandId: 'sony',
      mountId: 'sony_e',
      name: 'Sony A6700',
      displayName: 'A6700',
      sensorSize: SensorSize.apsC,
      cropFactor: 1.5,
      spec: BodySpec(
        sensor: SensorSpec(
          isoRange: IsoRange(min: 100, max: 32000),
          isoUsableMax: isoUsableMax,
          hasIbis: hasIbis,
          ibisStops: ibisStops,
        ),
        autofocus: AfSpec(
          modes: ['af-s', 'af-c', 'dmf', 'mf'],
          areas: ['wide', 'zone', 'center', 'spot', 'tracking'],
          hasEyeAf: hasEyeAf,
          eyeAfModes: hasEyeAf ? ['af-c'] : [],
        ),
        shutter: ShutterSpec(
          mechanical: ShutterRange(min: '1/4000', max: '30'),
          electronic: ShutterRange(min: '1/8000', max: '30'),
        ),
        metering: MeteringSpec(modes: ['multi', 'center', 'spot', 'highlight']),
        whiteBalance: WbSpec(
          presets: ['auto', 'daylight', 'shade', 'cloudy', 'tungsten', 'fluorescent'],
          customKelvinRange: KelvinRange(min: 2500, max: 9900),
        ),
        stabilization: StabSpec(hasIbis: hasIbis, ibisStops: ibisStops),
      ),
      // ... controls et menuTree simplifiés
    );
  }

  /// Canon R50 — pas d'IBIS, Eye-AF limité
  static Body canonR50() { /* ... */ }

  /// Body générique full-frame
  static Body genericFullFrame() { /* ... */ }
}
```

```dart
// test/helpers/mock_lenses.dart

class MockLenses {
  /// Sigma 18-50mm f/2.8 — zoom constant
  static Lens sigma1850f28({double minFocusDistance = 0.125}) {
    return Lens(
      id: 'sigma_18-50_f2.8',
      brandId: 'sigma',
      mountId: 'sony_e',
      displayName: 'Sigma 18-50mm f/2.8',
      type: LensType.zoom,
      designedFor: SensorSize.apsC,
      spec: LensSpec(
        focalLength: FocalLength(type: 'zoom', minMm: 18, maxMm: 50),
        aperture: ApertureSpec(
          type: 'constant',
          maxAperture: 2.8,
          minAperture: 22,
        ),
        focus: FocusSpec(minFocusDistanceM: minFocusDistance),
        stabilization: LensStabSpec(hasOis: false),
      ),
    );
  }

  /// Kit lens à ouverture variable
  static Lens variableApertureKit() {
    return Lens(
      id: 'sony_16-50_f3.5-5.6',
      // ...
      spec: LensSpec(
        aperture: ApertureSpec(
          type: 'variable',
          maxAperture: 3.5,
          minAperture: 22,
          variableApertureMap: [
            ApertureMapEntry(focalMm: 16, maxAperture: 3.5),
            ApertureMapEntry(focalMm: 35, maxAperture: 5.0),
            ApertureMapEntry(focalMm: 50, maxAperture: 5.6),
          ],
        ),
      ),
    );
  }

  /// Prime 50mm f/1.8
  static Lens prime50f18() { /* ... */ }
}
```

```dart
// test/helpers/mock_scenes.dart

class MockScenes {
  static SceneInput portraitOutdoorBokeh() => const SceneInput(
    shootType: ShootType.photo,
    environment: Environment.outdoorDay,
    subject: Subject.portrait,
    intention: Intention.bokeh,
  );

  static SceneInput astroTripod() => const SceneInput(
    shootType: ShootType.photo,
    environment: Environment.outdoorNight,
    subject: Subject.astro,
    intention: Intention.maxSharpness,
    support: Support.tripod,
    lightCondition: LightCondition.starryNight,
  );

  static SceneInput sportIndoorDark() => const SceneInput(
    shootType: ShootType.photo,
    environment: Environment.indoorDark,
    subject: Subject.sport,
    intention: Intention.freezeMotion,
  );

  static SceneInput impossibleConstraints() => const SceneInput(
    shootType: ShootType.photo,
    environment: Environment.indoorDark,
    subject: Subject.sport,
    intention: Intention.freezeMotion,
    constraintIsoMax: 400,
    constraintShutterMin: '1/1000',
  );

  // ... etc pour chaque scénario type
}
```

### 4.3. Widget test helpers

```dart
// test/helpers/widget_test_helpers.dart

/// Wrappe un widget avec ProviderScope + MaterialApp pour les tests
Widget createTestWidget(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(body: child),
    ),
  );
}

/// Overrides communs pour les tests widget
List<Override> defaultOverrides({
  Body? body,
  Lens? lens,
  SettingsResult? result,
}) {
  return [
    if (body != null)
      currentBodyProvider.overrideWith((_) => body),
    if (lens != null)
      currentLensProvider.overrideWith((_) => lens),
    if (result != null)
      settingsResultProvider.overrideWith((_) async => result),
  ];
}
```

---

## 5. Tests unitaires — Couche Domain

### 5.1. Value Objects

```dart
// test/shared/domain/value_objects/f_stop_test.dart

void main() {
  group('FStop', () {
    test('display formate correctement', () {
      expect(FStop(2.8).display, 'f/2.8');
      expect(FStop(11).display, 'f/11');
      expect(FStop(1.4).display, 'f/1.4');
    });

    test('roundToNearest arrondit au cran standard 1/3', () {
      expect(FStop(2.9).roundToNearest().value, 2.8);
      expect(FStop(3.0).roundToNearest().value, 2.8); // Plus proche de 2.8 que de 3.2
      expect(FStop(7.5).roundToNearest().value, 7.1);
    });

    test('stopsFrom calcule la différence en stops', () {
      expect(FStop(2.8).stopsFrom(FStop(2.0)), closeTo(1.0, 0.1));
      expect(FStop(5.6).stopsFrom(FStop(2.8)), closeTo(2.0, 0.1));
    });

    test('compareTo ordonne correctement', () {
      final stops = [FStop(5.6), FStop(2.8), FStop(8.0), FStop(1.4)];
      stops.sort();
      expect(stops.map((s) => s.value), [1.4, 2.8, 5.6, 8.0]);
    });

    test('value equality fonctionne', () {
      expect(FStop(2.8), equals(FStop(2.8)));
      expect(FStop(2.8), isNot(equals(FStop(4.0))));
    });
  });
}
```

### 5.2. ExposureCalculator (Triangle d'exposition)

```dart
// test/features/settings_engine/domain/engine/exposure_calculator_test.dart

void main() {
  group('ExposureCalculator', () {
    group('resolve_iso', () {
      test('calcule ISO correctement pour une exposition donnée', () {
        // EV 14 (plein soleil), f/2.8, 1/250s → ISO devrait être ~100
        final iso = ExposureCalculator.resolveIso(
          aperture: FStop(2.8),
          shutterSeconds: 1 / 250,
          evTarget: 14,
        );
        expect(iso, closeTo(100, 50)); // ISO 100 ± 50
      });

      test('ISO monte en basse lumière', () {
        // EV 6 (indoor sombre), f/2.8, 1/125s → ISO élevé
        final iso = ExposureCalculator.resolveIso(
          aperture: FStop(2.8),
          shutterSeconds: 1 / 125,
          evTarget: 6,
        );
        expect(iso, greaterThan(1600));
      });
    });

    group('resolve_shutter', () {
      test('calcule vitesse correctement', () {
        // EV 14, f/8, ISO 100 → vitesse rapide
        final shutter = ExposureCalculator.resolveShutter(
          aperture: FStop(8),
          iso: 100,
          evTarget: 14,
        );
        expect(shutter, closeTo(1 / 250, 1 / 500));
      });
    });

    group('bokeh intent', () {
      test('ouvre l\'ouverture au max', () {
        final ctx = EngineContext(
          body: MockBodies.sonyA6700(),
          lens: MockLenses.sigma1850f28(),
          scene: MockScenes.portraitOutdoorBokeh(),
        );
        final result = ExposureCalculator.resolve(ctx);
        final aperture = result.firstWhere((r) => r.settingId == 'aperture');
        expect(aperture.value, equals(FStop(2.8)));
      });
    });

    group('freeze_motion intent', () {
      test('fixe une vitesse rapide en priorité', () {
        final ctx = EngineContext(
          body: MockBodies.sonyA6700(),
          lens: MockLenses.sigma1850f28(),
          scene: MockScenes.sportIndoorDark(),
        );
        final result = ExposureCalculator.resolve(ctx);
        final shutter = result.firstWhere((r) => r.settingId == 'shutter_speed');
        expect((shutter.value as ShutterSpeed).seconds, lessThanOrEqualTo(1 / 500));
      });

      test('monte l\'ISO pour compenser', () {
        final ctx = EngineContext(
          body: MockBodies.sonyA6700(),
          lens: MockLenses.sigma1850f28(),
          scene: MockScenes.sportIndoorDark(),
        );
        final result = ExposureCalculator.resolve(ctx);
        final iso = result.firstWhere((r) => r.settingId == 'iso');
        expect(iso.value as int, greaterThan(800));
      });
    });

    group('arrondi aux valeurs standard', () {
      test('arrondit l\'ISO au cran standard le plus proche', () {
        final rounded = ExposureCalculator.roundIsoToStandard(2200);
        expect(rounded, isIn([2000, 2500])); // Un des deux crans adjacents
      });
    });
  });
}
```

### 5.3. Resolvers individuels (arbres de décision)

```dart
// test/features/settings_engine/domain/engine/resolvers/af_mode_resolver_test.dart

void main() {
  final resolver = AfModeResolver();

  group('AfModeResolver', () {
    test('astro → MF', () {
      final ctx = EngineContext(
        body: MockBodies.sonyA6700(),
        lens: MockLenses.sigma1850f28(),
        scene: MockScenes.astroTripod(),
      );
      final result = resolver.resolve(ctx);
      expect(result.value, 'mf');
    });

    test('portrait immobile → AF-S', () {
      final ctx = EngineContext(
        body: MockBodies.sonyA6700(),
        lens: MockLenses.sigma1850f28(),
        scene: const SceneInput(
          shootType: ShootType.photo,
          environment: Environment.outdoorDay,
          subject: Subject.portrait,
          intention: Intention.bokeh,
          subjectMotion: SubjectMotion.still,
        ),
      );
      final result = resolver.resolve(ctx);
      expect(result.value, 'af-s');
    });

    test('sport rapide → AF-C', () {
      final ctx = EngineContext(
        body: MockBodies.sonyA6700(),
        lens: MockLenses.sigma1850f28(),
        scene: MockScenes.sportIndoorDark(),
      );
      final result = resolver.resolve(ctx);
      expect(result.value, 'af-c');
    });

    test('fallback si mode non supporté → mode le plus proche', () {
      final bodyWithoutDmf = MockBodies.sonyA6700(); // DMF removed from modes
      // ... test que le resolver choisit un mode disponible
    });
  });
}
```

### 5.4. CompromiseDetector

```dart
// test/features/settings_engine/domain/engine/compromise_detector_test.dart

void main() {
  group('CompromiseDetector', () {
    test('détecte ISO > usable max', () {
      final compromises = CompromiseDetector.detect(
        EngineContext(body: MockBodies.sonyA6700(isoUsableMax: 6400), /*...*/),
        [SettingRecommendation(settingId: 'iso', value: 8000, /*...*/)],
      );
      expect(compromises, hasLength(1));
      expect(compromises.first.type, CompromiseType.noise);
      expect(compromises.first.severity, CompromiseSeverity.warning);
    });

    test('détecte ISO > range max → critical', () {
      final compromises = CompromiseDetector.detect(
        EngineContext(body: MockBodies.sonyA6700(), /*...*/),
        [SettingRecommendation(settingId: 'iso', value: 64000, /*...*/)],
      );
      expect(compromises.first.severity, CompromiseSeverity.critical);
    });

    test('détecte astro sans trépied → critical', () {
      final compromises = CompromiseDetector.detect(
        EngineContext(
          body: MockBodies.sonyA6700(),
          lens: MockLenses.sigma1850f28(),
          scene: const SceneInput(
            shootType: ShootType.photo,
            environment: Environment.outdoorNight,
            subject: Subject.astro,
            intention: Intention.maxSharpness,
            support: Support.handheld,
          ),
        ),
        [],
      );
      expect(compromises.any((c) => c.type == CompromiseType.impossible), isTrue);
    });

    test('aucun compromis pour une scène facile', () {
      final compromises = CompromiseDetector.detect(
        EngineContext(
          body: MockBodies.sonyA6700(),
          lens: MockLenses.sigma1850f28(),
          scene: MockScenes.portraitOutdoorBokeh(),
        ),
        [SettingRecommendation(settingId: 'iso', value: 200, /*...*/)],
      );
      expect(compromises, isEmpty);
    });
  });
}
```

### 5.5. AstroCalculator (Règle NPF)

```dart
// test/features/settings_engine/domain/engine/astro_calculator_test.dart

void main() {
  group('AstroCalculator - Règle NPF', () {
    test('Sony A6700 @ 18mm f/2.8 → ~12s', () {
      final tMax = AstroCalculator.calculateMaxExposure(
        focalMm: 18,
        aperture: FStop(2.8),
        sensorWidthMm: 23.5,
        sensorHeightMm: 15.6,
        megapixels: 26.0,
      );
      expect(tMax, closeTo(12, 3)); // 12s ± 3s
    });

    test('50mm → beaucoup plus court', () {
      final tMax = AstroCalculator.calculateMaxExposure(
        focalMm: 50,
        aperture: FStop(2.8),
        sensorWidthMm: 23.5,
        sensorHeightMm: 15.6,
        megapixels: 26.0,
      );
      expect(tMax, lessThan(6)); // Beaucoup plus court
    });

    test('full frame → pixel pitch plus grand → temps plus long', () {
      final tMaxFF = AstroCalculator.calculateMaxExposure(
        focalMm: 18,
        aperture: FStop(2.8),
        sensorWidthMm: 36.0,
        sensorHeightMm: 24.0,
        megapixels: 24.0,
      );
      final tMaxApsC = AstroCalculator.calculateMaxExposure(
        focalMm: 18,
        aperture: FStop(2.8),
        sensorWidthMm: 23.5,
        sensorHeightMm: 15.6,
        megapixels: 26.0,
      );
      expect(tMaxFF, greaterThan(tMaxApsC));
    });
  });
}
```

### 5.6. ResolveMenuPath

```dart
// test/features/menu_nav/domain/use_cases/resolve_menu_path_test.dart

void main() {
  late ResolveMenuPath useCase;
  late MockGearRepository mockRepo;

  setUp(() async {
    mockRepo = MockGearRepository();
    useCase = ResolveMenuPath(gearRepo: mockRepo);

    // Setup fixtures
    final body = await TestFixtures.loadBody('sony_a6700');
    when(() => mockRepo.getBody('sony_a6700')).thenAnswer((_) async => body);

    final navPaths = await TestFixtures.loadNavPaths('sony_a6700');
    when(() => mockRepo.getNavPath('sony_a6700', any()))
        .thenAnswer((inv) async =>
            navPaths.firstWhereOrNull((n) => n.settingId == inv.positionalArguments[1]));
  });

  test('AF mode FR → breadcrumb en français', () async {
    final result = await useCase.execute(
      bodyId: 'sony_a6700',
      settingId: 'af_mode',
      value: 'af-c',
      firmwareLanguage: 'fr',
      appLanguage: 'fr',
      l10n: mockL10n,
    );

    expect(result.header, contains('Mode mise au point'));
    expect(result.header, contains('AF-C'));
    expect(result.isIncomplete, isFalse);
    expect(result.sections.length, greaterThanOrEqualTo(1));
  });

  test('AF mode DE → breadcrumb en allemand', () async {
    final result = await useCase.execute(
      bodyId: 'sony_a6700',
      settingId: 'af_mode',
      value: 'af-c',
      firmwareLanguage: 'de',
      appLanguage: 'fr',
      l10n: mockL10n,
    );

    expect(result.header, contains('Fokusmodus'));
  });

  test('aperture → dial access seulement, pas de menu path', () async {
    final result = await useCase.execute(
      bodyId: 'sony_a6700',
      settingId: 'aperture',
      value: '2.8',
      firmwareLanguage: 'fr',
      appLanguage: 'fr',
      l10n: mockL10n,
    );

    expect(result.sections.whereType<NavSectionFullMenu>(), isEmpty);
    expect(result.sections.whereType<NavSectionQuick>(), hasLength(1));
  });

  test('setting inconnu → isIncomplete', () async {
    when(() => mockRepo.getNavPath('sony_a6700', 'unknown'))
        .thenAnswer((_) async => null);

    final result = await useCase.execute(
      bodyId: 'sony_a6700',
      settingId: 'unknown',
      value: 'x',
      firmwareLanguage: 'fr',
      appLanguage: 'fr',
      l10n: mockL10n,
    );

    expect(result.isIncomplete, isTrue);
    expect(result.sections, isEmpty);
  });

  test('langue absente → fallback EN', () async {
    final result = await useCase.execute(
      bodyId: 'sony_a6700',
      settingId: 'af_mode',
      value: 'af-c',
      firmwareLanguage: 'xx', // Langue inexistante
      appLanguage: 'fr',
      l10n: mockL10n,
    );

    // Doit fallback vers l'anglais, pas crasher
    expect(result.header, contains('Focus Mode')); // Label EN
    expect(result.isIncomplete, isFalse);
  });
}
```

### 5.7. Data mappers

```dart
// test/shared/data/mappers/body_mapper_test.dart

void main() {
  group('BodyMapper', () {
    test('toEntity mappe correctement un body complet', () async {
      final json = await TestFixtures.loadJson('bodies/sony_a6700.json');
      final model = BodyModel.fromJson(json);
      final entity = BodyMapper.toEntity(model);

      expect(entity.id, 'sony_a6700');
      expect(entity.cropFactor, 1.5);
      expect(entity.sensorSize, SensorSize.apsC);
      expect(entity.spec.sensor.isoRange.min, 100);
      expect(entity.spec.sensor.isoRange.max, 32000);
      expect(entity.spec.autofocus.hasEyeAf, isTrue);
    });

    test('gère les champs optionnels manquants', () async {
      final json = await TestFixtures.loadJson('bodies/sony_a6700_minimal.json');
      final model = BodyModel.fromJson(json);
      final entity = BodyMapper.toEntity(model);

      // Les champs optionnels ont des valeurs par défaut
      expect(entity.spec.stabilization.hasIbis, isFalse); // Default
    });
  });
}
```

---

## 6. Tests unitaires — Couche Data

### 6.1. JsonDataSource

```dart
// test/shared/data/data_sources/local/json_data_source_test.dart

void main() {
  late JsonDataSource dataSource;
  late MockFileManager mockFm;

  setUp(() {
    mockFm = MockFileManager();
    dataSource = JsonDataSource(fileManager: mockFm);
  });

  test('readBodyJson retourne le JSON parsé', () async {
    when(() => mockFm.readJson('packs/sony_a6700/body.json'))
        .thenAnswer((_) async => {'id': 'sony_a6700', 'name': 'Sony A6700'});

    final result = await dataSource.readBodyJson('sony_a6700');
    expect(result['id'], 'sony_a6700');
  });

  test('throw quand le fichier n\'existe pas', () async {
    when(() => mockFm.readJson(any()))
        .thenThrow(const FileSystemException('Not found'));

    expect(
      () => dataSource.readBodyJson('nonexistent'),
      throwsA(isA<FileSystemException>()),
    );
  });
}
```

### 6.2. CameraDataCache

```dart
// test/shared/data/data_sources/local/camera_data_cache_test.dart

void main() {
  group('CameraDataCache', () {
    test('charge tous les fichiers en parallèle', () async {
      final cache = CameraDataCache();
      final mockFm = MockFileManager();

      // Setup mocks pour chaque fichier
      when(() => mockFm.readJson('packs/sony_a6700/body.json'))
          .thenAnswer((_) async => await TestFixtures.loadJson('bodies/sony_a6700.json'));
      when(() => mockFm.readJson('packs/sony_a6700/menu_tree.json'))
          .thenAnswer((_) async => await TestFixtures.loadJson('menu_trees/sony_a6700_menu_tree.json'));
      // ... etc

      await cache.load('sony_a6700', ['sigma_18-50_f2.8'], mockFm);

      expect(cache.isLoaded, isTrue);
      expect(cache.body.id, 'sony_a6700');
      expect(cache.getLens('sigma_18-50_f2.8').displayName, contains('Sigma'));
    });

    test('clear libère toutes les données', () async {
      final cache = CameraDataCache();
      // ... load data ...

      cache.clear();
      expect(cache.isLoaded, isFalse);
    });
  });
}
```

---

## 7. Widget tests — Couche Presentation

### 7.1. SceneInputScreen

```dart
// test/features/scene_input/presentation/screens/scene_input_screen_test.dart

void main() {
  group('SceneInputScreen', () {
    testWidgets('bouton Calculer disabled tant que Niveau 1 incomplet', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SceneInputScreen(),
        overrides: defaultOverrides(body: MockBodies.sonyA6700()),
      ));

      // Vérifier que le bouton est disabled
      final button = find.widgetWithText(FilledButton, 'Calculer mes réglages');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('bouton Calculer activé après 4 sélections', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SceneInputScreen(),
        overrides: defaultOverrides(body: MockBodies.sonyA6700()),
      ));

      // Tap les 4 chips obligatoires
      await tester.tap(find.text('Photo'));
      await tester.tap(find.text('Ext. Jour'));
      await tester.tap(find.text('Portrait'));
      await tester.tap(find.text('Flou arrière-plan'));
      await tester.pump();

      final button = find.widgetWithText(FilledButton, 'Calculer mes réglages');
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });

    testWidgets('expand Niveau 2 affiche les sections', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SceneInputScreen(),
        overrides: defaultOverrides(body: MockBodies.sonyA6700()),
      ));

      // Le Niveau 2 est caché
      expect(find.text('Conditions de lumière'), findsNothing);

      // Tap "Affiner davantage"
      await tester.tap(find.text('Affiner davantage'));
      await tester.pumpAndSettle();

      // Le Niveau 2 est visible
      expect(find.text('Conditions de lumière'), findsOneWidget);
    });

    testWidgets('Eye-AF grisé si boîtier sans Eye-AF', (tester) async {
      final bodyNoEyeAf = MockBodies.sonyA6700(hasEyeAf: false);
      await tester.pumpWidget(createTestWidget(
        const SceneInputScreen(),
        overrides: defaultOverrides(body: bodyNoEyeAf),
      ));

      // Expand jusqu'au Niveau 3
      await tester.tap(find.text('Affiner davantage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paramètres avancés'));
      await tester.pumpAndSettle();

      // Le chip Eye-AF est disabled
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Eye-AF'),
      );
      expect(chip.onSelected, isNull);
    });
  });
}
```

### 7.2. ResultsScreen

```dart
// test/features/results/presentation/screens/results_screen_test.dart

void main() {
  group('ResultsScreen', () {
    final mockResult = SettingsResult(
      settings: [
        SettingRecommendation(settingId: 'exposure_mode', value: 'M', valueDisplay: 'M',
            explanationShort: 'Mode manuel.', explanationDetail: '', isOverride: false, isCompromised: false, alternatives: []),
        SettingRecommendation(settingId: 'aperture', value: FStop(2.8), valueDisplay: 'f/2.8',
            explanationShort: 'Ouverture max.', explanationDetail: '', isOverride: false, isCompromised: false, alternatives: []),
        SettingRecommendation(settingId: 'shutter_speed', value: ShutterSpeed(1/250), valueDisplay: '1/250s',
            explanationShort: 'Vitesse sûre.', explanationDetail: '', isOverride: false, isCompromised: false, alternatives: []),
        SettingRecommendation(settingId: 'iso', value: 200, valueDisplay: 'ISO 200',
            explanationShort: 'Bruit inexistant.', explanationDetail: '', isOverride: false, isCompromised: false, alternatives: []),
      ],
      compromises: [],
      sceneSummary: 'Portrait · Ext Jour · Bokeh',
      confidence: Confidence.high,
    );

    testWidgets('affiche le résumé d\'exposition', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ResultsScreen(),
        overrides: [
          settingsResultProvider.overrideWith((_) async => mockResult),
          currentBodyProvider.overrideWith((_) => MockBodies.sonyA6700()),
          currentLensProvider.overrideWith((_) => MockLenses.sigma1850f28()),
          submittedSceneProvider.overrideWith((_) => MockScenes.portraitOutdoorBokeh()),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('f/2.8'), findsWidgets);
      expect(find.text('1/250s'), findsWidgets);
      expect(find.text('ISO 200'), findsWidgets);
    });

    testWidgets('affiche le bandeau compromis si présent', (tester) async {
      final resultWithCompromise = mockResult.copyWith(
        compromises: [
          Compromise(
            type: CompromiseType.noise, severity: CompromiseSeverity.warning,
            message: 'ISO élevé', affectedSettings: ['iso'], suggestion: 'Trépied',
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(
        const ResultsScreen(),
        overrides: [
          settingsResultProvider.overrideWith((_) async => resultWithCompromise),
          // ...
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('ISO élevé'), findsOneWidget);
    });

    testWidgets('masque comp expo = 0 et drive = single', (tester) async {
      final resultWithDefaults = mockResult.copyWith(settings: [
        ...mockResult.settings,
        SettingRecommendation(settingId: 'exposure_compensation', value: 0.0, valueDisplay: '0.0 EV',
            explanationShort: '', explanationDetail: '', isOverride: false, isCompromised: false, alternatives: []),
        SettingRecommendation(settingId: 'drive_mode', value: 'single', valueDisplay: 'Single',
            explanationShort: '', explanationDetail: '', isOverride: false, isCompromised: false, alternatives: []),
      ]);

      await tester.pumpWidget(createTestWidget(
        const ResultsScreen(),
        overrides: [settingsResultProvider.overrideWith((_) async => resultWithDefaults), /*...*/],
      ));
      await tester.pumpAndSettle();

      expect(find.text('0.0 EV'), findsNothing);
      expect(find.text('Single'), findsNothing);
    });
  });
}
```

---

## 8. Tests d'intégration (E2E)

### 8.1. Flow principal complet

```dart
// integration_test/shoot_flow_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flow complet : Scène → Résultats → Menu Nav', (tester) async {
    // Pré-condition : gear configuré, data pack chargé
    await tester.pumpWidget(const ProviderScope(
      overrides: [/* mock repos avec fixtures */],
      child: App(),
    ));
    await tester.pumpAndSettle();

    // 1. Home → Nouveau shoot
    await tester.tap(find.text('Nouveau shoot'));
    await tester.pumpAndSettle();

    // 2. Scene Input : sélection Niveau 1
    await tester.tap(find.text('Photo'));
    await tester.tap(find.text('Ext. Jour'));
    await tester.tap(find.text('Portrait'));
    await tester.tap(find.text('Flou arrière-plan'));
    await tester.pump();

    // 3. Calculer
    await tester.tap(find.text('Calculer mes réglages'));
    await tester.pumpAndSettle();

    // 4. Résultats affichés
    expect(find.text('f/2.8'), findsWidgets);
    expect(find.textContaining('ISO'), findsWidgets);

    // 5. Tap sur un réglage
    await tester.tap(find.text('Ouverture').first);
    await tester.pumpAndSettle();

    // 6. Détail du réglage
    expect(find.textContaining('flou'), findsWidgets);

    // 7. Tap "Où régler"
    await tester.tap(find.textContaining('Où régler'));
    await tester.pumpAndSettle();

    // 8. Menu Navigation affiché
    expect(find.textContaining('Méthode rapide'), findsOneWidget);
    // Ou "Via le menu" selon le réglage
  });
}
```

---

## 9. Snapshot testing (Régression du moteur)

Le moteur doit être **déterministe** — le même input donne toujours le même output. On vérifie ça avec des snapshot tests.

```dart
// test/features/settings_engine/domain/engine/snapshot_test.dart

void main() {
  group('Engine snapshot tests', () {
    final scenarios = {
      'portrait_outdoor_bokeh': MockScenes.portraitOutdoorBokeh(),
      'landscape_overcast_sharpness': MockScenes.landscapeOvercast(),
      'sport_indoor_freeze': MockScenes.sportIndoorDark(),
      'astro_tripod': MockScenes.astroTripod(),
      'street_golden_hour': MockScenes.streetGoldenHour(),
      'portrait_night_lowlight': MockScenes.portraitNight(),
      'macro_outdoor': MockScenes.macroOutdoor(),
      'video_portrait_indoor': MockScenes.videoPortraitIndoor(),
    };

    final body = MockBodies.sonyA6700();
    final lens = MockLenses.sigma1850f28();

    for (final entry in scenarios.entries) {
      test('snapshot: ${entry.key}', () async {
        final engine = CalculateSettings(gearRepo: MockGearRepo(body, lens));
        final result = await engine.execute(
          GearProfile(bodyId: body.id, lensIds: [lens.id], activeLensId: lens.id, firmwareLanguage: 'en'),
          entry.value,
        );

        // Sérialiser le résultat
        final snapshot = {
          'settings': result.settings.map((s) => {
            'id': s.settingId,
            'value': s.value.toString(),
            'display': s.valueDisplay,
          }).toList(),
          'compromises': result.compromises.map((c) => {
            'type': c.type.name,
            'severity': c.severity.name,
          }).toList(),
          'confidence': result.confidence.name,
        };

        // Comparer avec le snapshot enregistré
        expect(snapshot, matchesGoldenJson('engine_snapshots/${entry.key}.json'));
      });
    }
  });
}
```

**Workflow** :
1. Première exécution : les snapshots sont créés
2. Exécutions suivantes : les résultats sont comparés aux snapshots
3. Si un résultat change → le test échoue
4. Si le changement est voulu (ex: amélioration du moteur) → mettre à jour les snapshots avec `--update-goldens`

---

## 10. CI — GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.x'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Run unit & widget tests
        run: flutter test --coverage --reporter=github

      - name: Check import rules
        run: bash ci/check_imports.sh

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

### 10.1. Quand les tests tournent

| Événement | Tests exécutés |
|-----------|---------------|
| Push sur `develop` | Unit + widget + analyze + import check |
| PR vers `main` | Unit + widget + analyze + import check + snapshots |
| Merge sur `main` | Tout + integration tests (émulateur) |
| Release tag | Tout + build iOS/Android |

### 10.2. Seuils de couverture

| Couche | Seuil minimum | Cible |
|--------|--------------|-------|
| `domain/engine/` | **95%** | Le moteur est critique. Chaque branche doit être testée. |
| `domain/use_cases/` | **90%** | |
| `domain/value_objects/` | **95%** | |
| `data/mappers/` | **90%** | |
| `data/data_sources/` | **80%** | |
| `presentation/providers/` | **80%** | |
| `presentation/screens/` | **60%** | Les widget tests sont plus lents à écrire. |
| **Global** | **80%** | |

---

## 11. Inventaire consolidé — Tous les tests

Consolidation de tous les scénarios de test définis dans les skills précédents.

### 11.1. Settings Engine (skill 06) — 10 scénarios

| ID | Nom | Ce qu'on vérifie |
|----|-----|-----------------|
| SE-01 | Portrait sunny bokeh | f/2.8, ISO bas, ouverture max |
| SE-02 | Paysage couvert sharpness | f/8 (sweet spot), ISO modéré |
| SE-03 | Sport indoor freeze | Vitesse ≥ 1/500s, ISO monte, ouverture max |
| SE-04 | Astro tripod | Règle NPF (~12s), ISO poussé, MF |
| SE-05 | Street golden hour | EV golden hour correct |
| SE-06 | Portrait nuit low-light | Compromis bruit détecté |
| SE-07 | Macro outdoor | f/8-f/11, vitesse ≥ 1/250s |
| SE-08 | Contraintes impossibles | Compromis critical |
| SE-09 | Filé plein soleil | Warning filtre ND |
| SE-10 | Vidéo portrait | Règle du double (1/50s) |

### 11.2. Error Handling (skill 15) — 15 scénarios

| ID | Nom | Ce qu'on vérifie |
|----|-----|-----------------|
| EH-01 | Download sans réseau | Écran "Connexion requise" |
| EH-02 | Download interrompu | Resume reprend au bon fichier |
| EH-03 | CDN 500 | Retry × 3 puis message serveur |
| EH-04 | JSON corrompu | Message corruption + re-download |
| EH-05 | Checksum invalide | Détecté, re-download |
| EH-06 | Label manquant | Fallback EN affiché |
| EH-07 | NavPath manquant | Résultat sans bouton menu |
| EH-08 | Objectif manquant | Message + option re-download |
| EH-09 | ISO impossible | Compromis critical + suggestion |
| EH-10 | Astro handheld | Compromis critical + trépied |
| EH-11 | Surexposition filé | Warning filtre ND |
| EH-12 | Eye-AF absent | Auto-switch + info |
| EH-13 | Macro impossible | Warning distance MAP |
| EH-14 | Stockage plein | Message espace insuffisant |
| EH-15 | Crash inattendu | Catch-all → ErrorDisplay |

### 11.3. Scene Input (skill 17) — 13 scénarios

| ID | Nom | Ce qu'on vérifie |
|----|-----|-----------------|
| SI-01 | 4 taps → bouton actif | Validation Niveau 1 |
| SI-02 | 3 taps → bouton disabled | Validation incomplète |
| SI-03 | Expand Niveau 2 | Sections visibles |
| SI-04 | Collapse Niveau 2 | Badge compteur |
| SI-05 | Astro → suggestion trépied | Pré-sélection intelligente |
| SI-06 | Modifier suggestion | Style confirmé |
| SI-07 | Contrainte ISO → slider | Borné par specs body |
| SI-08 | Eye-AF grisé | Chip disabled + tooltip |
| SI-09 | Retour depuis résultats | Draft conservé |
| SI-10 | Nouveau shoot | Draft réinitialisé |
| SI-11 | Réordonnancement contextuel | Mood pertinent en premier |
| SI-12 | Warning astro handheld | Bannière visible |
| SI-13 | Warning macro non-macro | Bannière visible |

### 11.4. Results Output (skill 18) — 19 scénarios

| ID | Nom | Ce qu'on vérifie |
|----|-----|-----------------|
| RO-01 | Résultat normal | Summary card avec 4 valeurs |
| RO-02 | Compromis warning | Bandeau orange |
| RO-03 | Compromis critical | Bandeau rouge, badge low confidence |
| RO-04 | Pas de comp expo | Setting masqué |
| RO-05 | Comp expo non-zéro | Setting visible |
| RO-06 | Tap réglage | Navigation vers détail |
| RO-07 | Copier presse-papier | Texte copié, snackbar |
| RO-08 | Setting overridé | Badge "Valeur choisie" |
| RO-09 to RO-16 | Explications correctes | Templates i18n par réglage |
| RO-17 to RO-19 | Alternatives cascade | ISO/vitesse changent en cascade |

### 11.5. Menu Navigation (skill 19) — 15 scénarios

| ID | Nom | Ce qu'on vérifie |
|----|-----|-----------------|
| MN-01 | AF mode Sony FR | Breadcrumb français |
| MN-02 | Ouverture Sony FR | Molette seulement, pas de menu |
| MN-03 | AF mode Sony DE | Breadcrumb allemand |
| MN-04 | AF mode Canon FR | Terminologie Canon ("Servo") |
| MN-05 | AF mode Canon EN | "Servo AF" |
| MN-06 | AF mode Sony ZH-CN | Chinois simplifié |
| MN-07 | Setting inconnu | isIncomplete + notice |
| MN-08 | Langue absente | Fallback EN |
| MN-09 | 3 méthodes d'accès | Ordre dial → Fn → menu |
| MN-10 | Tip avec chemin lié | Chemin en firmware lang |
| MN-11 | UI 3 sections | Cards dans l'ordre |
| MN-12 | UI molette seule | Une seule card |
| MN-13 | UI incomplet | Notice + bouton Signaler |
| MN-14 | Dernière étape highlight | Fond coloré différent |
| MN-15 | Cross-brand 4×2 | 8 combinaisons terminologie exacte |

### Total : **72 scénarios de test** documentés dans les skills.

---

## 12. Priorité d'implémentation des tests

| Phase | Tests | Pourquoi en premier |
|-------|-------|-------------------|
| **Phase 1** | Value objects + ExposureCalculator + tous les resolvers | Le moteur est le cœur. Si les maths sont fausses, rien ne fonctionne. |
| **Phase 2** | CalculateSettings intégration + snapshots | Vérifie le pipeline complet du moteur. |
| **Phase 3** | ResolveMenuPath + label resolution | Le killer feature. Les chemins de menu doivent être exacts. |
| **Phase 4** | Data mappers + JSON parsing | Les données doivent être parsées correctement. |
| **Phase 5** | Widget tests (SceneInput, Results, MenuNav) | L'UI affiche correctement les données. |
| **Phase 6** | Download + error handling | Les cas d'erreur réseau et données. |
| **Phase 7** | Integration tests E2E | Le flow complet fonctionne. |

---

*Ce document est la référence pour toute l'implémentation des tests. Les 72 scénarios consolidés sont le contrat de qualité minimum avant le lancement du MVP.*
