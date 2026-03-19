# Tech Stack Decision — ShootHelper

> **Skill 08/22** · Choix de la stack technique mobile
> Version 1.0 · Mars 2026
> Réf : 01_PRD.md, 04_CAMERA_DATA_ARCHITECTURE.md

---

## 1. Contexte de la décision

Ce document tranche une question : **quelle technologie pour développer l'app mobile ShootHelper ?**

La décision doit être prise en fonction des **contraintes spécifiques du projet**, pas des benchmarks génériques. Rappel des contraintes clés :

| Contrainte | Impact sur le choix |
|-----------|-------------------|
| Développeur solo (toi) | Un seul codebase, pas deux |
| Offline-first | Stockage local performant obligatoire |
| Calcul local pur (Settings Engine) | Pas de bridge JS/natif intensif |
| Données JSON (~250KB) | Parsing et navigation de structures JSON |
| UI data-driven, pas animation-heavy | Listes, cards, breadcrumbs — pas de 3D ni de canvas |
| iOS + Android | Cross-platform obligatoire |
| Side project, budget zéro | Pas de licence payante |
| Étudiant en info, bases en Python/PHP/Angular | Pas d'expérience mobile native |

---

## 2. Options évaluées

| Option | Langage | Éditeur | Principe |
|--------|---------|---------|----------|
| **Flutter** | Dart | Google | Rendu custom (Impeller), tout est widget |
| **React Native** | JavaScript/TypeScript | Meta | Bridge vers composants natifs (New Architecture / Fabric) |
| **Kotlin Multiplatform (KMP) + Compose** | Kotlin | JetBrains/Google | Logique partagée + UI native ou Compose Multiplatform |
| **Swift + Kotlin natif** | Swift / Kotlin | Apple / Google | Deux apps séparées, 100% natif |

KMP et natif pur sont inclus pour complétude mais éliminés rapidement — les arguments sont quand même documentés.

---

## 3. Grille d'évaluation

### 3.1. Critère 1 — Codebase unique (Éliminatoire)

| Option | Codebase unique | Verdict |
|--------|----------------|---------|
| Flutter | ✅ Un seul codebase Dart | ✅ |
| React Native | ✅ Un seul codebase JS/TS | ✅ |
| KMP + Compose Multiplatform | ✅ Logique partagée + UI partagée (depuis mai 2025 stable iOS) | ✅ |
| Swift + Kotlin natif | ❌ Deux codebases | ❌ Éliminé |

**Swift + Kotlin natif est éliminé.** Dev solo = un seul codebase, point final.

### 3.2. Critère 2 — Offline-first & stockage local

L'app repose sur du JSON local (~250KB) et potentiellement SQLite en V2. Le stockage local doit être de première classe, pas un afterthought.

| Option | Stockage local | Écosystème offline |
|--------|---------------|-------------------|
| **Flutter** | sqflite (mature), Drift (ORM type-safe, réactif, migrations), Hive (NoSQL) | Excellent. Drift est le standard pour l'offline-first Flutter. Documentation officielle Flutter avec exemple SQL architecture pattern. |
| **React Native** | react-native-sqlite-storage, WatermelonDB, op-sqlite | Bon. WatermelonDB est optimisé offline-first. Mais l'écosystème est plus fragmenté, certains packages ont des maintenances irrégulières. |
| **KMP** | SQLDelight (mature, cross-platform) | Bon pour la logique, mais l'écosystème mobile est plus jeune. |

**Avantage Flutter.** L'écosystème Drift + sqflite est le plus mature et le mieux documenté pour l'offline-first. Les docs officielles Flutter ont un pattern d'architecture SQL dédié.

### 3.3. Critère 3 — Performance du moteur de calcul

Le Settings Engine fait des calculs purs (math, arbres de décision) sur des données locales. Pas de rendu GPU, pas de bridge intensif.

| Option | Perf calcul | Note |
|--------|------------|------|
| **Flutter** | Dart AOT compilé en natif. Calcul pur = quasi-natif. | Excellent |
| **React Native** | JS via Hermes (bytecode). Plus lent que Dart AOT pour du calcul pur, mais le moteur est si léger (< 1ms) que c'est invisible. | Suffisant |
| **KMP** | Kotlin natif. Performance identique au natif. | Excellent |

**Non-discriminant.** Le moteur est trop léger pour que la performance soit un facteur. Même JS/Hermes le calcule en < 5ms.

### 3.4. Critère 4 — Parsing JSON

L'app charge et navigue des structures JSON (~250KB). Parsing au démarrage + lookups fréquents.

| Option | Parsing JSON | Note |
|--------|-------------|------|
| **Flutter** | `dart:convert` natif + code generation (json_serializable, freezed). Type-safe. | Excellent |
| **React Native** | JSON natif en JS. Parsing trivial, pas de code generation nécessaire. | Excellent |
| **KMP** | kotlinx.serialization. Type-safe, mature. | Excellent |

**Non-discriminant.** Les trois gèrent parfaitement le JSON.

### 3.5. Critère 5 — Courbe d'apprentissage (pour ton profil)

Tu as de l'expérience en Python, PHP, Angular (TypeScript), et tu as fait du PySide6/Qt.

| Option | Langage | Familiarité | Courbe |
|--------|---------|-------------|--------|
| **Flutter** | Dart | Syntaxe proche de Java/TypeScript. OOP classique. Facile à apprendre pour quelqu'un qui connaît TS. | ~2-3 semaines productif |
| **React Native** | TypeScript | Tu connais Angular (TypeScript). React est différent d'Angular (JSX vs templates) mais le langage est familier. | ~2-3 semaines productif |
| **KMP** | Kotlin | Proche de Java/Dart. Mais l'écosystème Compose Multiplatform est plus jeune, moins de tutos. | ~4-6 semaines productif |

**Flutter et React Native sont à égalité.** Dart te sera aussi naturel que TypeScript. KMP est plus lent à cause de l'écosystème plus jeune.

### 3.6. Critère 6 — UI & composants

L'UI de ShootHelper est data-driven : listes de réglages, cards expandables, chips de sélection, breadcrumbs de navigation menu. Pas d'animations complexes, pas de canvas custom.

| Option | Composants UI | Design system |
|--------|--------------|---------------|
| **Flutter** | Material 3 intégré, tout est widget. Chips, cards, lists, expansion tiles = natifs. | Flutter contrôle chaque pixel. UI identique iOS/Android. |
| **React Native** | Composants natifs par plateforme. Besoin de librairies tierces pour certains composants (pas de chips natifs par défaut). | Look & feel natif par plateforme (différent iOS vs Android). |
| **KMP** | Compose Multiplatform = Material 3 intégré. Similaire à Flutter dans l'approche. | UI identique iOS/Android (comme Flutter). |

**Avantage Flutter.** Les composants nécessaires (Chips, ExpansionTile, BottomSheet, Stepper) existent nativement dans le SDK. Pas de dépendance tierce pour l'UI de base. React Native nécessite des libs tierces pour certains éléments clés de notre UI.

### 3.7. Critère 7 — Taille de l'app

| Option | Taille APK/IPA (app simple) | Note |
|--------|---------------------------|------|
| **Flutter** | ~15-20 MB (inclut le moteur Impeller) | Acceptable |
| **React Native** | ~20-25 MB (Expo), ~10-15 MB (bare) | Comparable |
| **KMP** | ~10-15 MB | Plus léger |

**Non-discriminant.** Les différences sont marginales pour une app utilitaire.

### 3.8. Critère 8 — Écosystème & communauté

| Option | Stars GitHub | Stack Overflow | Maturité |
|--------|------------|----------------|----------|
| **Flutter** | ~170K | 9.12% usage (SO 2025) | Mature (Production Era, v3.38+) |
| **React Native** | ~121K | 8.43% usage (SO 2025) | Mature (New Architecture stable) |
| **KMP** | ~16K | Faible | En croissance (Compose Multiplatform iOS stable mai 2025) |

**Flutter a l'écosystème le plus actif en 2026.** Plus de packages, plus d'issues résolues sur GitHub, documentation officielle plus complète. React Native a un écosystème npm massif mais plus fragmenté. KMP est trop jeune.

### 3.9. Critère 9 — Outillage & DX

| Option | Hot Reload | Testing | IDE | CI/CD |
|--------|-----------|---------|-----|-------|
| **Flutter** | ✅ Hot reload + hot restart | Widget tests, unit tests, integration tests — tout intégré | VS Code, Android Studio | Excellent (GitHub Actions, Codemagic) |
| **React Native** | ✅ Fast Refresh | Jest, Detox. Moins intégré que Flutter. | VS Code, WebStorm | Bon (EAS Build, GitHub Actions) |
| **KMP** | ⚠️ Preview compose, pas de hot reload iOS | Kotlin test, mais tooling UI test immature | Android Studio / IntelliJ | En progrès |

**Avantage Flutter.** Le tooling est le plus intégré et le plus mature. Le testing est de première classe. Le hot reload est rock-solid.

### 3.10. Critère 10 — Pérennité & backing

| Option | Éditeur | Risque |
|--------|---------|--------|
| **Flutter** | Google | Google a un historique de kill de produits, mais Flutter est en "Production Era" et utilisé en interne (Google Pay, Google Ads). Risque faible. |
| **React Native** | Meta | Meta l'utilise massivement (Facebook, Instagram, Messenger). Risque très faible. |
| **KMP** | JetBrains/Google | JetBrains très engagé. Google pousse Kotlin comme langage Android. Risque faible mais écosystème mobile plus jeune. |

**Non-discriminant.** Les trois sont pérennes.

---

## 4. Tableau récapitulatif

| Critère | Poids | Flutter | React Native | KMP |
|---------|-------|---------|-------------|-----|
| Codebase unique | Éliminatoire | ✅ | ✅ | ✅ |
| Offline-first & stockage local | ★★★★★ | ⬛⬛⬛⬛⬛ | ⬛⬛⬛⬜⬜ | ⬛⬛⬛⬜⬜ |
| Performance calcul | ★★☆☆☆ | ⬛⬛⬛⬛⬛ | ⬛⬛⬛⬛⬜ | ⬛⬛⬛⬛⬛ |
| Parsing JSON | ★★★☆☆ | ⬛⬛⬛⬛⬛ | ⬛⬛⬛⬛⬛ | ⬛⬛⬛⬛⬛ |
| Courbe d'apprentissage | ★★★★☆ | ⬛⬛⬛⬛⬜ | ⬛⬛⬛⬛⬜ | ⬛⬛⬛⬜⬜ |
| Composants UI | ★★★★☆ | ⬛⬛⬛⬛⬛ | ⬛⬛⬛⬜⬜ | ⬛⬛⬛⬛⬜ |
| Taille app | ★☆☆☆☆ | ⬛⬛⬛⬜⬜ | ⬛⬛⬛⬜⬜ | ⬛⬛⬛⬛⬜ |
| Écosystème & communauté | ★★★★☆ | ⬛⬛⬛⬛⬛ | ⬛⬛⬛⬛⬜ | ⬛⬛⬜⬜⬜ |
| Outillage & DX | ★★★★☆ | ⬛⬛⬛⬛⬛ | ⬛⬛⬛⬛⬜ | ⬛⬛⬛⬜⬜ |
| Pérennité | ★★★☆☆ | ⬛⬛⬛⬛⬜ | ⬛⬛⬛⬛⬛ | ⬛⬛⬛⬛⬜ |

---

## 5. Décision : Flutter

**Flutter est le choix recommandé pour ShootHelper.**

### 5.1. Pourquoi Flutter gagne

**Offline-first de première classe.** L'écosystème Drift/sqflite est le plus mature pour le stockage local structuré. C'est le cœur technique de l'app — la qualité du stockage local n'est pas négociable.

**Composants UI natifs pour notre besoin.** Chips, ExpansionTile, Stepper, BottomSheet, SearchBar — tout ce que l'UI de ShootHelper utilise existe dans le SDK Flutter sans dépendance tierce. En React Native, il faudrait assembler 3-4 libs pour la même chose.

**Meilleur tooling pour un dev solo.** Le testing est intégré (widget tests, unit tests), le hot reload est fiable, la documentation est exhaustive. Quand tu es seul, l'outillage compte double.

**Dart est facile à apprendre.** La syntaxe est un mélange de Java et TypeScript — familier vu ton profil Angular. Le type system est strict, ce qui aide à éviter les bugs dans un projet solo sans code review.

**Rendu identique iOS/Android.** Flutter dessine chaque pixel. L'UI sera identique sur les deux plateformes. Pour un dev solo, ne pas avoir à tester et ajuster des différences de rendu entre iOS et Android, c'est un gain de temps énorme.

### 5.2. Pourquoi pas React Native

React Native est un excellent framework, et si tu avais une forte préférence pour TypeScript/React ou un écosystème web existant à réutiliser, ce serait le bon choix. Mais pour ShootHelper :

- L'écosystème stockage local est plus fragmenté (WatermelonDB vs react-native-sqlite-storage vs op-sqlite — lequel choisir ?)
- Les composants UI nécessaires demandent des libs tierces avec des niveaux de maintenance variables
- La New Architecture (Fabric/JSI) est stable mais plus récente que le moteur Flutter — plus de risques de breaking changes
- Le tooling testing est moins intégré (Jest + Detox = deux outils séparés vs le testing unifié Flutter)

### 5.3. Pourquoi pas KMP

Kotlin Multiplatform est prometteur mais trop jeune pour un side project en 2026 :

- Compose Multiplatform pour iOS est stable depuis mai 2025 seulement — moins d'un an
- L'écosystème de packages est significativement plus petit
- Moins de tutoriels, moins de solutions sur Stack Overflow
- Le temps d'apprentissage est plus long pour un bénéfice non prouvé

KMP sera peut-être le meilleur choix dans 2-3 ans. Pas aujourd'hui pour ce projet.

---

## 6. Stack technique complète

### 6.1. Core

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **Framework** | Flutter 3.38+ | Décision ci-dessus |
| **Langage** | Dart 3.x | Livré avec Flutter |
| **IDE** | VS Code + extensions Flutter/Dart | Léger, gratuit, familier |
| **Min SDK** | iOS 13+ / Android API 24+ (Android 7.0) | Couvre ~98% des appareils actifs |

### 6.2. Stockage local

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **Data packs (JSON)** | Fichiers JSON dans app documents directory | Lecture simple, pas besoin de BDD pour des données statiques |
| **Profil gear** | SharedPreferences (ou Drift) | Données simples clé-valeur |
| **BDD locale (V2)** | Drift (ORM SQLite) | Si on migre vers SQLite : type-safe, réactif, migrations, bien documenté |
| **Cache** | path_provider + File I/O | Gestion du filesystem local |

**Stratégie MVP** : les data packs restent en JSON fichier. SharedPreferences pour le profil gear. On migre vers Drift seulement si la performance ou la complexité des requêtes l'exige.

### 6.3. State management

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **State management** | Riverpod 2.x | Le standard Flutter actuel. Type-safe, testable, pas de BuildContext hell. Plus moderne que Provider, plus simple que BLoC pour notre app. |

Riverpod est le choix pour ShootHelper parce que :
- L'app a un state relativement simple (gear sélectionné, scène en cours, résultats)
- Pas de flux de données complexes justifiant BLoC
- Riverpod gère nativement l'injection de dépendances (utile pour les tests)
- Documentation excellente, patterns bien établis

### 6.4. Réseau (download data packs)

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **HTTP client** | Dio | Plus riche que http : interceptors, cancel tokens, download progress |
| **Connectivité** | connectivity_plus | Détection online/offline |

### 6.5. Navigation

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **Router** | GoRouter | Le router déclaratif officiel Flutter. Deep linking, routes typées, guards. |

### 6.6. UI

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **Design system** | Material 3 (intégré Flutter) | Composants natifs : Chips, Cards, ExpansionTile, BottomSheet, Stepper |
| **Icônes** | Material Icons + quelques custom SVG | Suffisant pour le MVP |
| **Fonts** | Google Fonts (package) | Accès facile aux fonts custom si besoin |

### 6.7. Internationalisation

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **i18n app (Couche 1)** | flutter_localizations + intl + ARB files | Standard Flutter officiel. Génération de code type-safe. |
| **i18n firmware (Couche 2)** | Custom (labels JSON inline, skill 07) | Pas de framework i18n — les données sont per-boîtier |

### 6.8. Testing

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **Unit tests** | flutter_test (intégré) | Settings Engine, parsing JSON, calculs |
| **Widget tests** | flutter_test (intégré) | Composants UI isolés |
| **Integration tests** | integration_test (intégré) | Flows complets (onboarding, scène → résultats) |
| **Mocking** | mocktail | Léger, pas de code generation (contrairement à mockito) |

### 6.9. Code quality

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **Linter** | flutter_lints (intégré) + custom analysis_options.yaml | Règles strictes activées |
| **Code generation** | build_runner + json_serializable + freezed | Modèles immutables type-safe pour les data classes |
| **Formatting** | dart format (intégré) | Formatage automatique cohérent |

### 6.10. CI/CD & Distribution

| Composant | Technologie | Justification |
|-----------|------------|---------------|
| **CI** | GitHub Actions | Gratuit pour les projets publics et limité gratuit pour privé |
| **Build iOS** | Xcode (via GitHub Actions macOS runner ou local) | Requis pour l'App Store |
| **Build Android** | Gradle (via Flutter) | Intégré |
| **Distribution beta** | Firebase App Distribution ou TestFlight/Play Console internal test | Gratuit |

---

## 7. Versions & compatibilité

| Dépendance | Version minimum | Raison |
|-----------|----------------|--------|
| Flutter SDK | 3.38+ | Impeller stable Android, 16KB page size |
| Dart | 3.6+ | Livré avec Flutter 3.38 |
| iOS deployment target | 13.0 | Couvre ~98% des iPhones actifs |
| Android minSdkVersion | 24 (Android 7.0) | Couvre ~97% des appareils Android actifs |
| Android compileSdkVersion | 35 (Android 15) | Requis pour les builds Play Store 2026 |

---

## 8. Ce que cette stack ne couvre pas

| Besoin | Solution | Quand |
|--------|----------|-------|
| Backend pour distribuer les data packs | Serveur statique simple (GitHub Pages, Cloudflare R2, ou Firebase Hosting) | Skill 14 (API & Backend Design) |
| Push notifications (MAJ data pack) | firebase_messaging | V2 |
| Analytics | firebase_analytics ou local-only | V2 |
| Crash reporting | firebase_crashlytics ou Sentry | V2 |
| Monétisation | RevenueCat (in-app purchases) | V3+ |

---

## 9. Plan d'apprentissage Flutter

Si tu n'as jamais touché Flutter, voici un plan réaliste :

| Semaine | Focus | Ressource |
|---------|-------|-----------|
| S1 | Dart basics + Flutter fundamentals | docs.flutter.dev/get-started + codelabs officiels |
| S2 | Widgets, layouts, navigation (GoRouter) | Flutter cookbook + construire un prototype 2-3 écrans |
| S3 | State management (Riverpod), stockage local | Riverpod docs + tuto offline-first avec sqflite/Drift |
| S4 | Prototype ShootHelper : onboarding + scene input | Appliquer sur le vrai projet |

**Tu seras productif en ~3 semaines.** La semaine 4 est déjà du vrai dev sur ShootHelper. Dart est suffisamment proche de TypeScript pour que la transition soit fluide.

---

*Ce document est la référence pour tous les skills techniques suivants (09-15). Toutes les décisions d'architecture, de patterns et de librairies s'appuient sur cette stack Flutter/Dart.*
