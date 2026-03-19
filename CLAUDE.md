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
Phase 4 : Onboarding & Download

## Ce qui est fait
- ☑ Phase 0 : Bootstrap
- ☑ Phase 1 : Moteur (Settings Engine, Dart pur) — 37 tests passent
- ☑ Phase 2 : Données (JSON data packs + parsing) — 94 tests passent
- ☑ Phase 3 : Flow principal UI — 119 tests passent
- ☐ Phase 4 : Onboarding & Download
- ☐ Phase 5 : Error handling & polish
- ☐ Phase 6 : Data entry supplémentaire
- ☐ Phase 7 : Tests & Release


Voici les phases à implémenter et suivre :
Phase 0 — Bootstrap
☐ Flutter SDK installé + flutter doctor OK
☐ VS Code + extensions Flutter/Dart installées
☐ Android Studio + SDK + émulateur configuré
☐ Repo shoothelper-app créé sur GitHub
☐ Repo shoothelper-data créé sur GitHub
☐ Structure de dossiers créée (skill 10)
☐ pubspec.yaml avec toutes les dépendances (skill 22)
☐ flutter pub get sans erreur
☐ flutter run affiche l'écran de base
☐ Premier commit pushé
☐ 22 skills copiés dans docs/skills/
☐ CLAUDE.md créé à la racine
Phase 1 — Le moteur
☐ FStop, ShutterSpeed, IsoValue — value objects + tests
☐ Body, Lens, SceneInput, SettingsResult — entities (Freezed)
☐ EngineContext — structure d'entrée du moteur
☐ ExposureCalculator — triangle d'exposition + tests
☐ AstroCalculator — règle NPF + tests
☐ AfModeResolver + tests
☐ AfAreaResolver + tests
☐ MeteringResolver + tests
☐ WbResolver + tests
☐ DriveResolver + tests
☐ StabilizationResolver + tests
☐ FileFormatResolver + tests
☐ ExposureModeResolver + tests
☐ CompromiseDetector + tests
☐ AlternativeGenerator + tests
☐ ExplanationGenerator + tests (templates i18n)
☐ SettingsEngine (orchestrateur) + tests intégration
☐ CalculateSettings use case + tests
☐ Les 10 scénarios du skill 06 passent ✅
☐ Snapshot tests créés pour les 8 scénarios types
Phase 2 — Les données
☐ body.json Sony A6700 créé (depuis le Help Guide)
☐ menu_tree.json Sony A6700 créé (FR + EN minimum)
☐ nav_paths.json Sony A6700 créé (15 réglages)
☐ sigma_18-50_f2.8.json créé
☐ setting_defs.json créé
☐ brands.json + mounts.json créés
☐ BodyModel + json_serializable + .g.dart
☐ LensModel, MenuTreeModel, NavPathModel
☐ BodyMapper, LensMapper, MenuTreeMapper
☐ JsonDataSource — lecture fichiers JSON
☐ CameraDataCache — chargement en mémoire
☐ FileManager — abstraction filesystem
☐ Tests : parsing JSON → entities correctes
☐ Tests : CameraDataCache.load() charge tout en mémoire
☐ Vérification : 5 chemins de menu spot-checkés sur ton A6700
Phase 3 — Flow principal UI
☐ AppTheme (Material 3, couleurs, typo)
☐ GoRouter configuré avec toutes les routes
☐ Home Screen (affiche gear, bouton "Nouveau shoot")
☐ Scene Input Screen — Niveau 1 (4 chips obligatoires)
☐ Scene Input Screen — Niveau 2 (expand, suggestions)
☐ Scene Input Screen — Niveau 3 (expand, overrides)
☐ SceneInputDraft provider + validation
☐ Bouton "Calculer" → appel moteur → navigation résultats
☐ Results Screen — ExposureSummaryCard (4 valeurs en gros)
☐ Results Screen — Liste des réglages avec explanation courte
☐ Results Screen — Bandeau compromis
☐ Setting Detail Screen — explication détaillée + alternatives
☐ Menu Navigation Screen — breadcrumb + étapes + tips
☐ Bouton copier presse-papier
☐ Widget tests pour chaque écran
☐ LIVRABLE : flow complet sur émulateur avec données A6700 réelles
Phase 4 — Onboarding & Download
☐ Data packs déployés sur GitHub Pages
☐ catalog.json + health.json sur le CDN
☐ DataPackApi (Dio) — fetch manifest, fetch fichiers
☐ ConnectivityService — détection réseau + ping réel
☐ Download pipeline — temp dir → validation → atomic swap
☐ download_state.json — tracking des fichiers téléchargés
☐ Welcome Screen
☐ Body Selection Screen (depuis catalog.json)
☐ Lens Selection Screen (filtré par monture)
☐ Firmware Language Screen
☐ Recap & Download Screen (progress bar)
☐ Auto-resume download au retour du réseau
☐ Guard router : pas de gear → redirect onboarding
☐ Guard router : data pack incomplet → redirect download
☐ Test : installer from scratch + onboarding complet
☐ Test : mode avion après setup → app fonctionne
Phase 5 — Error handling & polish
☐ Exception hierarchy (skill 15)
☐ Failure classes avec messages utilisateur
☐ ErrorDisplay widget réutilisable
☐ Fallback chain pour labels manquants
☐ Fallback pour NavPath manquant
☐ Gestion gear : ajouter/supprimer objectif, changer boîtier
☐ Changement langue firmware (instantané, pas de download)
☐ Check MAJ data pack silencieux au lancement
☐ UI polish : animations expand, transitions, responsive
☐ Les 15 scénarios d'erreur du skill 15 sont couverts
Phase 6 — Data entry supplémentaire
☐ Canon R50 : body.json, menu_tree.json (FR+EN), nav_paths.json, 3 lenses
☐ Nikon Z50 II : body.json, menu_tree.json (FR+EN), nav_paths.json, 3 lenses
☐ Validation pipeline (validate.py, build_manifests.py, build_catalog.py)
☐ Cross-brand test : même scène (portrait bokeh) sur 3 boîtiers → résultats cohérents
☐ Cross-brand test : même réglage (af_mode:af-c) → terminologie correcte par marque
☐ Déployer les 3 data packs sur GitHub Pages
Phase 7 — Tests & Release
☐ Les 72 scénarios de test documentés passent
☐ Coverage ≥ 80% global, ≥ 95% sur le moteur
☐ CI GitHub Actions configuré (analyze + test + import check)
☐ Build release Android (APK + AAB)
☐ Build release iOS (IPA) — si Mac disponible
☐ Test sur device réel Android
☐ Test sur device réel iOS (si dispo)
☐ Fiche Play Store complète
☐ Fiche App Store complète (si iOS)
☐ Soumission aux stores
☐ 🚀