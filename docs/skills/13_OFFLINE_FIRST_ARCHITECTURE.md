# Offline-First Architecture — ShootHelper

> **Skill 13/22** · Download initial, cache, détection réseau, fonctionnement 100% offline
> Version 1.0 · Mars 2026
> Réf : 02_USER_FLOWS.md, 04_CAMERA_DATA_ARCHITECTURE.md, 12_LOCAL_DATABASE_DESIGN.md

---

## 1. La promesse offline

ShootHelper fait une promesse à l'utilisateur : **après le setup initial (qui nécessite internet), l'app fonctionne 100% sans réseau.**

Ce n'est pas un "mode dégradé offline" — c'est le mode normal. L'utilisateur est sur la plage, en randonnée, en montagne. Pas de 4G, pas de Wi-Fi. L'app doit calculer ses réglages, afficher les chemins de menu, tout. Comme si le réseau n'existait pas.

Le réseau est utilisé pour exactement **3 choses** :

| Action réseau | Quand | Obligatoire |
|--------------|-------|-------------|
| Téléchargement initial du data pack | Onboarding (une seule fois) | OUI — l'app ne fonctionne pas sans |
| Ajout d'un objectif ou changement de boîtier | Action explicite de l'utilisateur | OUI pour cette action |
| Vérification de mise à jour data pack | Au lancement (si online) | NON — silencieux, optionnel |

Tout le reste = offline.

---

## 2. Les 4 états réseau de l'app

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ÉTAT 1 : PREMIER LANCEMENT (pas de data pack)                  │
│  ─────────────────────────────────────────────                  │
│  • Pas de données locales                                       │
│  • L'app DOIT avoir internet                                    │
│  • Si pas de réseau → écran bloquant "Connexion requise"        │
│  • Après download → transition vers État 3                      │
│                                                                 │
│  ÉTAT 2 : ONLINE AVEC DATA PACK                                 │
│  ──────────────────────────────                                 │
│  • Data pack présent et complet                                 │
│  • Réseau disponible                                            │
│  • L'app fonctionne normalement                                 │
│  • En arrière-plan : check silencieux de mise à jour            │
│  • L'utilisateur peut ajouter des objectifs, changer de boîtier │
│                                                                 │
│  ÉTAT 3 : OFFLINE AVEC DATA PACK (LE MODE NORMAL)              │
│  ────────────────────────────────────────────────               │
│  • Data pack présent et complet                                 │
│  • Pas de réseau                                                │
│  • L'app fonctionne à 100%                                      │
│  • Aucune fonctionnalité désactivée                             │
│  • "Ajouter un objectif" et "Changer de boîtier" sont grisés   │
│  • Le check de MAJ est silencieusement ignoré                   │
│                                                                 │
│  ÉTAT 4 : OFFLINE AVEC DATA PACK INCOMPLET                     │
│  ──────────────────────────────────────────                     │
│  • Data pack partiellement téléchargé (ex: 1 objectif manquant) │
│  • L'app fonctionne avec les données disponibles               │
│  • L'objectif manquant n'apparaît pas dans le sélecteur         │
│  • Badge "1 téléchargement en attente" dans settings            │
│  • Reprend automatiquement quand le réseau revient              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Détection réseau

### 3.1. Package

`connectivity_plus` pour la détection de connectivité.

### 3.2. Service de connectivité

```dart
// shared/data/data_sources/network/connectivity_service.dart

enum NetworkStatus { online, offline }

abstract class ConnectivityService {
  /// État actuel
  Future<NetworkStatus> get currentStatus;

  /// Stream de changements
  Stream<NetworkStatus> get statusStream;

  /// Vérification réelle (ping) — pas juste la présence de Wi-Fi
  Future<bool> hasInternetAccess();
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<NetworkStatus> get currentStatus async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) return NetworkStatus.offline;
    // Wi-Fi ou mobile présent — mais est-ce qu'on a vraiment internet ?
    return await hasInternetAccess()
        ? NetworkStatus.online
        : NetworkStatus.offline;
  }

  @override
  Stream<NetworkStatus> get statusStream {
    return _connectivity.onConnectivityChanged.asyncMap((results) async {
      if (results.contains(ConnectivityResult.none)) return NetworkStatus.offline;
      return await hasInternetAccess()
          ? NetworkStatus.online
          : NetworkStatus.offline;
    });
  }

  @override
  Future<bool> hasInternetAccess() async {
    try {
      // Ping léger vers notre CDN (ou Google DNS en fallback)
      final response = await Dio().head(
        AppConstants.healthCheckUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
```

**Pourquoi un ping en plus de `connectivity_plus` ?** Parce que `connectivity_plus` détecte la présence d'une connexion Wi-Fi ou mobile, pas la présence réelle d'internet. Un Wi-Fi d'hôtel avec un portail captif = `ConnectivityResult.wifi` mais pas d'internet. Le ping confirme l'accès réel.

### 3.3. Riverpod integration

```dart
// shared/presentation/providers/connectivity_providers.dart

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityServiceImpl();
}

@Riverpod(keepAlive: true)
Stream<NetworkStatus> networkStatus(Ref ref) {
  return ref.watch(connectivityServiceProvider).statusStream;
}

/// Raccourci booléen
@riverpod
bool isOnline(Ref ref) {
  return ref.watch(networkStatusProvider).valueOrNull == NetworkStatus.online;
}
```

### 3.4. Usage dans l'UI

```dart
// Griser un bouton quand offline
class GearSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);

    return Column(children: [
      // ...
      ElevatedButton(
        onPressed: online ? () => _addLens(context) : null,
        child: Text(online
            ? 'Ajouter un objectif'
            : 'Ajouter un objectif (connexion requise)'),
      ),
    ]);
  }
}
```

**Règle UX** : ne jamais cacher un bouton parce qu'on est offline. Le griser et expliquer pourquoi. L'utilisateur doit comprendre que la feature existe mais nécessite internet.

---

## 4. Download initial (onboarding)

### 4.1. Ce qui est téléchargé

```
Onboarding → Sélection body + lenses + langue → Download

Fichiers téléchargés :
  1. shared/setting_defs.json       (~3 KB)   — si pas déjà présent
  2. shared/brands.json             (~1 KB)   — si pas déjà présent
  3. shared/mounts.json             (~1 KB)   — si pas déjà présent
  4. packs/{body}/manifest.json     (~1 KB)
  5. packs/{body}/body.json         (~15 KB)
  6. packs/{body}/menu_tree.json    (~150 KB) — le plus gros fichier
  7. packs/{body}/nav_paths.json    (~30 KB)
  8. packs/{body}/lenses/{id}.json  (~5 KB × N objectifs)

Total estimé : ~220 KB pour 1 boîtier + 3 objectifs
Temps estimé : < 2 secondes en 4G, < 5 secondes en 3G
```

### 4.2. Pipeline de download

```
┌─────────────────────────────────────────────────────────────────┐
│                   PIPELINE DE DOWNLOAD                          │
│                                                                 │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐               │
│  │  CHECK   │ ──→ │ DOWNLOAD │ ──→ │ VALIDATE │               │
│  │ réseau   │     │ séquentiel│     │ checksum │               │
│  └──────────┘     └──────────┘     └────┬─────┘               │
│       │                                  │                     │
│       │ offline?                         │ OK?                 │
│       ▼                                  ▼                     │
│  ┌──────────┐                      ┌──────────┐               │
│  │  BLOCK   │                      │  COMMIT  │               │
│  │ "Connexion│                      │ atomic   │               │
│  │ requise"  │                      │ rename   │               │
│  └──────────┘                      └────┬─────┘               │
│                                          │                     │
│                                          ▼                     │
│                                    ┌──────────┐               │
│                                    │  UPDATE  │               │
│                                    │ download │               │
│                                    │ _state   │               │
│                                    └──────────┘               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3. Implémentation du download

```dart
// features/data_pack/domain/use_cases/download_data_pack.dart

class DownloadDataPack {
  final DataPackRepository _repo;
  final FileManager _fileManager;

  DownloadDataPack({
    required DataPackRepository repo,
    required FileManager fileManager,
  })  : _repo = repo,
        _fileManager = fileManager;

  /// Télécharge un data pack complet pour un boîtier et ses objectifs
  Future<void> execute({
    required String bodyId,
    required List<String> lensIds,
    required void Function(DownloadProgress) onProgress,
  }) async {
    final items = _buildDownloadManifest(bodyId, lensIds);
    final tempDir = 'packs/${bodyId}_temp';
    final finalDir = 'packs/$bodyId';

    try {
      // Phase 1 : Télécharger les fichiers partagés (si absents)
      await _downloadSharedIfNeeded(onProgress);

      // Phase 2 : Télécharger dans un dossier temporaire
      for (var i = 0; i < items.length; i++) {
        final item = items[i];

        onProgress(DownloadProgress(
          currentItem: item.displayName,
          itemIndex: i,
          totalItems: items.length,
          fraction: i / items.length,
        ));

        final data = await _repo.fetchFile(item.remoteUrl);
        await _fileManager.writeBytes('$tempDir/${item.localPath}', data);
      }

      // Phase 3 : Valider les checksums
      final manifest = await _fileManager.readJson('$tempDir/manifest.json');
      final expectedChecksum = manifest['checksum_sha256'] as String;
      final valid = await _validateChecksum(tempDir, expectedChecksum);

      if (!valid) {
        await _fileManager.deleteDirectory(tempDir);
        throw DataPackCorruptedException(bodyId);
      }

      // Phase 4 : Atomic swap
      if (await _fileManager.directoryExists(finalDir)) {
        await _fileManager.deleteDirectory(finalDir);
      }
      await _fileManager.renameDirectory(tempDir, finalDir);

      // Phase 5 : Mettre à jour le download_state
      await _updateDownloadState(bodyId, lensIds, manifest);

      onProgress(DownloadProgress(
        currentItem: 'Terminé',
        itemIndex: items.length,
        totalItems: items.length,
        fraction: 1.0,
      ));

    } catch (e) {
      // Nettoyage du dossier temporaire en cas d'erreur
      if (await _fileManager.directoryExists(tempDir)) {
        await _fileManager.deleteDirectory(tempDir);
      }
      rethrow;
    }
  }

  List<_DownloadItem> _buildDownloadManifest(String bodyId, List<String> lensIds) {
    return [
      _DownloadItem(
        remoteUrl: '${AppConstants.cdnBaseUrl}/$bodyId/manifest.json',
        localPath: 'manifest.json',
        displayName: 'Manifest',
      ),
      _DownloadItem(
        remoteUrl: '${AppConstants.cdnBaseUrl}/$bodyId/body.json',
        localPath: 'body.json',
        displayName: 'Specs $bodyId',
      ),
      _DownloadItem(
        remoteUrl: '${AppConstants.cdnBaseUrl}/$bodyId/menu_tree.json',
        localPath: 'menu_tree.json',
        displayName: 'Arbre menus',
      ),
      _DownloadItem(
        remoteUrl: '${AppConstants.cdnBaseUrl}/$bodyId/nav_paths.json',
        localPath: 'nav_paths.json',
        displayName: 'Chemins navigation',
      ),
      ...lensIds.map((lensId) => _DownloadItem(
        remoteUrl: '${AppConstants.cdnBaseUrl}/$bodyId/lenses/$lensId.json',
        localPath: 'lenses/$lensId.json',
        displayName: 'Objectif $lensId',
      )),
    ];
  }
}

@freezed
class DownloadProgress with _$DownloadProgress {
  const factory DownloadProgress({
    required String currentItem,
    required int itemIndex,
    required int totalItems,
    required double fraction,
  }) = _DownloadProgress;
}
```

### 4.4. Atomic swap — pourquoi c'est critique

```
PROBLÈME SANS ATOMIC SWAP :
  1. Download de body.json → OK, écrit dans packs/sony_a6700/
  2. Download de menu_tree.json → Crash réseau à 50%
  3. État : body.json = v1.1, menu_tree.json = corrompu
  4. L'app charge les fichiers → crash ou données incohérentes

SOLUTION AVEC ATOMIC SWAP :
  1. Download de body.json → OK, écrit dans packs/sony_a6700_temp/
  2. Download de menu_tree.json → Crash réseau à 50%
  3. État : packs/sony_a6700_temp/ incomplet, packs/sony_a6700/ intact
  4. L'app charge packs/sony_a6700/ → données cohérentes de la version précédente
  5. Au prochain essai : supprime _temp, recommence

Le rename (atomic swap) est la SEULE opération qui modifie les données actives.
Tant que le rename n'est pas fait, les anciennes données restent intactes.
```

---

## 5. download_state.json — Le registre de complétude

Ce fichier track quels data packs sont téléchargés, quels objectifs sont présents, et quel est l'état de chaque composant.

```json
{
  "packs": {
    "sony_a6700": {
      "status": "complete",
      "pack_version": "1.1.0",
      "firmware_version": "3.0",
      "downloaded_at": "2026-03-15T10:30:00Z",
      "body": true,
      "menu_tree": true,
      "nav_paths": true,
      "lenses": {
        "sigma_18-50_f2.8": true,
        "sony_e_16-50_f3.5-5.6": true,
        "sony_fe_50_f1.8": true
      }
    }
  },
  "shared": {
    "status": "complete",
    "downloaded_at": "2026-03-15T10:29:55Z"
  }
}
```

| Champ | Usage |
|-------|-------|
| `status` | `complete` (tout OK), `incomplete` (téléchargement partiel), `updating` (MAJ en cours) |
| `pack_version` | Version du data pack — comparée avec le serveur pour détecter les MAJ |
| `lenses.{id}` | true/false par objectif — permet de savoir quel objectif relancer |

**Qui lit ce fichier ?**

- Au démarrage : l'app vérifie que le data pack du boîtier actif est `complete`
- La feature `gear` : pour savoir quels objectifs sont disponibles
- La feature `data_pack` : pour savoir quoi re-télécharger après un échec

```dart
// shared/data/data_sources/local/download_state_source.dart

class DownloadStateSource {
  final FileManager _fm;

  DownloadStateSource(this._fm);

  Future<DownloadState> load() async {
    try {
      final json = await _fm.readJson('meta/download_state.json');
      return DownloadState.fromJson(json);
    } catch (_) {
      return const DownloadState.empty();
    }
  }

  Future<void> save(DownloadState state) async {
    await _fm.writeJson('meta/download_state.json', state.toJson());
  }

  Future<bool> isPackComplete(String bodyId) async {
    final state = await load();
    return state.packs[bodyId]?.status == 'complete';
  }

  Future<List<String>> getMissingLenses(String bodyId, List<String> expectedLensIds) async {
    final state = await load();
    final pack = state.packs[bodyId];
    if (pack == null) return expectedLensIds;

    return expectedLensIds.where((id) => pack.lenses[id] != true).toList();
  }
}
```

---

## 6. Reprise de téléchargement (resume)

### 6.1. Stratégie

Le téléchargement est **file-level resumable**, pas byte-level. Chaque fichier fait < 150 KB — les re-télécharger entièrement est plus simple que d'implémenter un HTTP Range resume.

```
REPRISE APRÈS ÉCHEC :
  1. Lire download_state.json
  2. Pour chaque composant (body, menu_tree, nav_paths, chaque lens) :
     - Si true → déjà téléchargé, skip
     - Si false ou absent → télécharger
  3. Quand tout est true → marquer le pack comme "complete"
```

### 6.2. Reprise automatique au retour du réseau

```dart
// features/data_pack/presentation/providers/auto_resume_provider.dart

/// Écoute les changements de connectivité et reprend les téléchargements
/// incomplets automatiquement
@Riverpod(keepAlive: true)
class AutoResumeDownload extends _$AutoResumeDownload {
  @override
  void build() {
    ref.listen(networkStatusProvider, (prev, next) {
      final wasOffline = prev?.valueOrNull == NetworkStatus.offline;
      final isNowOnline = next.valueOrNull == NetworkStatus.online;

      if (wasOffline && isNowOnline) {
        _resumeIncompleteDownloads();
      }
    });
  }

  Future<void> _resumeIncompleteDownloads() async {
    final downloadState = await ref.read(downloadStateSourceProvider).load();
    final gear = ref.read(currentGearProvider).valueOrNull;
    if (gear == null) return;

    final pack = downloadState.packs[gear.bodyId];
    if (pack == null || pack.status == 'complete') return;

    // Identifier les fichiers manquants
    final missingLenses = await ref.read(downloadStateSourceProvider)
        .getMissingLenses(gear.bodyId, gear.lensIds);

    if (missingLenses.isEmpty && pack.body && pack.menuTree && pack.navPaths) {
      // Tout est là, juste mettre à jour le statut
      await _markComplete(gear.bodyId);
      return;
    }

    // Reprendre le téléchargement silencieusement
    try {
      final downloadUseCase = ref.read(downloadDataPackProvider);
      await downloadUseCase.resumeIncomplete(
        bodyId: gear.bodyId,
        missingLenses: missingLenses,
        onProgress: (_) {}, // Silencieux — pas de UI
      );
    } catch (_) {
      // Échec silencieux — on réessaiera au prochain passage online
    }
  }
}
```

**Règle UX** : la reprise automatique est **silencieuse**. Pas de popup, pas de notification. L'utilisateur ne sait même pas que ça se passe. Le seul indice : un badge dans les settings qui disparaît quand tout est complet.

---

## 7. Mise à jour des data packs

### 7.1. Quand vérifier les mises à jour

```
DÉCLENCHEUR 1 : Lancement de l'app (si online)
  → Check silencieux, non-bloquant
  → L'app démarre normalement avec les données locales
  → Si MAJ dispo → badge dans settings

DÉCLENCHEUR 2 : Manuellement dans settings
  → Bouton "Vérifier les mises à jour"
  → Feedback immédiat (loading → "MAJ dispo" ou "Tout est à jour")

JAMAIS de MAJ forcée au lancement. L'utilisateur doit pouvoir
utiliser l'app immédiatement même si une MAJ est disponible.
```

### 7.2. Check de mise à jour

```dart
// features/data_pack/domain/use_cases/check_data_pack_update.dart

class CheckDataPackUpdate {
  final DataPackRepository _repo;
  final DownloadStateSource _downloadState;

  CheckDataPackUpdate({
    required DataPackRepository repo,
    required DownloadStateSource downloadState,
  })  : _repo = repo,
        _downloadState = downloadState;

  /// Vérifie si une MAJ est disponible pour le boîtier actif
  /// Retourne null si pas de MAJ, ou les détails de la MAJ
  Future<DataPackUpdate?> execute(String bodyId) async {
    final localState = await _downloadState.load();
    final localPack = localState.packs[bodyId];
    if (localPack == null) return null; // Pas installé

    // Fetch uniquement le manifest distant (~1 KB)
    final remoteManifest = await _repo.fetchManifest(bodyId);

    if (remoteManifest.packVersion == localPack.packVersion) {
      return null; // Déjà à jour
    }

    return DataPackUpdate(
      bodyId: bodyId,
      currentVersion: localPack.packVersion,
      newVersion: remoteManifest.packVersion,
      changelog: remoteManifest.changelog,
      estimatedSizeBytes: remoteManifest.totalSizeBytes,
    );
  }
}
```

### 7.3. Application de la mise à jour

La mise à jour utilise le même pipeline que le download initial (§4), avec l'atomic swap. L'app continue de fonctionner avec les anciennes données pendant le téléchargement. Le swap ne se fait qu'après validation complète.

```dart
// features/data_pack/domain/use_cases/apply_data_pack_update.dart

class ApplyDataPackUpdate {
  final DataPackRepository _repo;
  final FileManager _fileManager;
  final CameraDataCache _cache;

  Future<void> execute({
    required String bodyId,
    required List<String> lensIds,
    required void Function(DownloadProgress) onProgress,
  }) async {
    // 1. Télécharger dans _temp (même pipeline que le download initial)
    final downloader = DownloadDataPack(repo: _repo, fileManager: _fileManager);
    await downloader.execute(
      bodyId: bodyId,
      lensIds: lensIds,
      onProgress: onProgress,
    );

    // 2. Invalider le cache mémoire pour forcer un rechargement
    _cache.clear();

    // 3. Le rechargement se fait automatiquement via le provider
    // (loadCameraDataProvider se recalcule quand le cache est clear)
  }
}
```

### 7.4. Riverpod : check silencieux au lancement

```dart
// features/data_pack/presentation/providers/update_check_providers.dart

/// Vérifie les MAJ au lancement (si online), sans bloquer l'app
@Riverpod(keepAlive: true)
class UpdateChecker extends _$UpdateChecker {
  @override
  DataPackUpdate? build() {
    // Déclencher le check quand le provider est créé
    _checkOnStartup();
    return null;
  }

  Future<void> _checkOnStartup() async {
    // Attendre un peu pour ne pas ralentir le démarrage
    await Future.delayed(const Duration(seconds: 3));

    final online = ref.read(isOnlineProvider);
    if (!online) return;

    final gear = ref.read(currentGearProvider).valueOrNull;
    if (gear == null) return;

    try {
      final useCase = ref.read(checkDataPackUpdateProvider);
      final update = await useCase.execute(gear.bodyId);
      if (update != null) {
        state = update;
      }
    } catch (_) {
      // Échec silencieux — pas de réseau stable, on réessaiera
    }
  }

  void dismiss() => state = null;
}

/// Badge "MAJ disponible" pour les settings
@riverpod
bool hasUpdateAvailable(Ref ref) {
  return ref.watch(updateCheckerProvider) != null;
}
```

---

## 8. Séquence de démarrage

Voici exactement ce qui se passe quand l'utilisateur lance l'app, du tap sur l'icône jusqu'à l'écran Home.

```
┌─────────────────────────────────────────────────────────────────┐
│                    SÉQUENCE DE DÉMARRAGE                        │
│                                                                 │
│  main.dart                                                      │
│  ├── WidgetsFlutterBinding.ensureInitialized()                  │
│  ├── ProviderScope(child: App())                                │
│  └── App.build()                                                │
│       └── MaterialApp.router(routerConfig: appRouter)           │
│                                                                 │
│  GoRouter initial redirect :                                    │
│  │                                                              │
│  ├── 1. Lire onboarding_complete (SharedPreferences)            │
│  │   └── false → redirect '/onboarding' → [WelcomeScreen]      │
│  │                                                              │
│  ├── 2. Lire gear_profile (SharedPreferences / SQLite)          │
│  │   └── null → redirect '/onboarding' → [WelcomeScreen]       │
│  │                                                              │
│  ├── 3. Vérifier download_state pour le body actif              │
│  │   └── incomplete → redirect '/download/resume'               │
│  │                                                              │
│  ├── 4. Charger les données en mémoire (CameraDataCache)       │
│  │   ├── body.json → Body entity                                │
│  │   ├── lenses/*.json → Lens entities                          │
│  │   ├── menu_tree.json → MenuTree                              │
│  │   └── nav_paths.json → NavPaths                              │
│  │   Temps : ~100ms (lecture fichier + parse JSON)              │
│  │                                                              │
│  ├── 5. Afficher [HomeScreen]                                   │
│  │                                                              │
│  └── 6. (Arrière-plan) Check MAJ data pack si online            │
│       └── Si MAJ dispo → badge dans settings                    │
│                                                                 │
│  Temps total démarrage (après premier setup) : < 500ms          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

```dart
// core/router/app_router.dart

GoRouter appRouter(Ref ref) => GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final onboardingDone = await ref.read(preferencesSourceProvider)
        .isOnboardingComplete();
    if (!onboardingDone) return '/onboarding';

    final gear = await ref.read(currentGearProvider.future);
    if (gear == null) return '/onboarding';

    final packComplete = await ref.read(downloadStateSourceProvider)
        .isPackComplete(gear.bodyId);
    if (!packComplete) return '/download/resume';

    return null; // Pas de redirect → afficher '/' (Home)
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    ...onboardingRoutes,
    ...dataPackRoutes,
    ...sceneInputRoutes,
    ...resultsRoutes,
    ...menuNavRoutes,
    ...gearRoutes,
  ],
);
```

---

## 9. Matrice des fonctionnalités par état réseau

Chaque feature de l'app a un comportement défini pour chaque état réseau.

| Feature | Online + data pack | Offline + data pack | Offline + incomplet | Pas de data pack |
|---------|-------------------|--------------------|--------------------|-----------------|
| Nouveau shoot → résultats | ✅ Normal | ✅ Normal | ✅ Normal (avec les données dispo) | ❌ Bloqué |
| Navigation menu | ✅ Normal | ✅ Normal | ⚠️ Dégradé (pas de menu pour les lenses manquants) | ❌ Bloqué |
| Changer de boîtier | ✅ Normal | ❌ Grisé "Connexion requise" | ❌ Grisé | ❌ Bloqué (onboarding) |
| Ajouter un objectif | ✅ Normal | ❌ Grisé "Connexion requise" | ❌ Grisé | ❌ Bloqué (onboarding) |
| Supprimer un objectif | ✅ Normal | ✅ Normal (local) | ✅ Normal | N/A |
| Changer langue firmware | ✅ Normal | ✅ Normal (données déjà locales) | ✅ Normal | ❌ Bloqué |
| Check MAJ data pack | ✅ Normal | Silencieusement ignoré | Silencieusement ignoré | N/A |
| Appliquer MAJ data pack | ✅ Normal | ❌ Grisé | ❌ Grisé | N/A |
| Historique & favoris (V2) | ✅ Normal | ✅ Normal (tout local) | ✅ Normal | ✅ Normal |

**Observation clé** : les seules features qui nécessitent le réseau sont celles qui **téléchargent de nouvelles données** (nouveau boîtier, nouvel objectif, MAJ). Tout le flow principal est 100% offline.

---

## 10. Gestion d'erreur réseau

### 10.1. Types d'erreur

```dart
// core/errors/network_exceptions.dart

/// Pas de connexion réseau
class NoNetworkException implements Exception {
  final String message;
  const NoNetworkException([this.message = 'Pas de connexion internet']);
}

/// Timeout
class NetworkTimeoutException implements Exception {
  final String url;
  final Duration timeout;
  const NetworkTimeoutException(this.url, this.timeout);
}

/// Serveur indisponible (5xx)
class ServerException implements Exception {
  final int statusCode;
  final String url;
  const ServerException(this.statusCode, this.url);
}

/// Fichier introuvable sur le CDN (404)
class DataPackNotFoundException implements Exception {
  final String bodyId;
  const DataPackNotFoundException(this.bodyId);
}

/// Checksum invalide après téléchargement
class DataPackCorruptedException implements Exception {
  final String bodyId;
  const DataPackCorruptedException(this.bodyId);
}
```

### 10.2. Retry policy

```dart
// shared/data/data_sources/remote/retry_policy.dart

class RetryPolicy {
  static const maxRetries = 3;
  static const baseDelay = Duration(seconds: 1);

  /// Exécute une opération avec retry exponentiel
  static Future<T> execute<T>(Future<T> Function() operation) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        if (e is NoNetworkException) rethrow; // Pas de retry si pas de réseau

        final delay = baseDelay * pow(2, attempt - 1); // 1s, 2s, 4s
        await Future.delayed(delay);
      }
    }
  }
}
```

### 10.3. Messages utilisateur par type d'erreur

| Erreur | Message | Action |
|--------|---------|--------|
| `NoNetworkException` | "Pas de connexion internet. Connecte-toi pour télécharger les données." | Bouton "Réessayer" |
| `NetworkTimeoutException` | "La connexion est trop lente. Vérifie ton réseau et réessaie." | Bouton "Réessayer" |
| `ServerException` | "Le serveur est temporairement indisponible. Réessaie dans quelques minutes." | Bouton "Réessayer" |
| `DataPackNotFoundException` | "Les données de ce boîtier ne sont pas encore disponibles." | Bouton "Signaler" |
| `DataPackCorruptedException` | "Le téléchargement a été corrompu. On va réessayer." | Retry automatique |

---

## 11. Distribution des data packs (serveur)

### 11.1. Architecture serveur MVP

Le serveur est un **CDN statique**. Pas de backend applicatif, pas d'API, pas de base de données côté serveur. Juste des fichiers JSON statiques servis par un CDN.

```
OPTIONS (par budget croissant) :

1. GitHub Pages (gratuit)
   URL : https://shoothelper.github.io/data-packs/sony_a6700/body.json
   Avantage : gratuit, versionné avec git, CI/CD intégré
   Limite : 1 GB de stockage, pas de custom domain facile

2. Cloudflare R2 (quasi gratuit)
   URL : https://data.shoothelper.app/v1/sony_a6700/body.json
   Avantage : CDN global, pas de frais d'egress, custom domain
   Limite : Setup un peu plus technique

3. Firebase Hosting (gratuit tier)
   URL : https://shoothelper.web.app/data/sony_a6700/body.json
   Avantage : intégré Firebase, CLI simple, CDN global
   Limite : 10 GB/mois de transfert gratuit
```

**Recommandation MVP : GitHub Pages** pour commencer (zéro coût, zéro config). Migrer vers Cloudflare R2 quand le trafic augmente.

### 11.2. Structure des URLs

```
GET /{body_id}/manifest.json
GET /{body_id}/body.json
GET /{body_id}/menu_tree.json
GET /{body_id}/nav_paths.json
GET /{body_id}/lenses/{lens_id}.json
GET /shared/setting_defs.json
GET /shared/brands.json
GET /shared/mounts.json
GET /catalog.json                      ← Liste de tous les boîtiers supportés
```

### 11.3. catalog.json — Le catalogue des boîtiers

Ce fichier est téléchargé pendant l'onboarding pour afficher la liste des boîtiers disponibles.

```json
{
  "version": "2026-03-15",
  "bodies": [
    {
      "id": "sony_a6700",
      "brand_id": "sony",
      "display_name": "A6700",
      "sensor_size": "aps-c",
      "pack_version": "1.1.0",
      "pack_size_bytes": 245000,
      "lens_count": 12,
      "supported_languages": ["en", "fr", "de", "ja"]
    },
    {
      "id": "canon_r50",
      "brand_id": "canon",
      "display_name": "R50",
      "sensor_size": "aps-c",
      "pack_version": "1.0.0",
      "pack_size_bytes": 230000,
      "lens_count": 10,
      "supported_languages": ["en", "fr", "de", "es"]
    }
  ]
}
```

Ce catalogue est léger (~5 KB pour 14 boîtiers) et permet d'afficher l'écran de sélection de boîtier sans télécharger aucun data pack. Le data pack complet n'est téléchargé qu'après la sélection.

### 11.4. Versioning des URLs

```
MVP : pas de version dans l'URL
  https://data.shoothelper.app/sony_a6700/body.json
  Le pack_version est dans le manifest.json

V2 (si besoin de breaking changes) :
  https://data.shoothelper.app/v2/sony_a6700/body.json
  L'app v2.0 pointe vers /v2/, l'app v1.x continue de pointer vers /v1/
```

---

## 12. Séquence complète — Du premier lancement au shoot offline

```
JOUR 1 — À LA MAISON (Wi-Fi)
──────────────────────────────
  1. L'utilisateur installe ShootHelper
  2. Premier lancement → [Welcome Screen]
  3. Sélection Sony A6700
  4. Sélection Sigma 18-50mm f/2.8 + Sony 16-50mm kit
  5. Langue firmware : Français
  6. Téléchargement : catalog.json → body.json → menu_tree.json
     → nav_paths.json → 2× lens.json
     Total : ~230 KB en ~2 secondes
  7. Chargement en RAM (CameraDataCache) : ~100ms
  8. [Home Screen] — prêt

JOUR 2 — EN RANDONNÉE (PAS DE RÉSEAU)
──────────────────────────────────────
  9. L'utilisateur ouvre l'app
  10. Démarrage : lecture SharedPrefs → lecture JSON → RAM
      Temps : ~300ms total
  11. [Home Screen] — tout est disponible
  12. Tap "Nouveau shoot"
  13. Sélection : Photo · Ext Jour · Paysage · Netteté max
  14. Tap "Calculer" → Settings Engine (local, <1ms)
  15. [Résultats] — f/8, 1/250s, ISO 200, etc.
  16. Tap sur "Ouverture f/8"
  17. [Détail] — explication pourquoi f/8 (sweet spot)
  18. Tap "Où régler sur mon A6700"
  19. [Menu Navigation] — chemin en français
      ❶ Menu > Exposition/Couleur
      ❷ → Ouverture > f/8
  20. L'utilisateur règle son appareil et shoote

  TOUT ÇA SANS UNE SEULE REQUÊTE RÉSEAU.

JOUR 15 — RETOUR À LA MAISON (Wi-Fi)
─────────────────────────────────────
  21. L'utilisateur ouvre l'app
  22. Check silencieux en arrière-plan : manifest distant vs local
  23. Pas de MAJ → rien ne se passe
  24. L'utilisateur va dans Settings > "Ajouter un objectif"
  25. Sélection Sony FE 50mm f/1.8
  26. Téléchargement : 1× lens.json (~5 KB, <1 seconde)
  27. Le nouvel objectif est disponible immédiatement
```

---

*Ce document est la référence pour l'implémentation du download, de la gestion réseau, et du fonctionnement offline. Combiné avec le skill 12 (Local Database), il couvre tout le cycle de vie des données depuis le serveur jusqu'au cache mémoire.*
