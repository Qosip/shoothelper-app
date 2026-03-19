# Local Database Design — ShootHelper

> **Skill 12/22** · Schéma de stockage local, migrations, versioning
> Version 1.0 · Mars 2026
> Réf : 04_CAMERA_DATA_ARCHITECTURE.md, 08_TECH_STACK_DECISION.md, 11_STATE_MANAGEMENT.md

---

## 1. Stratégie de stockage dual

ShootHelper a deux types de données fondamentalement différents qui appellent deux stratégies de stockage différentes.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  TYPE A : Données caméra (data packs)                       │
│  ─────────────────────────────────────                      │
│  • Statiques (ne changent qu'avec un firmware update)       │
│  • Produites par le pipeline de scraping (skill 05)         │
│  • Téléchargées depuis le serveur                           │
│  • Identiques pour tous les utilisateurs d'un même boîtier  │
│  • ~250 KB par boîtier, ~15 fichiers JSON                   │
│  • Lues fréquemment, jamais écrites par l'app               │
│                                                             │
│  → STOCKAGE : Fichiers JSON sur le filesystem local         │
│                                                             │
│  TYPE B : Données utilisateur                               │
│  ────────────────────────────                               │
│  • Dynamiques (créées et modifiées par l'utilisateur)       │
│  • Propres à chaque utilisateur                             │
│  • MVP : uniquement le profil gear (clé-valeur simple)      │
│  • V2 : historique, favoris, presets (relationnelles)       │
│  • Écrites fréquemment, requêtes de lecture variées         │
│                                                             │
│  → STOCKAGE MVP : SharedPreferences (clé-valeur)            │
│  → STOCKAGE V2 : Drift / SQLite (relationnel)              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Pourquoi ne pas tout mettre en SQLite dès le MVP ?** Les données caméra sont des arbres JSON imbriqués (MenuTree = récursif, BodySpec = nested 5 niveaux). Les aplatir en tables relationnelles serait douloureux et sans bénéfice — on ne fait jamais de requête SQL dessus. On les charge en mémoire au démarrage et on navigue dans les objets Dart. SQLite n'apporterait que de la complexité.

---

## 2. Type A — Données caméra (filesystem JSON)

### 2.1. Structure sur le filesystem

```
{app_documents_directory}/
└── shoothelper/
    ├── shared/
    │   ├── setting_defs.json
    │   ├── brands.json
    │   └── mounts.json
    │
    ├── packs/
    │   ├── sony_a6700/
    │   │   ├── manifest.json
    │   │   ├── body.json
    │   │   ├── menu_tree.json
    │   │   ├── nav_paths.json
    │   │   └── lenses/
    │   │       ├── sigma_18-50_f2.8.json
    │   │       ├── sony_e_16-50_f3.5-5.6.json
    │   │       └── sony_fe_50_f1.8.json
    │   │
    │   ├── canon_r50/
    │   │   ├── manifest.json
    │   │   ├── body.json
    │   │   ├── menu_tree.json
    │   │   ├── nav_paths.json
    │   │   └── lenses/
    │   │       └── ...
    │   └── ...
    │
    └── meta/
        └── download_state.json         # État du téléchargement (quels packs sont complets)
```

### 2.2. Cycle de vie des fichiers

```
TÉLÉCHARGEMENT (onboarding / ajout gear)
  1. App crée le dossier packs/{body_id}/
  2. Télécharge chaque fichier séquentiellement
  3. Valide le checksum SHA-256 contre le manifest
  4. Écrit download_state.json avec le statut "complete"
  5. Si échec partiel → marque "incomplete" dans download_state

LECTURE (flow principal)
  1. Au démarrage, charger le profil gear (SharedPreferences)
  2. Lire packs/{body_id}/body.json → parser → Body entity en mémoire
  3. Lire packs/{body_id}/lenses/{lens_id}.json → parser → Lens entity
  4. Lire packs/{body_id}/menu_tree.json → parser → MenuTree en mémoire
  5. Lire packs/{body_id}/nav_paths.json → parser → List<SettingNavPath>
  6. Tout est en RAM — aucune lecture filesystem pendant le flow principal

MISE À JOUR (data pack update)
  1. Télécharger le nouveau manifest
  2. Comparer pack_version
  3. Télécharger les fichiers modifiés dans un dossier temporaire
  4. Valider les checksums
  5. Remplacer atomiquement (rename) les anciens fichiers
  6. Si échec → les anciens fichiers sont intacts (atomic swap)

SUPPRESSION (changement de boîtier)
  1. Supprimer le dossier packs/{old_body_id}/
  2. Télécharger le nouveau data pack
```

### 2.3. FileManager — L'abstraction filesystem

```dart
// shared/data/data_sources/local/file_manager.dart
abstract class FileManager {
  /// Chemin racine de l'app
  Future<String> get rootPath;

  /// Vérifie si un data pack existe et est complet
  Future<bool> isDataPackComplete(String bodyId);

  /// Lit un fichier JSON et retourne la Map parsée
  Future<Map<String, dynamic>> readJson(String relativePath);

  /// Écrit un fichier JSON
  Future<void> writeJson(String relativePath, Map<String, dynamic> data);

  /// Supprime un dossier récursivement
  Future<void> deleteDirectory(String relativePath);

  /// Renomme un dossier (atomic swap)
  Future<void> renameDirectory(String from, String to);

  /// Taille totale d'un data pack
  Future<int> dataPackSizeBytes(String bodyId);

  /// Liste les data packs téléchargés
  Future<List<String>> listDownloadedPacks();
}
```

### 2.4. Chargement en mémoire (CameraDataCache)

Les données caméra sont chargées une fois au démarrage et gardées en RAM. Pas de re-lecture filesystem à chaque calcul.

```dart
// shared/data/data_sources/local/camera_data_cache.dart

/// Cache en mémoire des données du boîtier actif
/// Invalidé et rechargé quand le gear profile change
class CameraDataCache {
  Body? _body;
  Map<String, Lens> _lenses = {};
  MenuTree? _menuTree;
  List<SettingNavPath> _navPaths = [];
  List<SettingDef> _settingDefs = [];

  bool get isLoaded => _body != null;

  Body get body => _body!;
  Lens getLens(String lensId) => _lenses[lensId]!;
  MenuTree get menuTree => _menuTree!;
  List<SettingNavPath> get navPaths => _navPaths;
  List<SettingDef> get settingDefs => _settingDefs;

  /// Charge toutes les données d'un boîtier depuis le filesystem
  Future<void> load(String bodyId, List<String> lensIds, FileManager fm) async {
    // Lecture parallèle des fichiers
    final results = await Future.wait([
      fm.readJson('packs/$bodyId/body.json'),
      fm.readJson('packs/$bodyId/menu_tree.json'),
      fm.readJson('packs/$bodyId/nav_paths.json'),
      fm.readJson('shared/setting_defs.json'),
      ...lensIds.map((id) => fm.readJson('packs/$bodyId/lenses/$id.json')),
    ]);

    _body = BodyMapper.toEntity(BodyModel.fromJson(results[0]));
    _menuTree = MenuTreeMapper.toEntity(MenuTreeModel.fromJson(results[1]));
    _navPaths = (results[2] as List).map((j) =>
        NavPathMapper.toEntity(NavPathModel.fromJson(j))).toList();
    _settingDefs = (results[3] as List).map((j) =>
        SettingDefMapper.toEntity(SettingDefModel.fromJson(j))).toList();

    _lenses = {};
    for (var i = 0; i < lensIds.length; i++) {
      final lensJson = results[4 + i];
      final lens = LensMapper.toEntity(LensModel.fromJson(lensJson));
      _lenses[lens.id] = lens;
    }
  }

  /// Libère la mémoire
  void clear() {
    _body = null;
    _lenses = {};
    _menuTree = null;
    _navPaths = [];
    _settingDefs = [];
  }
}
```

**Estimation mémoire :**

| Donnée | Taille JSON | Taille en RAM (Dart objects) | Note |
|--------|------------|----------------------------|------|
| body.json | ~15 KB | ~50 KB | Objets Dart + overhead |
| menu_tree.json | ~150 KB | ~500 KB | Arbre récursif, beaucoup de strings |
| nav_paths.json | ~30 KB | ~100 KB | |
| 5 lenses | ~25 KB | ~80 KB | |
| setting_defs.json | ~5 KB | ~20 KB | |
| **Total** | **~225 KB** | **~750 KB** | |

750 KB en RAM. Négligeable même sur un téléphone bas de gamme (2 GB de RAM).

### 2.5. Riverpod integration

```dart
// shared/presentation/providers/camera_data_providers.dart

@Riverpod(keepAlive: true)
CameraDataCache cameraDataCache(Ref ref) {
  return CameraDataCache();
}

/// Charge les données quand le gear change
/// Auto-invalidé quand currentGear change
@riverpod
Future<void> loadCameraData(Ref ref) async {
  final gear = await ref.watch(currentGearProvider.future);
  if (gear == null) return;

  final cache = ref.read(cameraDataCacheProvider);
  final fm = ref.read(fileManagerProvider);

  if (cache.isLoaded && cache.body.id == gear.bodyId) return; // Déjà chargé

  cache.clear();
  await cache.load(gear.bodyId, gear.lensIds, fm);
}

/// Accès typé au Body chargé
@riverpod
Body? currentBody(Ref ref) {
  ref.watch(loadCameraDataProvider); // Trigger le chargement
  final cache = ref.read(cameraDataCacheProvider);
  return cache.isLoaded ? cache.body : null;
}

/// Accès typé au Lens actif
@riverpod
Lens? currentLens(Ref ref) {
  ref.watch(loadCameraDataProvider);
  final gear = ref.watch(currentGearProvider).valueOrNull;
  if (gear == null) return null;
  final cache = ref.read(cameraDataCacheProvider);
  return cache.isLoaded ? cache.getLens(gear.activeLensId) : null;
}
```

---

## 3. Type B (MVP) — Données utilisateur (SharedPreferences)

### 3.1. Ce qui est stocké

Au MVP, les données utilisateur sont minimales :

| Clé | Type | Contenu | Exemple |
|-----|------|---------|---------|
| `gear_profile` | String (JSON) | Profil gear sérialisé | `{"bodyId":"sony_a6700","lensIds":["sigma_18-50"],"activeLensId":"sigma_18-50","firmwareLanguage":"fr"}` |
| `onboarding_complete` | bool | Onboarding terminé | `true` |
| `app_language_override` | String? | Langue forcée (null = auto) | `null` |

C'est volontairement minimal. SharedPreferences est adapté pour 3-5 clé-valeurs simples. Pas plus.

### 3.2. Implémentation

```dart
// shared/data/data_sources/local/preferences_source.dart
class PreferencesSource {
  static const _keyGearProfile = 'gear_profile';
  static const _keyOnboardingComplete = 'onboarding_complete';

  Future<GearProfile?> loadGearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyGearProfile);
    if (json == null) return null;
    return GearProfile.fromJson(jsonDecode(json));
  }

  Future<void> saveGearProfile(GearProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGearProfile, jsonEncode(profile.toJson()));
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, value);
  }
}
```

---

## 4. Type B (V2) — Données utilisateur (Drift / SQLite)

Quand l'app évolue vers l'historique, les favoris, et les presets, SharedPreferences ne suffit plus. On migre les données dynamiques vers Drift (SQLite).

### 4.1. Quand déclencher la migration

```
MVP (v1.x) :
  SharedPreferences  →  gear_profile, onboarding_complete
  Filesystem JSON    →  data packs caméra

V2 (v2.0) :
  Drift SQLite       →  gear_profile + historique + favoris + presets
  Filesystem JSON    →  data packs caméra (inchangé)
  SharedPreferences  →  flags simples uniquement (onboarding_complete)
```

La migration se déclenche au premier lancement de la v2 : l'app détecte que la base SQLite n'existe pas, lit le `gear_profile` depuis SharedPreferences, le migre vers SQLite, et supprime la clé SharedPreferences.

### 4.2. Schéma SQLite (Drift)

```
┌──────────────────────────────────────────────────────────────┐
│                   SCHÉMA DRIFT V2                            │
│                                                              │
│  ┌────────────────┐                                          │
│  │  gear_profiles  │                                         │
│  │────────────────│          ┌───────────────────┐           │
│  │ id (PK)        │──────1:N──│  gear_lenses     │           │
│  │ body_id        │          │─────────────────│           │
│  │ active_lens_id │          │ profile_id (FK) │           │
│  │ firmware_lang   │          │ lens_id         │           │
│  │ created_at     │          │ sort_order      │           │
│  │ updated_at     │          └───────────────────┘           │
│  └────────────────┘                                          │
│                                                              │
│  ┌─────────────────┐         ┌───────────────────┐          │
│  │ history_entries  │──────1:N──│ history_settings │          │
│  │─────────────────│         │─────────────────│          │
│  │ id (PK)         │         │ entry_id (FK)   │          │
│  │ profile_id (FK) │         │ setting_id      │          │
│  │ scene_json      │         │ value           │          │
│  │ summary         │         │ value_display   │          │
│  │ confidence      │         │ explanation     │          │
│  │ is_favorite     │         └───────────────────┘          │
│  │ created_at      │                                         │
│  │ note            │                                         │
│  └─────────────────┘                                         │
│                                                              │
│  ┌─────────────────┐                                         │
│  │  presets         │                                         │
│  │─────────────────│                                         │
│  │ id (PK)         │                                         │
│  │ name            │                                         │
│  │ profile_id (FK) │                                         │
│  │ scene_json      │                                         │
│  │ created_at      │                                         │
│  │ updated_at      │                                         │
│  └─────────────────┘                                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 4.3. Tables Drift (Dart)

```dart
// shared/data/database/tables.dart

/// Profil gear de l'utilisateur
class GearProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bodyId => text()();
  TextColumn get activeLensId => text()();
  TextColumn get firmwareLanguage => text().withDefault(const Constant('en'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Objectifs associés à un profil (relation N:M simplifiée en 1:N)
class GearLenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(GearProfiles, #id)();
  TextColumn get lensId => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Historique des calculs de réglages
class HistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(GearProfiles, #id)();
  TextColumn get sceneJson => text()();         // SceneInput sérialisé en JSON
  TextColumn get summary => text()();            // "Portrait · Ext Jour · Bokeh"
  TextColumn get confidence => text()();         // "high", "medium", "low"
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();    // Note libre de l'utilisateur
}

/// Réglages associés à une entrée d'historique
class HistorySettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer().references(HistoryEntries, #id)();
  TextColumn get settingId => text()();          // "aperture", "shutter_speed"...
  TextColumn get value => text()();              // "2.8", "1/250"
  TextColumn get valueDisplay => text()();       // "f/2.8", "1/250s"
  TextColumn get explanation => text()();        // Explication courte
}

/// Presets de scène sauvegardés
class Presets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get profileId => integer().references(GearProfiles, #id)();
  TextColumn get sceneJson => text()();          // SceneInput sérialisé
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

### 4.4. Base de données Drift

```dart
// shared/data/database/app_database.dart

@DriftDatabase(tables: [
  GearProfiles,
  GearLenses,
  HistoryEntries,
  HistorySettings,
  Presets,
], daos: [
  GearProfileDao,
  HistoryDao,
  PresetDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Migrations futures ici (voir §5)
    },
    beforeOpen: (details) async {
      // Activer les foreign keys (désactivées par défaut en SQLite)
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

// Factory
AppDatabase createDatabase() {
  return AppDatabase(
    NativeDatabase.createInBackground(
      File(join(appDocumentsPath, 'shoothelper', 'app.db')),
    ),
  );
}
```

### 4.5. DAOs

```dart
// shared/data/database/daos/gear_profile_dao.dart

@DriftAccessor(tables: [GearProfiles, GearLenses])
class GearProfileDao extends DatabaseAccessor<AppDatabase>
    with _$GearProfileDaoMixin {
  GearProfileDao(super.db);

  /// Charge le profil actif (le plus récent)
  Future<GearProfile?> loadActiveProfile() async {
    final profileRow = await (select(gearProfiles)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();

    if (profileRow == null) return null;

    final lensRows = await (select(gearLenses)
          ..where((t) => t.profileId.equals(profileRow.id))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    return GearProfile(
      bodyId: profileRow.bodyId,
      lensIds: lensRows.map((r) => r.lensId).toList(),
      activeLensId: profileRow.activeLensId,
      firmwareLanguage: profileRow.firmwareLanguage,
    );
  }

  /// Sauvegarde ou met à jour le profil
  Future<void> saveProfile(GearProfile profile) async {
    await transaction(() async {
      // Upsert le profil
      final id = await into(gearProfiles).insertOnConflictUpdate(
        GearProfilesCompanion.insert(
          bodyId: profile.bodyId,
          activeLensId: profile.activeLensId,
          firmwareLanguage: profile.firmwareLanguage,
        ),
      );

      // Remplacer les lenses
      await (delete(gearLenses)..where((t) => t.profileId.equals(id))).go();
      for (var i = 0; i < profile.lensIds.length; i++) {
        await into(gearLenses).insert(GearLensesCompanion.insert(
          profileId: id,
          lensId: profile.lensIds[i],
          sortOrder: Value(i),
        ));
      }
    });
  }
}
```

```dart
// shared/data/database/daos/history_dao.dart

@DriftAccessor(tables: [HistoryEntries, HistorySettings])
class HistoryDao extends DatabaseAccessor<AppDatabase>
    with _$HistoryDaoMixin {
  HistoryDao(super.db);

  /// Historique récent, paginé
  Future<List<HistoryEntry>> getRecent({int limit = 20, int offset = 0}) async {
    final entries = await (select(historyEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit, offset: offset))
        .get();

    return Future.wait(entries.map(_hydrateEntry));
  }

  /// Favoris uniquement
  Future<List<HistoryEntry>> getFavorites() async {
    final entries = await (select(historyEntries)
          ..where((t) => t.isFavorite.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    return Future.wait(entries.map(_hydrateEntry));
  }

  /// Sauvegarder un calcul dans l'historique
  Future<void> saveEntry({
    required int profileId,
    required SceneInput scene,
    required SettingsResult result,
  }) async {
    await transaction(() async {
      final entryId = await into(historyEntries).insert(
        HistoryEntriesCompanion.insert(
          profileId: profileId,
          sceneJson: jsonEncode(scene.toJson()),
          summary: _buildSummary(scene),
          confidence: result.confidence.name,
        ),
      );

      for (final setting in result.settings) {
        await into(historySettings).insert(
          HistorySettingsCompanion.insert(
            entryId: entryId,
            settingId: setting.settingId,
            value: setting.value.toString(),
            valueDisplay: setting.valueDisplay,
            explanation: setting.explanationShort,
          ),
        );
      }
    });
  }

  /// Toggle favori
  Future<void> toggleFavorite(int entryId) async {
    final entry = await (select(historyEntries)
          ..where((t) => t.id.equals(entryId)))
        .getSingle();

    await (update(historyEntries)..where((t) => t.id.equals(entryId)))
        .write(HistoryEntriesCompanion(isFavorite: Value(!entry.isFavorite)));
  }

  /// Supprimer une entrée et ses réglages (cascade)
  Future<void> deleteEntry(int entryId) async {
    await transaction(() async {
      await (delete(historySettings)..where((t) => t.entryId.equals(entryId))).go();
      await (delete(historyEntries)..where((t) => t.id.equals(entryId))).go();
    });
  }

  /// Stream réactif pour l'UI
  Stream<List<HistoryEntryRow>> watchRecent({int limit = 20}) {
    return (select(historyEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<HistoryEntry> _hydrateEntry(HistoryEntryData row) async {
    final settings = await (select(historySettings)
          ..where((t) => t.entryId.equals(row.id)))
        .get();

    return HistoryEntry(
      id: row.id,
      scene: SceneInput.fromJson(jsonDecode(row.sceneJson)),
      summary: row.summary,
      confidence: Confidence.values.byName(row.confidence),
      isFavorite: row.isFavorite,
      createdAt: row.createdAt,
      note: row.note,
      settings: settings.map((s) => HistorySettingEntry(
        settingId: s.settingId,
        value: s.value,
        valueDisplay: s.valueDisplay,
        explanation: s.explanation,
      )).toList(),
    );
  }
}
```

### 4.6. Pourquoi `sceneJson` est un blob JSON et pas des colonnes séparées

Le `SceneInput` a ~15 champs dont la plupart sont nullable. Les aplatir en colonnes SQLite créerait une table large, difficile à maintenir, et qui change à chaque fois qu'on ajoute un paramètre de scène.

En stockant le SceneInput comme JSON blob :
- Ajouter un champ au SceneInput = zéro migration de schéma
- La lecture est un simple `jsonDecode` + `fromJson`
- On ne fait jamais de `WHERE` sur les champs individuels de la scène (on cherche par date, favori, ou profil — pas par "tous les portraits en extérieur")

Si on a besoin de filtrer par champ de scène en V3, on ajoutera des colonnes d'index dénormalisées (ex: `subject TEXT`, `environment TEXT`) en plus du JSON blob. Pas à la place.

---

## 5. Migrations

### 5.1. Stratégie de migration

```
RÈGLE : Chaque schéma a un numéro de version (schemaVersion).
        Chaque migration est un bloc de code nommé "from_X_to_Y".
        Les migrations sont SÉQUENTIELLES — v1→v2→v3, jamais v1→v3 directement.
        Drift gère l'exécution séquentielle automatiquement.
```

### 5.2. Migration v0 → v1 : SharedPreferences vers SQLite

C'est la migration qui se produit quand l'utilisateur met à jour de la v1.x (MVP) vers la v2.0.

```dart
// shared/data/database/migrations/migration_v0_to_v1.dart

/// Migre le gear profile de SharedPreferences vers SQLite
/// Appelé une fois au premier lancement de la v2
class MigrationV0ToV1 {
  final PreferencesSource _prefs;
  final GearProfileDao _dao;

  MigrationV0ToV1(this._prefs, this._dao);

  Future<void> execute() async {
    // 1. Lire l'ancien profil
    final oldProfile = await _prefs.loadGearProfile();
    if (oldProfile == null) return; // Pas de profil = rien à migrer

    // 2. Écrire dans SQLite
    await _dao.saveProfile(oldProfile);

    // 3. Supprimer l'ancienne clé SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gear_profile');

    // 4. Marquer la migration comme faite
    await prefs.setBool('migration_v0_v1_done', true);
  }

  Future<bool> isNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('migration_v0_v1_done') == true) return false;
    return prefs.containsKey('gear_profile');
  }
}
```

### 5.3. Migrations futures de schéma SQLite

```dart
// shared/data/database/app_database.dart

@override
int get schemaVersion => 2; // Incrémenter à chaque changement de schéma

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    for (var target = from + 1; target <= to; target++) {
      switch (target) {
        case 2:
          // v1 → v2 : Ajouter la table presets
          await m.createTable(presets);
          break;
        case 3:
          // v2 → v3 : Ajouter colonnes d'index dénormalisées à history
          await m.addColumn(historyEntries, historyEntries.subject);
          await m.addColumn(historyEntries, historyEntries.environment);
          break;
      }
    }
  },
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');

    // Migration SharedPreferences → SQLite (one-time, v1.x → v2.0)
    if (details.wasCreated) {
      final migrationV0 = MigrationV0ToV1(PreferencesSource(), GearProfileDao(this));
      if (await migrationV0.isNeeded()) {
        await migrationV0.execute();
      }
    }
  },
);
```

### 5.4. Règles de migration

| Règle | Détail |
|-------|--------|
| **Jamais de DROP TABLE** | Même si une table est "obsolète", on la garde. Supprimer = perte de données. |
| **Toujours additive** | Ajouter des colonnes (nullable ou avec default), ajouter des tables. Jamais supprimer/renommer. |
| **Tester chaque migration** | Un test unitaire par migration : créer la BDD en version N, exécuter la migration vers N+1, vérifier l'intégrité. |
| **Backup avant migration** | Copier le fichier `.db` avant d'appliquer une migration. Si la migration plante, on peut rollback. |
| **Garder un historique** | Chaque migration est dans un fichier séparé avec un commentaire expliquant le changement. |

---

## 6. Versioning des data packs vs schéma SQLite

Il y a deux systèmes de version indépendants qui coexistent :

```
DATA PACK VERSION (skill 04)
  Quoi : version du contenu caméra (menus, specs, nav_paths)
  Où :   manifest.json dans chaque data pack
  Quand : mise à jour firmware, correction d'erreur dans les données
  Impact : re-téléchargement du data pack, pas de migration code
  Exemple : sony_a6700 pack v1.0 → v1.1

SQLITE SCHEMA VERSION
  Quoi : version de la structure des tables utilisateur
  Où :   schemaVersion dans app_database.dart
  Quand : ajout de feature (historique, presets, nouvelles colonnes)
  Impact : migration de schéma à l'ouverture de la BDD
  Exemple : schemaVersion 1 → 2

APP VERSION
  Quoi : version de l'application publiée
  Où :   pubspec.yaml
  Quand : nouvelle release
  Impact : peut déclencher des migrations de schéma et/ou data pack
  Exemple : 1.0.0 → 2.0.0
```

**Il n'y a pas de couplage** entre ces versions. Le data pack v1.1 fonctionne avec le schéma SQLite v1 ou v2. Le schéma SQLite v2 fonctionne avec n'importe quel data pack. L'app v2.0 peut fonctionner avec des data packs téléchargés par l'app v1.0 (pas de re-download obligatoire).

---

## 7. Limites de stockage et nettoyage

### 7.1. Budget d'espace

| Composant | Budget max | Note |
|-----------|-----------|------|
| Data packs (tous boîtiers) | ~5 MB | 14 boîtiers × ~250 KB + overhead |
| SQLite database | ~10 MB | Surtout l'historique — 1000 entrées ≈ 2 MB |
| SharedPreferences | < 10 KB | Juste des flags |
| **Total** | **< 20 MB** | Négligeable |

### 7.2. Nettoyage automatique (V2)

```dart
/// Nettoie les entrées d'historique au-delà de la limite
/// Garde les favoris, supprime les plus anciens
Future<void> pruneHistory({int maxEntries = 500}) async {
  final count = await historyEntries.count().getSingle();
  if (count <= maxEntries) return;

  // Garder les favoris + les N plus récents
  await customStatement('''
    DELETE FROM history_entries
    WHERE id NOT IN (
      SELECT id FROM history_entries
      WHERE is_favorite = 1
      UNION ALL
      SELECT id FROM history_entries
      WHERE is_favorite = 0
      ORDER BY created_at DESC
      LIMIT ?
    )
  ''', [maxEntries]);

  // Cascade : les history_settings orphelins sont supprimés par FK
}
```

---

## 8. Diagramme complet du stockage

```
┌─────────────────────────────────────────────────────────────────┐
│                     STOCKAGE LOCAL COMPLET                       │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  FILESYSTEM (path_provider → app documents)               │  │
│  │                                                           │  │
│  │  shoothelper/                                             │  │
│  │  ├── packs/           ← Data packs caméra (JSON)         │  │
│  │  │   ├── sony_a6700/  ← Statique, read-only              │  │
│  │  │   └── canon_r50/   ← Téléchargé depuis le serveur     │  │
│  │  ├── shared/          ← Données partagées (JSON)         │  │
│  │  ├── meta/            ← État des téléchargements         │  │
│  │  └── app.db           ← Base SQLite Drift (V2)           │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  RAM (Riverpod providers)                                 │  │
│  │                                                           │  │
│  │  CameraDataCache                                          │  │
│  │  ├── Body (parsé depuis body.json)                        │  │
│  │  ├── Map<String, Lens> (parsé depuis lenses/*.json)       │  │
│  │  ├── MenuTree (parsé depuis menu_tree.json)               │  │
│  │  ├── List<SettingNavPath> (parsé depuis nav_paths.json)   │  │
│  │  └── List<SettingDef> (parsé depuis setting_defs.json)    │  │
│  │                                                           │  │
│  │  State Riverpod                                           │  │
│  │  ├── GearProfile (persisté ↔ SharedPrefs/SQLite)         │  │
│  │  ├── SceneInput (session, non persisté)                   │  │
│  │  └── SettingsResult (session, non persisté)               │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  SHARED PREFERENCES                                       │  │
│  │                                                           │  │
│  │  MVP : gear_profile (JSON string)                         │  │
│  │  MVP : onboarding_complete (bool)                         │  │
│  │  V2  : migration_v0_v1_done (bool)                        │  │
│  │  V2  : onboarding_complete (bool) ← seul survivant        │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Résumé des décisions

| Question | MVP | V2 | Justification |
|----------|-----|-----|---------------|
| Où stocker les données caméra ? | Filesystem JSON | Filesystem JSON | Données arborescentes, read-only, pas de requêtes SQL |
| Où stocker le profil gear ? | SharedPreferences | SQLite (Drift) | Migration quand le schéma devient relationnel |
| Où stocker l'historique ? | N/A | SQLite (Drift) | Requêtes (tri date, filtre favori), pagination |
| Où stocker les presets ? | N/A | SQLite (Drift) | CRUD classique, relations avec le profil |
| Comment accéder aux données caméra au runtime ? | RAM (CameraDataCache) | RAM (CameraDataCache) | Lecture unique au démarrage, ~750 KB |
| Comment migrer de MVP à V2 ? | — | Script one-time dans `beforeOpen` | Lit SharedPrefs → écrit SQLite → supprime SharedPrefs |
| SceneInput en base : colonnes ou JSON blob ? | — | JSON blob | Schéma flexible, pas de filtrage par champ au MVP/V2 |

---

*Ce document est la référence pour le skill 13 (Offline-First Architecture) et l'implémentation du stockage. Le CameraDataCache et le FileManager sont les deux classes les plus critiques à implémenter en premier.*
