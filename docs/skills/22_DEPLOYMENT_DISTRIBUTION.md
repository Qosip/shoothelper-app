# Deployment & Distribution — ShootHelper

> **Skill 22/22** · App Store, Play Store, CI/CD, OTA data packs
> Version 1.0 · Mars 2026
> Réf : 08_TECH_STACK_DECISION.md, 14_API_BACKEND_DESIGN.md, 20_TESTING_STRATEGY.md

---

## 1. Vue d'ensemble

ShootHelper a **deux pipelines de distribution indépendants** qui ne sont pas couplés :

```
PIPELINE 1 : L'APP (code Flutter)
  Repo : shoothelper-app (GitHub)
  Build : GitHub Actions → APK/IPA
  Distribution : Google Play Store + Apple App Store
  Fréquence : toutes les 2-4 semaines (ou plus si bugfix)
  Temps : 30min build + 1-3 jours review stores

PIPELINE 2 : LES DATA PACKS (fichiers JSON)
  Repo : shoothelper-data (GitHub)
  Build : GitHub Actions → minification + manifests
  Distribution : CDN statique (GitHub Pages → Cloudflare R2)
  Fréquence : à chaque correction ou ajout de boîtier
  Temps : 5 minutes du push au déploiement

L'app peut être mise à jour SANS toucher aux data packs.
Les data packs peuvent être mis à jour SANS publier une nouvelle version de l'app.
C'est le principe fondamental de l'architecture OTA.
```

---

## 2. Pipeline 1 : L'app — CI/CD complet

### 2.1. Branches et workflow Git

```
main          ← Production. Chaque commit = release candidate.
  ↑ merge PR
develop       ← Développement actif. Tests CI à chaque push.
  ↑ merge PR
feature/*     ← Branches de feature. Ex: feature/history, feature/video-mode
  ↑ merge PR
fix/*         ← Bugfixes. Ex: fix/astro-calculation
```

**Règles :**
- `main` est toujours déployable
- Merge vers `main` uniquement via PR avec CI verte
- Tags de release sur `main` : `v1.0.0`, `v1.0.1`, etc.
- `develop` est la branche d'intégration quotidienne

### 2.2. GitHub Actions — CI

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [develop, main]
  pull_request:
    branches: [develop, main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.x'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code (freezed, json_serializable, riverpod)
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Analyze (strict)
        run: flutter analyze --fatal-infos

      - name: Check import rules (no cross-feature imports)
        run: bash ci/check_imports.sh

      - name: Run unit & widget tests
        run: flutter test --coverage --reporter=github

      - name: Check coverage thresholds
        run: bash ci/check_coverage.sh

      - name: Upload coverage
        if: github.ref == 'refs/heads/main'
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

### 2.3. GitHub Actions — Build & Release

```yaml
# .github/workflows/release.yml
name: Build & Release

on:
  push:
    tags: ['v*']  # Déclenché par un tag v1.0.0, v1.0.1, etc.

jobs:
  # ─── BUILD ANDROID ───
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.x'

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Decode keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Build APK (release)
        run: flutter build apk --release --obfuscate --split-debug-info=build/debug-info

      - name: Build App Bundle (release)
        run: flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: android-release
          path: |
            build/app/outputs/flutter-apk/app-release.apk
            build/app/outputs/bundle/release/app-release.aab

  # ─── BUILD iOS ───
  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.x'

      - name: Install CocoaPods
        run: cd ios && pod install

      - name: Setup signing
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
          p12-password: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}

      - name: Setup provisioning profile
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.IOS_PROVISIONING_PROFILE_BASE64 }}" | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision

      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Build iOS (release)
        run: flutter build ipa --release --obfuscate --split-debug-info=build/debug-info --export-options-plist=ios/ExportOptions.plist

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: ios-release
          path: build/ios/ipa/ShootHelper.ipa

  # ─── PUBLISH ───
  publish-android:
    needs: [build-android]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: android-release

      - name: Upload to Play Store (internal track)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: app.shoothelper
          releaseFiles: app-release.aab
          track: internal
          status: completed

  publish-ios:
    needs: [build-ios]
    runs-on: macos-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: ios-release

      - name: Upload to App Store Connect
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: ShootHelper.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

### 2.4. Processus de release

```
RELEASE CHECKLIST :

1. ☐ Tous les tests passent sur develop
2. ☐ PR develop → main, review
3. ☐ Merge sur main
4. ☐ Créer le tag : git tag v1.0.0 && git push --tags
5. ☐ GitHub Actions build automatiquement iOS + Android
6. ☐ Android → Upload internal track Play Store (automatique)
7. ☐ iOS → Upload TestFlight (automatique)
8. ☐ Test interne sur les deux plateformes (~1 jour)
9. ☐ Promouvoir Android : internal → production dans Play Console
10. ☐ Soumettre iOS pour review dans App Store Connect
11. ☐ Review Apple (~1-3 jours pour la première soumission)
12. ☐ App live sur les deux stores

Temps total : ~3-5 jours (dont 1-3 jours d'attente review Apple)
```

---

## 3. Pipeline 2 : Data packs — OTA updates

### 3.1. Rappel du mécanisme (skill 14)

Les data packs sont des fichiers JSON statiques distribués via CDN. L'app les télécharge pendant l'onboarding et vérifie les mises à jour au lancement (si online).

```
CYCLE DE VIE D'UN DATA PACK UPDATE :

1. Tu modifies un fichier JSON dans shoothelper-data/sources/
2. PR → CI valide (schéma, cross-refs, i18n) → merge
3. GitHub Actions build : minifie, génère manifests, checksums → déploie sur CDN
4. Le manifest.json sur le CDN a une nouvelle pack_version
5. L'utilisateur ouvre l'app → check silencieux manifest
6. pack_version locale ≠ distante → badge "MAJ disponible" dans settings
7. L'utilisateur tape "Mettre à jour" → download + atomic swap
8. Données à jour, aucune mise à jour de l'app nécessaire
```

### 3.2. Indépendance app ↔ data pack

| Scénario | App version | Data pack version | Résultat |
|----------|-----------|------------------|---------|
| Première install | 1.0.0 | Télécharge la dernière (ex: 1.1.0) | Fonctionne |
| App pas mise à jour, data pack corrigé | 1.0.0 | 1.0.0 → 1.0.1 (OTA) | L'app 1.0.0 utilise le data pack 1.0.1 |
| App mise à jour, pas de nouveau data pack | 1.0.0 → 1.0.1 | 1.0.0 (inchangé) | L'app 1.0.1 utilise le data pack 1.0.0 |
| Breaking change data pack | 1.0.0 | 2.0.0 (min_app_version: 2.0.0) | L'app 1.0.0 ignore la MAJ. Message "Mets à jour l'app." |

Le champ `min_app_version` dans le manifest protège contre l'incompatibilité : si le data pack v2.0.0 nécessite un format que l'app v1.x ne comprend pas, l'utilisateur est invité à mettre à jour l'app d'abord.

### 3.3. Fréquence des updates OTA

| Type de changement | Fréquence estimée | Exemples |
|-------------------|-------------------|----------|
| Correction de chemin menu | Hebdomadaire (au début) | Typo dans un label FR, chemin incorrect |
| Ajout d'un objectif | Mensuel | Nouvel objectif populaire pour un boîtier existant |
| Ajout d'un boîtier | Trimestriel | Nouveau modèle lancé par un constructeur |
| Mise à jour firmware | Trimestriel | Sony publie un firmware avec de nouveaux menus |
| Breaking change format | Annuel (ou jamais) | Restructuration du format JSON |

Les corrections et ajouts d'objectifs sont les plus fréquents — et c'est exactement le cas d'usage de l'OTA. Publier une nouvelle version de l'app pour corriger un label serait disproportionné.

---

## 4. Configuration des stores

### 4.1. Google Play Store

**Identité de l'app :**

| Champ | Valeur |
|-------|--------|
| Package name | `app.shoothelper` |
| App name | ShootHelper |
| Category | Photography |
| Content rating | Everyone |
| Pricing | Free |
| Target age group | 13+ |

**Fiche Play Store :**

```
Titre : ShootHelper — Réglages photo & vidéo
Sous-titre : Les réglages optimaux pour ton appareil, expliqués.

Description courte (80 chars) :
Dis-moi ce que tu veux shooter, je te dis quoi régler et où le trouver.

Description longue :
ShootHelper est ton assistant photo pour le mode manuel. Décris ta scène,
l'app calcule les réglages optimaux pour TON appareil et te montre exactement
où les trouver dans les menus — dans la langue de ton firmware.

✅ Fonctionne 100% hors ligne après le setup initial
✅ Supporte Sony, Canon, Nikon, Fujifilm (14 boîtiers)
✅ Chemins de menu exacts, dans ta langue
✅ Explications de chaque réglage et pourquoi
✅ Compromis signalés avec alternatives

Boîtiers supportés :
Sony A6700, A6400, A7 IV, A7C II
Canon R50, R10, R7, R6 Mark II
Nikon Z50 II, Z30, Zf, Z6 III
Fujifilm X-T5, X-S20

ShootHelper n'est pas affilié à Sony, Canon, Nikon ou Fujifilm.
```

**Screenshots :** 5-8 screenshots montrant le flow principal (Scene Input → Résultats → Menu Navigation) sur un Pixel 8 (phone) et un Pixel Tablet (tablet optionnel).

**Configuration build :**

```groovy
// android/app/build.gradle

android {
    namespace "app.shoothelper"
    compileSdk 35

    defaultConfig {
        applicationId "app.shoothelper"
        minSdk 24
        targetSdk 35
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 4.2. Apple App Store

**Identité de l'app :**

| Champ | Valeur |
|-------|--------|
| Bundle ID | `app.shoothelper` |
| App name | ShootHelper |
| Primary category | Photo & Video |
| Pricing | Free |
| Age rating | 4+ |

**App Store Connect :**

```
Nom : ShootHelper — Réglages photo
Sous-titre : Réglages optimaux, menus guidés.
Mots-clés : photo,réglages,appareil photo,manuel,ISO,ouverture,Sony,Canon,Nikon
URL marketing : https://shoothelper.app (V2)
URL support : https://github.com/shoothelper/shoothelper-app/issues
```

**Configuration iOS :**

```yaml
# ios/Runner/Info.plist (extraits clés)

CFBundleIdentifier: app.shoothelper
CFBundleDisplayName: ShootHelper
CFBundleShortVersionString: $(FLUTTER_BUILD_NAME)    # 1.0.0
CFBundleVersion: $(FLUTTER_BUILD_NUMBER)              # 1
MinimumOSVersion: 13.0
LSRequiresIPhoneOS: true
UIRequiredDeviceCapabilities: [arm64]
```

**Permissions demandées :** Aucune. L'app n'utilise ni la caméra, ni la localisation, ni les contacts, ni rien d'autre. C'est un avantage pour la review Apple — zéro justification de permission à fournir.

### 4.3. Disclaimer juridique (dans les deux stores)

```
ShootHelper n'est pas affilié à, ni approuvé par Sony Corporation,
Canon Inc., Nikon Corporation, ou FUJIFILM Corporation.
Les noms de produits sont la propriété de leurs détenteurs respectifs.
Les données de menus sont dérivées de la documentation publique officielle.
```

---

## 5. Versioning de l'app

### 5.1. Convention semver

```
MAJOR.MINOR.PATCH+BUILD

1.0.0+1     → MVP launch
1.0.1+2     → Bugfix (ex: crash sur un boîtier spécifique)
1.1.0+3     → Feature mineure (ex: amélioration UX Scene Input)
2.0.0+4     → Feature majeure (ex: Historique & Favoris)

Flutter utilise :
  version: 1.0.0+1 dans pubspec.yaml
  versionName = "1.0.0"  (affiché à l'utilisateur)
  versionCode = 1          (numéro incrémental pour les stores)
```

### 5.2. pubspec.yaml

```yaml
name: shoothelper
description: Camera settings advisor with menu navigation.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Navigation
  go_router: ^14.0.0

  # Data
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  dio: ^5.4.0
  connectivity_plus: ^6.0.0

  # UI
  flutter_hooks: ^0.20.0
  hooks_riverpod: ^2.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  mocktail: ^1.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/brands/
```

---

## 6. Taille de l'app

### 6.1. Budget de taille

| Composant | Taille estimée |
|-----------|---------------|
| Flutter engine (Impeller) | ~8 MB |
| Code Dart compilé AOT | ~3 MB |
| Assets (icônes, fonts) | ~1 MB |
| Données embarquées (setting_defs fallback) | < 10 KB |
| **Total APK** | **~15-18 MB** |
| **Total IPA** | **~20-25 MB** |

Les data packs (~250 KB par boîtier) ne sont PAS inclus dans l'app — ils sont téléchargés après l'installation. L'app est donc légère au téléchargement initial.

### 6.2. Optimisations de taille

```yaml
# android/app/build.gradle
buildTypes {
    release {
        minifyEnabled true        # Supprime le code inutilisé
        shrinkResources true      # Supprime les resources inutilisées
    }
}
```

```
# Build avec split par ABI (réduit la taille par device)
flutter build appbundle --release
# L'App Bundle laisse Google Play servir uniquement le code pour le CPU du device
# Résultat : ~12 MB téléchargé au lieu de ~18 MB
```

---

## 7. Environnements

### 7.1. Trois environnements

| Env | CDN URL | Usage |
|-----|---------|-------|
| `dev` | `http://localhost:8080/data/` | Développement local (serveur Python simple) |
| `staging` | `https://staging-data.shoothelper.app/` | Tests pré-release (branche CDN séparée) |
| `prod` | `https://data.shoothelper.app/` | Production |

### 7.2. Configuration par environnement

```dart
// lib/core/config/app_config.dart

enum AppEnvironment { dev, staging, prod }

class AppConfig {
  final AppEnvironment environment;
  final String cdnBaseUrl;
  final String healthCheckUrl;
  final bool enableLogging;

  const AppConfig._({
    required this.environment,
    required this.cdnBaseUrl,
    required this.healthCheckUrl,
    required this.enableLogging,
  });

  static const dev = AppConfig._(
    environment: AppEnvironment.dev,
    cdnBaseUrl: 'http://localhost:8080/data',
    healthCheckUrl: 'http://localhost:8080/data/health.json',
    enableLogging: true,
  );

  static const staging = AppConfig._(
    environment: AppEnvironment.staging,
    cdnBaseUrl: 'https://staging-data.shoothelper.app',
    healthCheckUrl: 'https://staging-data.shoothelper.app/health.json',
    enableLogging: true,
  );

  static const prod = AppConfig._(
    environment: AppEnvironment.prod,
    cdnBaseUrl: 'https://data.shoothelper.app',
    healthCheckUrl: 'https://data.shoothelper.app/health.json',
    enableLogging: false,
  );
}
```

```dart
// lib/main.dart (sélection par --dart-define)

void main() {
  const env = String.fromEnvironment('ENV', defaultValue: 'prod');
  final config = switch (env) {
    'dev' => AppConfig.dev,
    'staging' => AppConfig.staging,
    _ => AppConfig.prod,
  };

  runApp(ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
    ],
    child: const App(),
  ));
}
```

```bash
# Build par environnement
flutter run --dart-define=ENV=dev
flutter build apk --dart-define=ENV=staging
flutter build apk --dart-define=ENV=prod    # défaut
```

---

## 8. Beta testing

### 8.1. Circuit de test avant publication

```
CIRCUIT :

1. Dev local (toi)
   → flutter run sur ton téléphone
   → Test des features + régressions

2. Internal testing (Play Store / TestFlight)
   → Build automatique via CI sur tag
   → Installable par toi sur plusieurs devices
   → Test sur iOS + Android réels

3. Closed beta (optionnel, V2)
   → 10-20 testeurs (amis photographes)
   → Firebase App Distribution ou TestFlight external
   → Feedback structuré

4. Production
   → Promouvoir sur les stores
```

### 8.2. Firebase App Distribution (alternative rapide)

Pour distribuer des builds de test sans passer par les stores :

```yaml
# Dans le workflow release.yml, ajouter :
- name: Upload to Firebase App Distribution
  uses: wzieba/Firebase-Distribution-Github-Action@v1
  with:
    appId: ${{ secrets.FIREBASE_APP_ID_ANDROID }}
    serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
    file: build/app/outputs/flutter-apk/app-release.apk
    groups: internal-testers
    releaseNotes: "Build ${{ github.ref_name }}"
```

Avantage : distribution instantanée, pas de review. Utile pour les builds quotidiens pendant le développement actif.

---

## 9. Monitoring post-launch (MVP minimal)

### 9.1. Ce qu'on veut savoir

| Question | Source |
|----------|--------|
| L'app crash-t-elle ? | Crashlytics (V2) ou logs locaux |
| Combien d'utilisateurs ? | Play Console + App Store Connect analytics |
| Quels boîtiers sont populaires ? | CDN logs (quels body_id sont téléchargés) |
| Quels boîtiers manquent ? | Feedback "Mon boîtier n'est pas listé" |
| Des chemins de menu sont faux ? | Feedback "Signaler un problème" |

### 9.2. MVP : analytics stores uniquement

Au MVP, pas de SDK analytics dans l'app. Les Play Console et App Store Connect fournissent gratuitement :

- Nombre d'installations et désinstallations
- Pays / langue des utilisateurs
- Modèles de téléphones
- Crashs (Android vitals / MetricKit)
- Ratings et reviews

C'est suffisant pour valider le product-market fit sans intégrer Firebase Analytics.

### 9.3. V2 : Firebase Crashlytics + Analytics

```yaml
# pubspec.yaml (V2)
dependencies:
  firebase_core: ^3.0.0
  firebase_crashlytics: ^4.0.0
  firebase_analytics: ^11.0.0
```

Événements custom à tracker en V2 :

| Événement | Paramètres | Pourquoi |
|-----------|-----------|----------|
| `onboarding_complete` | `body_id`, `lens_count`, `firmware_lang` | Comprendre le profil utilisateur |
| `calculate_settings` | `subject`, `intention`, `environment` | Quels scénarios sont les plus utilisés |
| `view_menu_nav` | `setting_id`, `body_id` | Quel réglage nécessite le plus de guidage |
| `data_pack_update` | `body_id`, `from_version`, `to_version` | Taux d'adoption des MAJ |
| `error_displayed` | `failure_type` | Quelles erreurs les utilisateurs rencontrent |

---

## 10. Processus de hotfix

### 10.1. Hotfix app (bug critique)

```
1. Créer branche fix/critical-bug depuis main
2. Fix + test
3. PR → main (fast-track review, CI doit passer)
4. Merge + tag v1.0.1
5. CI build + publish automatique
6. Android : promouvoir internal → production (instantané)
7. iOS : submit for expedited review (Apple propose un fast-track pour les crashs critiques)

Temps : 1-2 jours (dont review Apple)
```

### 10.2. Hotfix data pack (chemin menu faux)

```
1. Corriger le JSON dans shoothelper-data/sources/
2. Incrémenter _pack_version (1.0.0 → 1.0.1)
3. PR → main (CI valide) → merge
4. GitHub Actions déploie sur le CDN automatiquement
5. Les utilisateurs voient "MAJ disponible" au prochain lancement

Temps : 5 minutes. Pas de review de store.
```

C'est l'avantage majeur de l'architecture OTA : un chemin de menu incorrect est corrigé en 5 minutes, pas en 3 jours.

---

## 11. Checklist pré-launch

### 11.1. Technique

```
☐ Tous les tests passent (72 scénarios)
☐ Build release iOS sans warning
☐ Build release Android sans warning
☐ Testé sur iPhone (modèle récent + ancien compatible iOS 13)
☐ Testé sur Android (Pixel récent + device entrée de gamme API 24)
☐ Testé offline après setup initial (mode avion)
☐ Testé le download initial en 3G (timeout acceptable)
☐ Testé le changement de boîtier
☐ Testé le changement de langue firmware
☐ Proguard/minification ne casse pas le JSON parsing
☐ Les data packs sont déployés sur le CDN
☐ Le catalog.json liste tous les boîtiers MVP
☐ health.json répond sur le CDN
```

### 11.2. Stores

```
☐ Compte développeur Google Play (~25$ one-time)
☐ Compte développeur Apple (~99$/an)
☐ Fiche Play Store complète (description, screenshots, catégorie)
☐ Fiche App Store complète (description, screenshots, keywords)
☐ Icône de l'app (1024×1024, fond non transparent pour Apple)
☐ Politique de confidentialité hébergée (même une page GitHub suffit)
☐ Disclaimer "pas affilié à Sony/Canon/Nikon/Fuji"
☐ Content rating questionnaire rempli (Play Store)
☐ Age rating questionnaire rempli (App Store)
☐ Export compliance (pas de cryptographie custom → exempt)
```

### 11.3. Data

```
☐ Au moins 3 boîtiers complets (Sony A6700, Canon R50, Nikon Z50 II)
☐ Au moins 3 objectifs par boîtier
☐ Labels FR + EN validés (spot check boîtier en main)
☐ Les 15 NavPaths fonctionnent pour chaque boîtier
☐ Manifests générés avec checksums corrects
☐ Catalog.json à jour
```

---

## 12. Coûts

### 12.1. Coûts fixes

| Poste | Coût | Fréquence |
|-------|------|-----------|
| Compte Google Play Developer | 25$ | One-time |
| Apple Developer Program | 99$/an | Annuel |
| **Total année 1** | **~125$** | |

### 12.2. Coûts variables (MVP = 0$)

| Poste | Solution MVP | Coût | Seuil de migration |
|-------|-------------|------|-------------------|
| CDN data packs | GitHub Pages | 0$ | > 400K downloads/mois |
| CI/CD | GitHub Actions (free tier) | 0$ | > 2000 min/mois |
| Monitoring | Store analytics | 0$ | Quand besoin de Crashlytics |
| Domain custom | Pas nécessaire MVP | 0$ | Quand tu veux un site web |

### 12.3. Coûts V2 (si l'app grandit)

| Poste | Solution | Coût estimé |
|-------|---------|------------|
| CDN | Cloudflare R2 | ~0$ (pas de frais egress) |
| CI/CD | GitHub Actions | ~0-10$/mois |
| Domain | shoothelper.app | ~12$/an |
| Crashlytics | Firebase (free tier) | 0$ |
| Analytics | Firebase (free tier) | 0$ |
| **Total V2** | | **~25$/an en plus du dev program** |

**Budget total réaliste année 1 : ~125$.** Essentiellement les frais des stores.

---

## 13. Timeline de lancement recommandée

```
SEMAINE 1-3   : Apprendre Flutter (skill 08 plan d'apprentissage)
SEMAINE 4-6   : Scaffolding architecture + data packs (Sony A6700 only)
SEMAINE 7-9   : Settings Engine + Scene Input + Results
SEMAINE 10-11 : Menu Navigation Mapper + polish UI
SEMAINE 12    : Data packs Canon R50 + Nikon Z50 II
SEMAINE 13    : Testing (72 scénarios) + bugfixes
SEMAINE 14    : Beta interne + corrections finales
SEMAINE 15    : Soumission aux stores
SEMAINE 16    : 🚀 Launch

TOTAL : ~4 mois de dev à temps partiel (side project)
```

Ce planning est serré mais réaliste pour un dev solo motivé avec les 22 skills comme référence. Le facteur limitant n'est pas le code — c'est le data entry des menus caméra (~50h pour les 3 premiers boîtiers).

---

## 14. Post-launch

### 14.1. Première semaine

```
JOUR 1-2 :
  → Surveiller Android Vitals et les reviews
  → Hotfix immédiat si crash critique

JOUR 3-5 :
  → Corriger les chemins de menu signalés (OTA, 5 min chacun)
  → Répondre aux reviews des stores

JOUR 7 :
  → Analyser : quels boîtiers sont les plus téléchargés
  → Prioriser les prochains boîtiers à ajouter
```

### 14.2. Premier mois

```
SEMAINE 2-3 :
  → Ajouter 2-3 boîtiers supplémentaires (data packs OTA)
  → Commencer les objectifs tiers populaires (Sigma, Tamron)

SEMAINE 4 :
  → Version 1.1.0 avec les améliorations UX issues du feedback
  → Planifier les features V2 (historique, favoris, vidéo avancé)
```

---

## 15. Résumé

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║  DEUX PIPELINES, DEUX VITESSES :                                 ║
║                                                                  ║
║  APP (code) :                                                    ║
║    GitHub → CI tests → Build iOS+Android → Stores                ║
║    ~3-5 jours du tag au live                                     ║
║    Toutes les 2-4 semaines                                       ║
║                                                                  ║
║  DATA PACKS (contenu) :                                          ║
║    GitHub → CI validation → CDN statique                         ║
║    ~5 minutes du push au live                                    ║
║    À tout moment, sans review de store                           ║
║                                                                  ║
║  COÛT TOTAL ANNÉE 1 : ~125$                                      ║
║  (25$ Google + 99$ Apple + 0$ infrastructure)                    ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

*Ce document conclut les 22 skills de ShootHelper. Tous les skills sont maintenant des documents de référence complets, traçables entre eux, et prêts à guider le développement. La prochaine étape : ouvrir un IDE et coder.*
