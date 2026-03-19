# Module & Feature Architecture — ShootHelper

> **Skill 10/22** · Modularité par feature, contracts inter-modules, extensibilité
> Version 1.0 · Mars 2026
> Réf : 09_APP_ARCHITECTURE.md, 02_USER_FLOWS.md

---

## 1. Pourquoi ce skill existe

Le skill 09 définit les **couches horizontales** (Domain / Data / Presentation). Ce skill 10 définit les **tranches verticales** — les features.

```
         Skill 09 (couches)          Skill 10 (features)
         ──────────────────          ───────────────────

         ┌──────────────┐            ┌────┐┌────┐┌────┐┌────┐
         │ Presentation │            │ On ││Scen││Resu││Menu│
         ├──────────────┤     →      │ bo ││ e  ││ lt ││Nav │
         │   Domain     │            │ ar ││ In ││ s  ││    │
         ├──────────────┤            │ di ││ pu ││    ││    │
         │    Data      │            │ ng ││ t  ││    ││    │
         └──────────────┘            └────┘└────┘└────┘└────┘

     Chaque tranche verticale       Chaque feature traverse
     est une couche technique.      les 3 couches.
```

Le but : quand tu ajoutes la feature "Historique & favoris" (V2), tu crées un **nouveau dossier** avec ses propres entities, use cases, repositories, screens et providers. Tu ne touches pas aux dossiers des features existantes.

---

## 2. Inventaire des features MVP

Chaque feature correspond à un périmètre fonctionnel autonome, traçable aux User Flows (skill 02).

| Feature ID | Nom | Flows couverts | Autonomie |
|-----------|-----|---------------|-----------|
| `onboarding` | Onboarding & Gear Setup | F1 | Complètement autonome |
| `data_pack` | Téléchargement & MAJ Data Packs | F2, F8 | Autonome (déclenché par onboarding ou settings) |
| `scene_input` | Description de scène | F3 (partie input) | Autonome (produit un SceneInput) |
| `settings_engine` | Moteur de calcul | F3 (partie calcul) | Autonome (consomme SceneInput + Gear, produit SettingsResult) |
| `results` | Affichage résultats & détails | F3 (partie output), F4 | Consomme SettingsResult |
| `menu_nav` | Navigation menu appareil | F5 | Consomme un SettingRecommendation + Body |
| `gear` | Gestion du matériel | F6, F7 | Autonome (CRUD gear profile) |
| `shared` | Composants partagés | Tous | Widgets et entités utilisés par plusieurs features |

**8 modules.** Chacun a sa propre boîte dans l'arborescence.

---

## 3. Structure de dossiers — Feature-first

Le skill 09 présentait une structure layer-first (tous les entities ensemble, tous les screens ensemble). On la **restructure en feature-first** pour la modularité.

```
lib/
├── main.dart
├── app.dart
│
├── core/                                    # ===== PARTAGÉ GLOBAL =====
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── photography_constants.dart       # Tables EV, f-stops, vitesses standard
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── extensions/
│   │   └── string_extensions.dart
│   ├── utils/
│   │   ├── exposure_math.dart
│   │   └── json_utils.dart
│   └── router/
│       └── app_router.dart                  # GoRouter central (assemble les routes des features)
│
├── shared/                                  # ===== PARTAGÉ ENTRE FEATURES =====
│   ├── domain/
│   │   ├── entities/                        # Entités utilisées par 2+ features
│   │   │   ├── body.dart
│   │   │   ├── body_spec.dart
│   │   │   ├── lens.dart
│   │   │   ├── lens_spec.dart
│   │   │   ├── menu_tree.dart
│   │   │   ├── menu_item.dart
│   │   │   ├── controls.dart
│   │   │   ├── setting_def.dart
│   │   │   ├── setting_nav_path.dart
│   │   │   └── gear_profile.dart
│   │   ├── value_objects/
│   │   │   ├── f_stop.dart
│   │   │   ├── shutter_speed.dart
│   │   │   ├── iso_value.dart
│   │   │   └── ev_value.dart
│   │   └── repositories/                   # Interfaces partagées
│   │       ├── gear_repository.dart
│   │       └── data_pack_repository.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── body_model.dart
│   │   │   ├── lens_model.dart
│   │   │   ├── menu_tree_model.dart
│   │   │   ├── nav_path_model.dart
│   │   │   └── manifest_model.dart
│   │   ├── mappers/
│   │   │   ├── body_mapper.dart
│   │   │   ├── lens_mapper.dart
│   │   │   └── menu_tree_mapper.dart
│   │   ├── data_sources/
│   │   │   ├── local/
│   │   │   │   ├── json_data_source.dart
│   │   │   │   ├── preferences_source.dart
│   │   │   │   └── file_manager.dart
│   │   │   └── remote/
│   │   │       └── data_pack_api.dart
│   │   └── repositories/
│   │       ├── gear_repository_impl.dart
│   │       └── data_pack_repository_impl.dart
│   ├── presentation/
│   │   ├── providers/
│   │   │   └── repository_providers.dart    # Providers des repos partagés
│   │   ├── widgets/                         # Widgets réutilisables
│   │   │   ├── shoot_chip.dart
│   │   │   ├── section_header.dart
│   │   │   ├── loading_indicator.dart
│   │   │   └── error_display.dart
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       └── app_colors.dart
│   └── l10n/
│       ├── app_en.arb
│       └── app_fr.arb
│
├── features/                                # ===== FEATURES AUTONOMES =====
│   │
│   ├── onboarding/                          # ── Feature: Onboarding ──
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── get_supported_bodies.dart
│   │   │       ├── get_compatible_lenses.dart
│   │   │       └── complete_onboarding.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── onboarding_providers.dart
│   │   │   ├── screens/
│   │   │   │   ├── welcome_screen.dart
│   │   │   │   ├── body_selection_screen.dart
│   │   │   │   ├── lens_selection_screen.dart
│   │   │   │   ├── firmware_language_screen.dart
│   │   │   │   └── recap_download_screen.dart
│   │   │   └── widgets/
│   │   │       ├── body_card.dart
│   │   │       └── lens_card.dart
│   │   └── onboarding_routes.dart           # Routes GoRouter de cette feature
│   │
│   ├── data_pack/                           # ── Feature: Data Pack Download ──
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── download_data_pack.dart
│   │   │       ├── check_data_pack_update.dart
│   │   │       └── apply_data_pack_update.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── data_pack_providers.dart
│   │   │   ├── screens/
│   │   │   │   ├── download_screen.dart
│   │   │   │   └── update_screen.dart
│   │   │   └── widgets/
│   │   │       └── download_progress.dart
│   │   └── data_pack_routes.dart
│   │
│   ├── scene_input/                         # ── Feature: Scene Input ──
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── scene_input.dart         # Entité propre à cette feature
│   │   │   └── use_cases/
│   │   │       └── validate_scene_input.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── scene_input_providers.dart
│   │   │   ├── screens/
│   │   │   │   └── scene_input_screen.dart
│   │   │   └── widgets/
│   │   │       ├── environment_selector.dart
│   │   │       ├── subject_selector.dart
│   │   │       ├── intention_selector.dart
│   │   │       ├── light_condition_selector.dart
│   │   │       ├── motion_selector.dart
│   │   │       ├── support_selector.dart
│   │   │       └── constraint_slider.dart
│   │   └── scene_input_routes.dart
│   │
│   ├── settings_engine/                     # ── Feature: Settings Engine ──
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── settings_result.dart
│   │   │   │   ├── setting_recommendation.dart
│   │   │   │   ├── compromise.dart
│   │   │   │   └── alternative.dart
│   │   │   ├── engine/
│   │   │   │   ├── settings_engine.dart          # Orchestrateur
│   │   │   │   ├── engine_context.dart           # Input structuré du moteur
│   │   │   │   ├── setting_resolver.dart         # Interface resolver
│   │   │   │   ├── resolvers/
│   │   │   │   │   ├── exposure_resolver.dart    # Triangle d'exposition
│   │   │   │   │   ├── af_mode_resolver.dart
│   │   │   │   │   ├── af_area_resolver.dart
│   │   │   │   │   ├── metering_resolver.dart
│   │   │   │   │   ├── wb_resolver.dart
│   │   │   │   │   ├── drive_resolver.dart
│   │   │   │   │   ├── stabilization_resolver.dart
│   │   │   │   │   ├── file_format_resolver.dart
│   │   │   │   │   └── exposure_mode_resolver.dart
│   │   │   │   ├── compromise_detector.dart
│   │   │   │   ├── alternative_generator.dart
│   │   │   │   └── astro_calculator.dart
│   │   │   └── use_cases/
│   │   │       └── calculate_settings.dart
│   │   └── presentation/
│   │       └── providers/
│   │           └── engine_providers.dart
│   │   # Pas de screens — le moteur est consommé par la feature results
│   │   # Pas de routes — pas d'écran propre
│   │
│   ├── results/                             # ── Feature: Results ──
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       └── explain_setting.dart     # Génère les explications
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── results_providers.dart
│   │   │   ├── screens/
│   │   │   │   ├── results_screen.dart
│   │   │   │   └── setting_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── exposure_summary_card.dart
│   │   │       ├── setting_row.dart
│   │   │       ├── compromise_banner.dart
│   │   │       ├── alternative_card.dart
│   │   │       └── explanation_section.dart
│   │   └── results_routes.dart
│   │
│   ├── menu_nav/                            # ── Feature: Menu Navigation ──
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── resolve_menu_path.dart
│   │   │       └── resolve_firmware_label.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── menu_nav_providers.dart
│   │   │   ├── screens/
│   │   │   │   └── menu_navigation_screen.dart
│   │   │   └── widgets/
│   │   │       ├── menu_breadcrumb.dart
│   │   │       ├── nav_step_card.dart
│   │   │       ├── quick_method_card.dart
│   │   │       └── tip_card.dart
│   │   └── menu_nav_routes.dart
│   │
│   └── gear/                                # ── Feature: Gear Management ──
│       ├── domain/
│       │   └── use_cases/
│       │       ├── add_lens.dart
│       │       ├── remove_lens.dart
│       │       ├── change_body.dart
│       │       └── switch_firmware_language.dart
│       ├── presentation/
│       │   ├── providers/
│       │   │   └── gear_providers.dart
│       │   ├── screens/
│       │   │   └── app_settings_screen.dart
│       │   └── widgets/
│       │       ├── gear_summary_card.dart
│       │       ├── lens_list_tile.dart
│       │       └── data_usage_card.dart
│       └── gear_routes.dart
│
└── generated/                               # Code généré (freezed, json_serializable, l10n)
```

---

## 4. Règle de placement : où va quoi ?

La question "est-ce que ce fichier va dans `shared/` ou dans `features/X/` ?" revient constamment. Voici la règle :

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║  Si l'entité/classe est utilisée par 2+ features → shared/  ║
║  Si l'entité/classe est utilisée par 1 seule feature → features/X/ ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### Exemples concrets

| Classe | Utilisée par | Placement |
|--------|-------------|-----------|
| `Body` entity | onboarding, gear, settings_engine, menu_nav, results | `shared/domain/entities/` |
| `Lens` entity | onboarding, gear, settings_engine | `shared/domain/entities/` |
| `GearProfile` | onboarding, gear, scene_input, settings_engine | `shared/domain/entities/` |
| `GearRepository` interface | onboarding, gear, settings_engine | `shared/domain/repositories/` |
| `SceneInput` entity | scene_input (crée), settings_engine (consomme) | `shared/domain/entities/` |
| `SettingsResult` entity | settings_engine (produit), results (affiche) | `features/settings_engine/domain/entities/` → **promu** `shared/` car 2 features |
| `SettingRecommendation` | settings_engine, results, menu_nav | `shared/domain/entities/` |
| `Compromise` | settings_engine, results | `shared/domain/entities/` |
| `ExposureResolver` | settings_engine uniquement | `features/settings_engine/domain/engine/resolvers/` |
| `AfModeResolver` | settings_engine uniquement | `features/settings_engine/domain/engine/resolvers/` |
| `MenuBreadcrumb` widget | menu_nav uniquement | `features/menu_nav/presentation/widgets/` |
| `ShootChip` widget | scene_input, onboarding | `shared/presentation/widgets/` |
| `SettingRow` widget | results uniquement | `features/results/presentation/widgets/` |
| `DownloadProgress` widget | data_pack uniquement | `features/data_pack/presentation/widgets/` |

### Migration progressive

Au début du dev, tout peut vivre dans `shared/`. Au fur et à mesure que tu identifies des entités spécifiques à une feature, tu les déplaces. L'important c'est la direction : **du partagé vers le spécifique**, pas l'inverse.

Si un jour un fichier dans `features/X/` est importé par `features/Y/`, il y a deux options :
1. Le promouvoir vers `shared/` (si c'est un concept fondamental)
2. Y a un problème de couplage (si c'est un détail d'implémentation)

---

## 5. Contracts entre features

Les features ne s'importent **jamais directement** entre elles. Elles communiquent via des **contracts** qui passent par `shared/` ou par Riverpod.

### 5.1. Diagramme de dépendances

```
                        ┌──────────┐
                        │  shared/ │
                        │          │
                        │ Entities │
                        │ Repos    │
                        │ Widgets  │
                        └────┬─────┘
                             │
              ┌──────────────┼──────────────────┐
              │              │                  │
     ┌────────▼───┐  ┌──────▼──────┐  ┌────────▼────┐
     │ onboarding │  │ scene_input │  │    gear     │
     └────────┬───┘  └──────┬──────┘  └─────────────┘
              │              │
              │              │ SceneInput (via provider)
              │              │
              │       ┌──────▼──────────┐
              │       │ settings_engine  │
              │       └──────┬──────────┘
              │              │
              │              │ SettingsResult (via provider)
              │              │
              │       ┌──────▼──────┐
              │       │   results   │
              │       └──────┬──────┘
              │              │
              │              │ SettingRecommendation + Body (via provider)
              │              │
              │       ┌──────▼──────┐
              │       │  menu_nav   │
              │       └─────────────┘
              │
              │ GearProfile (via provider)
              │
       ┌──────▼──────┐
       │  data_pack   │
       └──────────────┘


RÈGLE : Les flèches passent TOUJOURS par shared/ ou par un Riverpod provider.
        Jamais d'import direct features/X → features/Y.
```

### 5.2. Comment les données circulent

Le flow principal (Scène → Réglages → Navigation menu) traverse 4 features. Voici comment les données passent d'une feature à l'autre **sans couplage direct**.

```dart
// ─── SHARED : le provider "pont" entre scene_input et settings_engine ───

// shared/presentation/providers/current_scene_provider.dart
// Ce provider est écrit par scene_input et lu par settings_engine
final currentSceneProvider = StateProvider<SceneInput?>((ref) => null);


// ─── FEATURE scene_input : écrit le SceneInput ───

// features/scene_input/presentation/providers/scene_input_providers.dart
class SceneInputNotifier extends Notifier<SceneInput> {
  // ...

  void submitScene() {
    // Valide et publie dans le provider partagé
    ref.read(currentSceneProvider.notifier).state = state;
    // La navigation vers l'écran résultats est gérée par le router
  }
}


// ─── FEATURE settings_engine : lit le SceneInput, produit SettingsResult ───

// features/settings_engine/presentation/providers/engine_providers.dart
final settingsResultProvider = FutureProvider<SettingsResult?>((ref) async {
  final scene = ref.watch(currentSceneProvider);
  if (scene == null) return null;

  final gear = ref.watch(currentGearProvider);
  if (gear == null) return null;

  final engine = ref.read(calculateSettingsProvider);
  return engine.execute(gear, scene);
});


// ─── FEATURE results : lit le SettingsResult ───

// features/results/presentation/screens/results_screen.dart
class ResultsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(settingsResultProvider);
    return resultAsync.when(
      data: (result) => _buildResults(result),
      loading: () => const LoadingIndicator(),
      error: (e, s) => ErrorDisplay(error: e),
    );
  }
}


// ─── FEATURE menu_nav : lit un SettingRecommendation + Body ───

// Le router passe le setting_id en paramètre de route
// Le screen récupère les données via les providers partagés

// features/menu_nav/presentation/screens/menu_navigation_screen.dart
class MenuNavigationScreen extends ConsumerWidget {
  final String settingId;
  const MenuNavigationScreen({required this.settingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(settingsResultProvider).value;
    final setting = result?.settings.firstWhere((s) => s.settingId == settingId);
    final body = ref.watch(currentBodyProvider);
    final fwLang = ref.watch(firmwareLanguageProvider);

    if (setting == null || body == null) return const ErrorDisplay();

    final menuNav = ref.watch(menuNavProvider(
      MenuNavParams(bodyId: body.id, settingId: settingId, value: setting.value, fwLang: fwLang),
    ));

    return menuNav.when(/* ... */);
  }
}
```

### 5.3. Les providers "ponts"

Les providers qui servent de contrat entre features vivent dans `shared/presentation/providers/` :

```
shared/presentation/providers/
├── repository_providers.dart        # Instancie les repos partagés
├── current_gear_provider.dart       # GearProfile actuel (écrit par onboarding/gear, lu par tous)
├── current_body_provider.dart       # Body chargé (dérivé du gear)
├── current_lens_provider.dart       # Lens actif (dérivé du gear)
├── firmware_language_provider.dart   # Langue firmware sélectionnée
└── current_scene_provider.dart      # SceneInput en cours (écrit par scene_input, lu par engine)
```

**Règle** : un provider "pont" ne contient PAS de logique. C'est un `StateProvider` ou un `Provider` qui dérive d'un autre. La logique reste dans les use cases des features.

---

## 6. Routes par feature

Chaque feature expose ses routes dans un fichier dédié. Le router central les assemble.

```dart
// features/onboarding/onboarding_routes.dart
import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/body_selection_screen.dart';
import 'screens/lens_selection_screen.dart';
import 'screens/firmware_language_screen.dart';
import 'screens/recap_download_screen.dart';

final onboardingRoutes = [
  GoRoute(path: '/onboarding', builder: (_, __) => const WelcomeScreen()),
  GoRoute(path: '/onboarding/body', builder: (_, __) => const BodySelectionScreen()),
  GoRoute(path: '/onboarding/lens', builder: (_, __) => const LensSelectionScreen()),
  GoRoute(path: '/onboarding/language', builder: (_, __) => const FirmwareLanguageScreen()),
  GoRoute(path: '/onboarding/recap', builder: (_, __) => const RecapDownloadScreen()),
];
```

```dart
// core/router/app_router.dart
import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_routes.dart';
import '../../features/scene_input/scene_input_routes.dart';
import '../../features/results/results_routes.dart';
import '../../features/menu_nav/menu_nav_routes.dart';
import '../../features/gear/gear_routes.dart';
import '../../features/data_pack/data_pack_routes.dart';

final appRouter = GoRouter(
  initialLocation: '/',   // Home ou onboarding selon le state
  redirect: _guardOnboarding,
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    ...onboardingRoutes,
    ...sceneInputRoutes,
    ...resultsRoutes,
    ...menuNavRoutes,
    ...gearRoutes,
    ...dataPackRoutes,
  ],
);

String? _guardOnboarding(BuildContext context, GoRouterState state) {
  // Si pas de gear profile → rediriger vers onboarding
  // Logique d'auth guard ici
  return null;
}
```

**Règle** : un fichier route d'une feature n'importe que les screens de SA feature. Le router central importe les fichiers route, pas les screens directement.

---

## 7. Règles d'imports entre features

```
╔══════════════════════════════════════════════════════════════════╗
║                    MATRICE D'IMPORTS AUTORISÉS                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  features/X/  PEUT importer :                                    ║
║    ✅ shared/domain/**         (entities, value objects, repos)   ║
║    ✅ shared/data/**           (si besoin direct d'une data src)  ║
║    ✅ shared/presentation/**   (widgets, theme, providers ponts)  ║
║    ✅ core/**                  (utils, constants, errors)         ║
║    ✅ features/X/**            (ses propres fichiers)             ║
║                                                                  ║
║  features/X/  NE PEUT PAS importer :                             ║
║    ❌ features/Y/**            (JAMAIS d'import cross-feature)    ║
║                                                                  ║
║  shared/  PEUT importer :                                        ║
║    ✅ core/**                                                     ║
║    ✅ shared/**                                                   ║
║                                                                  ║
║  shared/  NE PEUT PAS importer :                                 ║
║    ❌ features/**              (JAMAIS)                           ║
║                                                                  ║
║  core/  PEUT importer :                                          ║
║    ✅ core/**                  (ses propres fichiers)             ║
║                                                                  ║
║  core/  NE PEUT PAS importer :                                   ║
║    ❌ shared/**                (JAMAIS)                           ║
║    ❌ features/**              (JAMAIS)                           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### 7.1. Enforcement

On ne peut pas compter sur la discipline humaine. Il faut un check automatisé.

**Option 1 — Script CI custom :**

```bash
#!/bin/bash
# ci/check_imports.sh
# Vérifie qu'aucune feature n'importe une autre feature

VIOLATIONS=$(grep -rn "import.*features/" lib/features/ \
  | while read line; do
    file_feature=$(echo "$line" | sed 's|lib/features/\([^/]*\)/.*|\1|')
    import_feature=$(echo "$line" | grep -oP "features/\K[^/]+")
    if [ "$file_feature" != "$import_feature" ]; then
      echo "$line"
    fi
  done)

if [ -n "$VIOLATIONS" ]; then
  echo "❌ Cross-feature imports detected:"
  echo "$VIOLATIONS"
  exit 1
fi

echo "✅ No cross-feature imports."
```

**Option 2 — Dart custom lint rule** via `custom_lint` package (plus avancé, V2).

**Option 3 — Convention + code review** (MVP minimum viable).

---

## 8. Feature anatomy — Template

Quand tu crées une nouvelle feature, voici le template :

```
features/{feature_name}/
├── domain/
│   ├── entities/           # Optionnel : entités propres à cette feature
│   │   └── ...
│   └── use_cases/          # Au moins 1 use case
│       └── ...
├── data/                   # Optionnel : si la feature a sa propre source de données
│   ├── models/
│   ├── mappers/
│   ├── data_sources/
│   └── repositories/
├── presentation/
│   ├── providers/          # Au moins 1 fichier de providers
│   │   └── {feature}_providers.dart
│   ├── screens/            # Optionnel : pas toutes les features ont des écrans
│   │   └── ...
│   └── widgets/            # Widgets spécifiques à cette feature
│       └── ...
└── {feature}_routes.dart   # Optionnel : seulement si la feature a des écrans
```

**Minimum viable feature** : `domain/use_cases/` + `presentation/providers/`. Tout le reste est optionnel.

---

## 9. Comment ajouter une feature (V2+)

Voici le guide concret pour ajouter une feature future sans toucher au code existant.

### 9.1. Exemple : Feature "Historique & Favoris" (V2)

**Périmètre** : sauvegarder les scènes et réglages passés, les retrouver, marquer des favoris.

**Étape 1 — Créer le dossier**

```
features/history/
├── domain/
│   ├── entities/
│   │   ├── history_entry.dart
│   │   └── favorite.dart
│   ├── repositories/
│   │   └── history_repository.dart          # Interface
│   └── use_cases/
│       ├── save_to_history.dart
│       ├── get_history.dart
│       ├── toggle_favorite.dart
│       └── delete_history_entry.dart
├── data/
│   ├── models/
│   │   └── history_entry_model.dart
│   ├── mappers/
│   │   └── history_mapper.dart
│   ├── data_sources/
│   │   └── history_local_source.dart        # Drift/SQLite
│   └── repositories/
│       └── history_repository_impl.dart
├── presentation/
│   ├── providers/
│   │   └── history_providers.dart
│   ├── screens/
│   │   ├── history_screen.dart
│   │   └── favorites_screen.dart
│   └── widgets/
│       ├── history_entry_card.dart
│       └── favorite_button.dart
└── history_routes.dart
```

**Étape 2 — Définir les entités** (dans la feature, pas dans shared)

```dart
// features/history/domain/entities/history_entry.dart
@freezed
class HistoryEntry with _$HistoryEntry {
  const factory HistoryEntry({
    required String id,
    required DateTime createdAt,
    required SceneInput scene,        // Import depuis shared/
    required SettingsResult result,    // Import depuis shared/
    required GearProfile gear,        // Import depuis shared/
    required bool isFavorite,
  }) = _HistoryEntry;
}
```

**Étape 3 — Implémenter le repository** (interface dans la feature, impl dans la feature)

Comme l'historique n'est utilisé que par cette feature, le repository ne va PAS dans shared.

**Étape 4 — Ajouter les routes**

```dart
// features/history/history_routes.dart
final historyRoutes = [
  GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
  GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
];
```

```dart
// core/router/app_router.dart — SEUL fichier modifié hors de la feature
import '../../features/history/history_routes.dart';

final appRouter = GoRouter(
  routes: [
    // ... routes existantes inchangées ...
    ...historyRoutes,   // ← Ajout d'une seule ligne
  ],
);
```

**Étape 5 — Connecter au flow existant**

Pour sauvegarder automatiquement un calcul dans l'historique, on ajoute un hook dans le provider partagé :

```dart
// Option A : le results provider déclenche la sauvegarde
// features/results/presentation/providers/results_providers.dart
// ❌ NON — ça couplerait results à history

// Option B : un provider dans history écoute le résultat (CORRECT)
// features/history/presentation/providers/history_providers.dart
final autoSaveProvider = Provider((ref) {
  ref.listen(settingsResultProvider, (prev, next) {
    if (next.hasValue && next.value != null) {
      final useCase = ref.read(saveToHistoryProvider);
      useCase.execute(
        scene: ref.read(currentSceneProvider)!,
        result: next.value!,
        gear: ref.read(currentGearProvider)!,
      );
    }
  });
});
```

**Bilan des fichiers modifiés hors de la feature** :
1. `core/router/app_router.dart` — 2 lignes (import + spread routes)
2. `main.dart` ou `app.dart` — 1 ligne si on doit initialiser le `autoSaveProvider`

Tout le reste est dans `features/history/`. **Zéro modification des features existantes.**

### 9.2. Exemple : Feature "AI Scene Assist" (V3)

**Périmètre** : description de scène par texte libre ou photo, interprétée par un LLM.

```
features/ai_scene/
├── domain/
│   ├── entities/
│   │   └── ai_scene_suggestion.dart
│   ├── repositories/
│   │   └── ai_scene_repository.dart         # Interface (appel API LLM)
│   └── use_cases/
│       ├── analyze_text_description.dart
│       └── analyze_photo.dart
├── data/
│   ├── data_sources/
│   │   └── llm_api_source.dart              # Appel API OpenAI/Anthropic
│   └── repositories/
│       └── ai_scene_repository_impl.dart
├── presentation/
│   ├── providers/
│   │   └── ai_scene_providers.dart
│   ├── screens/
│   │   └── ai_scene_screen.dart
│   └── widgets/
│       ├── text_input_card.dart
│       └── photo_picker_card.dart
└── ai_scene_routes.dart
```

Le résultat de l'AI est un `SceneInput` (entité partagée). Le flow existant le consomme tel quel :

```dart
// L'AI produit un SceneInput pré-rempli
final aiResult = await analyzeTextDescription.execute(userText);
ref.read(currentSceneProvider.notifier).state = aiResult;
// → Le settings engine se déclenche automatiquement
// → L'écran résultats s'affiche
```

**Zéro modification du settings_engine.** L'AI produit un SceneInput, le moteur le consomme. Le contrat (l'entité SceneInput) est le même.

---

## 10. Checklist — Santé modulaire

À vérifier périodiquement (ou en CI) :

```
Architecture
  ☐ Aucun import features/X → features/Y (script CI)
  ☐ Aucun import shared → features (script CI)
  ☐ Aucun import core → shared ou features (script CI)
  ☐ Chaque feature a au moins un use case dans domain/
  ☐ Chaque feature a au moins un provider dans presentation/providers/
  ☐ Les routes de chaque feature sont dans {feature}_routes.dart

Couplage
  ☐ Les providers "ponts" dans shared/ ne contiennent pas de logique
  ☐ Les entités dans features/X/domain/ ne sont pas importées ailleurs
  ☐ Si une entité feature est importée par 2+ features → la promouvoir dans shared/

Extensibilité
  ☐ Ajouter une feature touche ≤ 3 fichiers hors de features/{new}/
  ☐ Le router central n'a que des spreads de routes (pas de logique d'écran)
  ☐ Les resolvers du settings_engine sont enregistrables sans modifier l'orchestrateur
```

---

*Ce document est la référence pour la structure concrète du projet. Combiné avec le skill 09 (Clean Architecture), il définit complètement "où va chaque fichier" et "comment les pièces se parlent". Le skill 21 (Extensibility Playbook) utilisera ce document comme base pour les guides "comment ajouter X".*
