# CLAUDE.md — Contexte ShootHelper

## Le projet
ShootHelper est une app mobile Flutter qui recommande les réglages photo/vidéo
optimaux et guide l'utilisateur dans les menus de son appareil.

## Architecture
- Clean Architecture 3 couches : Domain / Data / Presentation
- Feature-first (lib/features/*)
- State management : Riverpod 2.x avec code generation
- Navigation : GoRouter
- Stockage : JSON fichiers (data packs) + SharedPreferences (profil gear)

## Conventions
- Entities : immutables via Freezed
- Value objects : FStop, ShutterSpeed, IsoValue (types forts)
- Models : suffixe Model (BodyModel), avec json_serializable
- Mappers : suffixe Mapper (BodyMapper), dans data/mappers/
- Use cases : une classe = une action (CalculateSettings, ResolveMenuPath)
- Providers : camelCase + Provider suffix
- Tests : mirrorent lib/, dans test/

## Règles strictes
- Domain n'importe JAMAIS Flutter, Data, ou packages I/O
- Aucun import cross-feature (features/X ne peut pas importer features/Y)
- Le state éphémère (toggle, search field) va dans le widget, PAS dans Riverpod
- ref.watch dans build(), ref.read dans callbacks, ref.listen pour side effects

## Skills de référence
Les 22 skills de design sont dans le dossier docs/skills/.
Chaque skill est un document de référence pour une partie du projet.
Les plus importants pour le code :
- 06_SETTINGS_ENGINE.md → Algorithmes du moteur
- 09_APP_ARCHITECTURE.md → Structure et patterns
- 10_MODULE_FEATURE_ARCHITECTURE.md → Dossiers et imports
- 11_STATE_MANAGEMENT.md → Riverpod providers
- 19_MENU_NAVIGATION_MAPPER.md → Killer feature

## Phase actuelle
Phase 0 : Bootstrap — finalisation du scaffolding

## Ce qui est fait
- ☑ Phase 0 : Bootstrap (en cours de finalisation)
- ☐ Phase 1 : Moteur (Settings Engine, Dart pur)
- ☐ Phase 2 : Données (JSON data packs)
- ☐ Phase 3 : Flow principal UI
- ☐ Phase 4 : Onboarding & Download
- ☐ Phase 5 : Error handling & polish
- ☐ Phase 6 : Data entry supplémentaire
- ☐ Phase 7 : Tests & Release
