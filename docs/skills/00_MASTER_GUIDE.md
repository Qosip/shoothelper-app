# SKILL 00 — Guide Maître ShootHelper

> **Le document que tu ouvres en premier. Toujours.**
> Il te dit quoi faire, dans quel ordre, et comment reprendre après une pause.
> Version 1.0 · Mars 2026

---

## 1. IDE & Outils à installer

### 1.1. Sur ton PC (Windows)

```
OBLIGATOIRE :
  1. Flutter SDK 3.38+
     → https://docs.flutter.dev/get-started/install/windows/mobile
     → Ajouter au PATH
     → Vérifier : flutter doctor

  2. Android Studio (pour le SDK Android + émulateur)
     → https://developer.android.com/studio
     → Installer Android SDK 35, Android SDK Build-Tools, Android Emulator
     → Créer un AVD (Pixel 8, API 35)

  3. VS Code (ton IDE principal)
     → https://code.visualstudio.com
     → Extensions OBLIGATOIRES :
        • Flutter (Dart-Code.flutter)
        • Dart (Dart-Code.dart-code)
        • Riverpod Snippets (robert-brunhage.flutter-riverpod-snippets)
        • Error Lens (usernamehw.errorlens)
        • Todo Tree (Gruntfuggly.todo-tree)

  4. Git
     → Déjà installé si tu utilises GitHub

  5. Un téléphone Android avec câble USB (pour le debug sur device réel)
     → Activer les Options développeur + Débogage USB

OPTIONNEL (si tu veux builder iOS plus tard) :
  → Un Mac est OBLIGATOIRE pour les builds iOS
  → Solution pas chère : Mac Mini M1 reconditionné (~400€)
  → Ou : GitHub Actions macOS runner (gratuit pour les builds CI)
  → Pour le MVP : commence Android only, ajoute iOS avant le launch

OPTIONNEL (pour le data entry) :
  6. Python 3.12+ (pour les scrapers et outils de build data packs)
  7. Node.js (si tu veux un serveur local pour tester le CDN)
```

### 1.2. Configuration VS Code

```json
// .vscode/settings.json (à la racine du projet)
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit",
    "source.organizeImports": "explicit"
  },
  "dart.lineLength": 100,
  "dart.previewFlutterUiGuides": true,
  "dart.openDevTools": "flutter",
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.rulers": [100],
    "editor.tabSize": 2
  },
  "files.exclude": {
    "**/*.g.dart": false,
    "**/*.freezed.dart": false
  },
  "search.exclude": {
    "**/*.g.dart": true,
    "**/*.freezed.dart": true
  }
}
```

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "ShootHelper (dev)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=dev"]
    },
    {
      "name": "ShootHelper (prod)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=prod"]
    }
  ]
}
```

### 1.3. Vérification de l'installation

```bash
flutter doctor -v
# Tout doit être ✓ sauf éventuellement Xcode (pas sur Windows)

flutter --version
# Flutter 3.38.x • channel stable

dart --version
# Dart SDK version: 3.6.x
```

---

## 2. Initialiser le projet

### 2.1. Créer les deux repos

```bash
# REPO 1 : L'app Flutter
mkdir shoothelper-app && cd shoothelper-app
flutter create --org app.shoothelper --project-name shoothelper .
git init
git remote add origin https://github.com/TON_USER/shoothelper-app.git

# REPO 2 : Les data packs (séparé)
cd ..
mkdir shoothelper-data && cd shoothelper-data
git init
git remote add origin https://github.com/TON_USER/shoothelper-data.git
mkdir -p sources/shared sources/sony_a6700/lenses schemas tools dist
```

### 2.2. Scaffolding de l'app (premier commit)

Après le `flutter create`, remplacer la structure par défaut par l'architecture du skill 10 :

```bash
cd shoothelper-app

# Nettoyer le boilerplate Flutter
rm lib/main.dart test/widget_test.dart

# Créer la structure de dossiers
mkdir -p lib/{core/{constants,errors,extensions,utils,config,router},shared/{domain/{entities,value_objects,repositories},data/{models,mappers,data_sources/{local,remote},repositories},presentation/{providers,widgets,theme},l10n},features/{onboarding/{domain/use_cases,presentation/{providers,screens,widgets}},data_pack/{domain/use_cases,presentation/{providers,screens,widgets}},scene_input/{domain/{entities,use_cases},presentation/{providers,screens,widgets}},settings_engine/{domain/{entities,engine/resolvers,use_cases},presentation/providers},results/{domain/use_cases,presentation/{providers,screens,widgets}},menu_nav/{domain/use_cases,presentation/{providers,screens,widgets}},gear/{domain/use_cases,presentation/{providers,screens,widgets}}},generated}

# Créer la structure de test
mkdir -p test/{core/utils,shared/{domain/{entities,value_objects},data/{models,mappers,data_sources/local}},features/{settings_engine/domain/{engine/resolvers,use_cases},scene_input/{domain/use_cases,presentation},results/{domain/use_cases,presentation},menu_nav/domain/use_cases,onboarding/presentation,data_pack/domain/use_cases},fixtures/{bodies,lenses,menu_trees,nav_paths,shared},helpers}

mkdir -p integration_test

# Créer les fichiers d'entrée minimaux
touch lib/main.dart
touch lib/app.dart
```

### 2.3. pubspec.yaml initial

Copier le contenu exact du skill 22, section 5.2 dans `pubspec.yaml`.

### 2.4. Installer les dépendances

```bash
flutter pub get
```

### 2.5. Premier fichier : main.dart

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}
```

```dart
// lib/app.dart
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShootHelper',
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('ShootHelper — Setup OK')),
      ),
    );
  }
}
```

### 2.6. Vérifier que tout tourne

```bash
flutter run
# L'app affiche "ShootHelper — Setup OK" sur l'émulateur ou le device
```

### 2.7. Premier commit

```bash
git add .
git commit -m "feat: initial project scaffolding with Clean Architecture structure"
git push -u origin main
```

---

## 3. Ordre de développement

**Chaque phase a un livrable testable.** Tu ne passes à la phase suivante que quand la phase en cours fonctionne et a ses tests.

```
╔══════════════════════════════════════════════════════════════════╗
║                    ROADMAP DE DÉVELOPPEMENT                      ║
║                                                                  ║
║  PHASE 0 : Bootstrap (1 semaine)                                 ║
║  ─────────────────────────────────                              ║
║  → Installer Flutter, VS Code, créer les repos                  ║
║  → Scaffolding architecture (dossiers + main.dart)              ║
║  → Premier flutter run qui marche                               ║
║  → Skills : 08, 09, 10                                          ║
║                                                                  ║
║  PHASE 1 : Le moteur — Dart pur, pas de Flutter (2 semaines)    ║
║  ────────────────────────────────────────────────               ║
║  → Value objects (FStop, ShutterSpeed, IsoValue)                ║
║  → Entities (Body, Lens, SceneInput, SettingsResult)            ║
║  → Settings Engine (tous les resolvers)                         ║
║  → ExposureCalculator + AstroCalculator                         ║
║  → CompromiseDetector + AlternativeGenerator                    ║
║  → ExplanationGenerator                                         ║
║  → 100% testable en Dart pur, pas besoin de Flutter             ║
║  → LIVRABLE : flutter test passe, 10 scénarios du skill 06     ║
║  → Skills : 06, partie domain du 17 et 18                      ║
║                                                                  ║
║  PHASE 2 : Les données — JSON + parsing (1 semaine)             ║
║  ──────────────────────────────────────────────────             ║
║  → Créer les fichiers JSON pour Sony A6700 (ton appareil)       ║
║  → body.json, menu_tree.json, nav_paths.json                   ║
║  → Au moins 1 lens (Sigma 18-50 f/2.8)                         ║
║  → Models + Mappers (BodyModel → Body entity)                   ║
║  → JsonDataSource + CameraDataCache                             ║
║  → FileManager                                                   ║
║  → LIVRABLE : charger le data pack A6700 en mémoire, vérifier  ║
║    les données avec un test                                      ║
║  → Skills : 04, 05, 07, 12                                     ║
║                                                                  ║
║  PHASE 3 : Le flow principal — UI de bout en bout (2 semaines)  ║
║  ──────────────────────────────────────────────────────────     ║
║  → Home Screen (minimal)                                         ║
║  → Scene Input Screen (3 niveaux)                               ║
║  → Results Screen (summary + liste + détail)                    ║
║  → Menu Navigation Screen                                        ║
║  → GoRouter (navigation entre écrans)                           ║
║  → Riverpod providers (gear, scene, results, menu_nav)          ║
║  → LIVRABLE : flow complet sur l'émulateur — décrire une scène ║
║    → voir les réglages → naviguer dans les menus de l'A6700     ║
║  → Skills : 02, 11, 17, 18, 19                                 ║
║                                                                  ║
║  PHASE 4 : Onboarding & Download (1 semaine)                    ║
║  ────────────────────────────────────────────                   ║
║  → Deployer les data packs sur GitHub Pages                     ║
║  → Écrans d'onboarding (sélection body → lens → langue)        ║
║  → Download data pack + stockage local                          ║
║  → Détection connectivité + mode offline                        ║
║  → download_state.json                                           ║
║  → LIVRABLE : installer l'app from scratch sur un device,       ║
║    onboarding complet, puis mode avion → l'app fonctionne       ║
║  → Skills : 13, 14, 16                                          ║
║                                                                  ║
║  PHASE 5 : Error handling & polish (1 semaine)                   ║
║  ────────────────────────────────────────────                   ║
║  → Tous les fallbacks (skill 15)                                ║
║  → Messages d'erreur utilisateur                                ║
║  → Gestion gear (settings, ajouter/supprimer objectif)          ║
║  → UI polish (theme, animations, responsive)                    ║
║  → Skills : 15, 03                                              ║
║                                                                  ║
║  PHASE 6 : Data entry — 2 boîtiers supplémentaires (1 semaine) ║
║  ──────────────────────────────────────────────────────────     ║
║  → Canon R50 data pack (scraping + data entry)                  ║
║  → Nikon Z50 II data pack                                       ║
║  → Validation cross-brand (même scène, 3 boîtiers différents)  ║
║  → Skills : 05                                                   ║
║                                                                  ║
║  PHASE 7 : Tests & Release (1 semaine)                           ║
║  ──────────────────────────────────────                         ║
║  → Les 72 scénarios de test (skill 20)                          ║
║  → Snapshot tests du moteur                                      ║
║  → CI/CD setup (GitHub Actions)                                  ║
║  → Beta interne sur device                                       ║
║  → Soumission aux stores                                        ║
║  → Skills : 20, 22                                               ║
║                                                                  ║
║  🚀 LAUNCH                                                       ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### 3.1. Pourquoi cet ordre

**Phase 1 d'abord (le moteur, pas l'UI)** parce que c'est le cœur de l'app et c'est du Dart pur — tu apprends Dart sans la complexité de Flutter. Si le moteur est faux, rien d'autre ne compte. Et les tests du moteur sont les plus rapides à écrire et à exécuter.

**Phase 2 avant Phase 3** parce que l'UI a besoin de données réelles pour afficher quelque chose d'utile. Un écran avec des données mockées ne valide rien. Avoir le data pack Sony A6700 dès la Phase 2 te permet de voir des vrais noms de menus en français sur ton écran dès la Phase 3.

**Phase 4 après Phase 3** parce que le download et l'offline sont importants mais l'app peut tourner en dev avec des fichiers locaux. L'onboarding n'est utile que quand le flow principal marche.

---

## 4. Travailler avec Claude Code (agent IDE)

### 4.1. Setup

Claude Code est un agent CLI qui travaille dans ton IDE. Pour l'utiliser avec ShootHelper :

```bash
# Installer Claude Code (si pas déjà fait)
npm install -g @anthropic-ai/claude-code

# Lancer dans le repo du projet
cd shoothelper-app
claude
```

### 4.2. Le fichier CLAUDE.md (contexte persistant)

Crée un fichier `CLAUDE.md` à la racine du projet. C'est le fichier que Claude Code lit automatiquement à chaque session pour comprendre le contexte du projet.

```markdown
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
Les 22 skills de design sont dans le dossier /docs/skills/ (ou fournis en contexte).
Chaque skill est un document de référence pour une partie du projet.
Les plus importants pour le code :
- 06_SETTINGS_ENGINE.md → Algorithmes du moteur
- 09_APP_ARCHITECTURE.md → Structure et patterns
- 10_MODULE_FEATURE_ARCHITECTURE.md → Dossiers et imports
- 11_STATE_MANAGEMENT.md → Riverpod providers
- 19_MENU_NAVIGATION_MAPPER.md → Killer feature

## Phase actuelle
[METTRE À JOUR MANUELLEMENT]
Phase X : description de ce sur quoi on travaille actuellement.

## Ce qui est fait
[METTRE À JOUR MANUELLEMENT]
- ☐/☑ Phase 0 : Bootstrap
- ☐/☑ Phase 1 : Moteur
- ☐/☑ Phase 2 : Données
- ...
```

### 4.3. Comment donner du contexte entre sessions

Quand tu ouvres une nouvelle conversation (ici sur claude.ai ou dans Claude Code), le contexte des conversations précédentes n'est pas automatiquement là. Voici comment être efficace :

**Méthode 1 : Le CLAUDE.md (Claude Code)**

Si tu utilises Claude Code, le fichier `CLAUDE.md` est lu automatiquement. Mets-le à jour après chaque session de travail avec la phase en cours et ce qui a été fait.

**Méthode 2 : Le "resumé de session" (claude.ai)**

À la fin de chaque session de chat, demande :

```
Résume cette session en un bloc de contexte que je pourrai coller
au début de la prochaine conversation pour reprendre où on en est.
```

Tu obtiendras un bloc condensé. Au début de la session suivante, colle-le en premier message :

```
Voici le contexte de ma dernière session sur ShootHelper :
[coller le bloc]

On continue avec [la suite].
```

**Méthode 3 : Fournir le skill pertinent**

Si tu travailles sur une feature spécifique, fournis le skill correspondant en pièce jointe ou en contexte. Exemple :

```
Je travaille sur le Settings Engine (Phase 1).
Voici le skill de référence : [coller ou uploader 06_SETTINGS_ENGINE.md]
J'en suis au AfModeResolver. Voici le code actuel : [coller le fichier]
```

### 4.4. Prompts types pour Claude Code

**Démarrer une phase :**
```
Je commence la Phase 1 du projet ShootHelper. Lis CLAUDE.md pour le contexte.
Le skill de référence est 06_SETTINGS_ENGINE.md.
Crée les fichiers pour les value objects FStop, ShutterSpeed, et IsoValue
avec leurs tests unitaires.
```

**Continuer un travail :**
```
J'ai implémenté les value objects et l'ExposureCalculator.
Maintenant je veux implémenter l'AfModeResolver (arbre de décision du skill 06 §4.1).
Voici le fichier EngineContext actuel : [path]
```

**Débugger :**
```
Le test SE-04 (Astro tripod) échoue. La vitesse calculée est 25s
au lieu de ~12s attendu. Voici le code de AstroCalculator et le test.
Le skill 06 §3.6 décrit la règle NPF.
```

**Review :**
```
J'ai terminé tous les resolvers du Settings Engine.
Fais une review de l'architecture — vérifie que ça respecte les conventions
du skill 09 (Clean Architecture) et du skill 10 (Module Architecture).
Vérifie en particulier les imports entre couches.
```

---

## 5. Stockage des skills dans le projet

### 5.1. Où mettre les 22 skills

```
shoothelper-app/
├── docs/
│   └── skills/
│       ├── 00_MASTER_GUIDE.md          ← Ce fichier
│       ├── 01_PRD.md
│       ├── 02_USER_FLOWS.md
│       ├── ...
│       └── 22_DEPLOYMENT_DISTRIBUTION.md
├── CLAUDE.md                            ← Contexte pour Claude Code
├── lib/
│   └── ...
└── ...
```

Les skills sont dans `docs/skills/`. Ils ne sont pas dans le code source, mais ils sont versionnés avec le repo. Tu peux les référencer dans les commits et les PRs.

### 5.2. Référencer un skill dans un commit

```bash
git commit -m "feat(engine): implement AfModeResolver

Decision tree from skill 06 §4.1.
Covers AF-S, AF-C, DMF, MF selection based on subject and motion.
Tests: SE-01, SE-04, SE-06"
```

---

## 6. Checklist par phase

### Phase 0 — Bootstrap

```
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
```

### Phase 1 — Le moteur

```
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
```

### Phase 2 — Les données

```
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
```

### Phase 3 — Flow principal UI

```
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
```

### Phase 4 — Onboarding & Download

```
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
```

### Phase 5 — Error handling & polish

```
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
```

### Phase 6 — Data entry supplémentaire

```
☐ Canon R50 : body.json, menu_tree.json (FR+EN), nav_paths.json, 3 lenses
☐ Nikon Z50 II : body.json, menu_tree.json (FR+EN), nav_paths.json, 3 lenses
☐ Validation pipeline (validate.py, build_manifests.py, build_catalog.py)
☐ Cross-brand test : même scène (portrait bokeh) sur 3 boîtiers → résultats cohérents
☐ Cross-brand test : même réglage (af_mode:af-c) → terminologie correcte par marque
☐ Déployer les 3 data packs sur GitHub Pages
```

### Phase 7 — Tests & Release

```
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
```

---

## 7. Mémo rapide — Les commandes du quotidien

```bash
# ─── DÉVELOPPEMENT ───
flutter run                              # Lancer l'app
flutter run --dart-define=ENV=dev        # Lancer en mode dev
flutter hot-restart                      # Ctrl+Shift+F5 dans VS Code (plus fiable que hot-reload pour Riverpod)

# ─── CODE GENERATION ───
dart run build_runner build --delete-conflicting-outputs
# À lancer après chaque modification d'un fichier @freezed, @riverpod, ou @JsonSerializable
# Shortcut VS Code : créer une tâche (Task) pour ça

dart run build_runner watch --delete-conflicting-outputs
# Mode watch : régénère automatiquement quand un fichier change
# RECOMMANDÉ : lancer dans un terminal séparé pendant le dev

# ─── TESTS ───
flutter test                             # Tous les tests
flutter test test/features/settings_engine/  # Tests d'une feature
flutter test --coverage                  # Avec rapport de coverage
flutter test --update-goldens            # Mettre à jour les snapshot tests

# ─── ANALYSE ───
flutter analyze                          # Lint strict
dart format .                            # Formater tout le code

# ─── BUILD ───
flutter build apk --release              # APK Android
flutter build appbundle --release        # App Bundle (pour Play Store)
flutter build ipa --release              # iOS (nécessite Mac)

# ─── DATA PACKS (dans le repo shoothelper-data) ───
python tools/validate.py --all --data sources/    # Valider les JSON
python tools/build_manifests.py --data dist/      # Générer les manifests
python tools/build_catalog.py --data dist/ --output dist/catalog.json
```

---

## 8. Quand tu es bloqué

```
1. Le test ne passe pas ?
   → Lis le skill correspondant. La logique y est décrite en pseudo-code.
   → Les scénarios de test attendus sont dans les skills.

2. Tu ne sais pas où mettre un fichier ?
   → Skill 10 (Module Architecture) : règle shared/ vs features/
   → Skill 09 (App Architecture) : règle Domain / Data / Presentation

3. Tu ne sais pas quel provider utiliser ?
   → Skill 11 (State Management) : catalogues des providers par feature

4. L'UI ne correspond pas au flow ?
   → Skill 02 (User Flows) : chaque écran est décrit avec ses actions

5. Le moteur donne un mauvais résultat ?
   → Skill 06 (Settings Engine) : arbres de décision + tables de référence

6. Le chemin menu est faux ?
   → Skill 04 (Camera Data Architecture) : vérifier le JSON du data pack
   → Skill 19 (Menu Navigation Mapper) : vérifier le pipeline de résolution
   → Vérifier sur le Help Guide officiel du constructeur
```

---

## 9. Notes finales

**Tu as 22 skills qui totalisent ~760 KB de documentation.** C'est l'équivalent d'un livre technique complet sur TON app. Chaque décision est argumentée, chaque structure de données est définie, chaque algorithme est en pseudo-code.

**Le code va écrire ce que les skills décrivent.** Si tu suis les skills, tu ne te retrouveras jamais devant un "et maintenant je fais quoi ?". La réponse est toujours dans un des 22 documents.

**Commencer petit, tester tôt.** Phase 1 = le moteur seul, testé en Dart pur. Si les maths sont justes et les arbres de décision corrects, le reste est de la plomberie.

Bon courage. L'app est entièrement designée — il ne reste qu'à la construire.

---

*Dernière mise à jour : Mars 2026*
*Phase actuelle : Phase 0 — Bootstrap*
