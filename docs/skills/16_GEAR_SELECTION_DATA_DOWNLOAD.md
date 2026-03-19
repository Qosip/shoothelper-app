# Gear Selection & Data Download — ShootHelper

> **Skill 16/22** · Flow sélection appareil + objectif, téléchargement, stockage local
> Version 1.0 · Mars 2026
> Réf : 02_USER_FLOWS.md, 10_MODULE_FEATURE_ARCHITECTURE.md, 13_OFFLINE_FIRST_ARCHITECTURE.md, 14_API_BACKEND_DESIGN.md

---

## 1. Vue d'ensemble

Ce skill détaille l'implémentation concrète de deux features du skill 10 : **onboarding** (premier setup) et **gear** (gestion ultérieure du matériel). C'est la porte d'entrée de l'app — si cette feature est bancale, l'utilisateur ne verra jamais le Settings Engine.

**Le flow complet :**

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Catalogue│───→│ Sélection│───→│ Sélection│───→│  Langue  │───→│  Récap & │
│ (remote) │    │  Boîtier │    │ Objectifs│    │ Firmware │    │ Download │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     🌐               📱              📱             📱             🌐
  ~5 KB            local           local          local         ~250 KB
```

Les étapes de sélection (boîtier, objectifs, langue) sont des choix locaux dans l'UI — pas de téléchargement entre les étapes. Le download ne se fait qu'une seule fois à la fin, quand tout est confirmé.

---

## 2. Données de sélection : le Catalogue

### 2.1. Problème : comment afficher la liste des boîtiers sans télécharger 14 data packs ?

Le `catalog.json` (skill 14) est un fichier léger (~5 KB) qui contient juste assez d'information pour afficher l'écran de sélection : nom, marque, capteur, langues supportées, et la liste des objectifs disponibles.

### 2.2. Schéma du catalog.json étendu

```json
{
  "version": "2026-03-15",
  "bodies": [
    {
      "id": "sony_a6700",
      "brand_id": "sony",
      "display_name": "A6700",
      "name": "Sony A6700",
      "sensor_size": "aps-c",
      "mount_id": "sony_e",
      "pack_version": "1.1.0",
      "pack_size_bytes": 245000,
      "supported_languages": ["en", "fr", "de", "es", "it", "ja", "ko", "zh-cn"],
      "lenses": [
        {
          "id": "sigma_18-50_f2.8_dc_dn_c",
          "display_name": "Sigma 18-50mm f/2.8 DC DN",
          "type": "zoom",
          "designed_for": "aps-c",
          "is_kit_lens": false,
          "popularity_rank": 1
        },
        {
          "id": "sony_e_16-50_f3.5-5.6_oss",
          "display_name": "Sony E 16-50mm f/3.5-5.6 OSS",
          "type": "zoom",
          "designed_for": "aps-c",
          "is_kit_lens": true,
          "popularity_rank": 2
        },
        {
          "id": "sony_e_55-210_f4.5-6.3_oss",
          "display_name": "Sony E 55-210mm f/4.5-6.3 OSS",
          "type": "zoom",
          "designed_for": "aps-c",
          "is_kit_lens": true,
          "popularity_rank": 3
        }
      ]
    }
  ],
  "brands": [
    { "id": "sony", "name": "Sony", "display_order": 0 },
    { "id": "canon", "name": "Canon", "display_order": 1 },
    { "id": "nikon", "name": "Nikon", "display_order": 2 },
    { "id": "fujifilm", "name": "Fujifilm", "display_order": 3 }
  ]
}
```

**Pourquoi les objectifs sont dans le catalogue ?** Pour que l'écran de sélection d'objectifs fonctionne sans téléchargement supplémentaire. L'utilisateur choisit ses objectifs dans cette liste. Le data pack complet (avec les specs détaillées de chaque objectif) n'est téléchargé qu'à la fin.

**`popularity_rank`** détermine l'ordre d'affichage. Les objectifs kit et les best-sellers sont en haut. Ça aide le débutant qui ne connaît pas forcément le nom exact de son objectif.

**`is_kit_lens`** permet d'afficher un badge "Kit" à côté de l'objectif. Le débutant reconnaît plus facilement "c'est celui qui était dans la boîte".

### 2.3. Cache local du catalogue

Le catalogue est caché localement après le premier téléchargement. Ça permet de revenir sur l'écran de sélection sans re-télécharger.

```dart
// features/onboarding/data/catalog_cache.dart

class CatalogCache {
  final FileManager _fm;
  static const _path = 'meta/catalog.json';
  static const _maxAge = Duration(hours: 24);

  CatalogCache(this._fm);

  Future<CatalogModel?> loadCached() async {
    try {
      final json = await _fm.readJson(_path);
      final cachedAt = DateTime.parse(json['_cached_at'] as String);
      if (DateTime.now().difference(cachedAt) > _maxAge) return null;
      return CatalogModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CatalogModel catalog) async {
    final json = catalog.toJson();
    json['_cached_at'] = DateTime.now().toIso8601String();
    await _fm.writeJson(_path, json);
  }
}
```

### 2.4. Provider du catalogue

```dart
// features/onboarding/presentation/providers/catalog_providers.dart

@riverpod
Future<CatalogModel> catalog(Ref ref) async {
  final cache = ref.watch(catalogCacheProvider);
  final api = ref.watch(dataPackApiProvider);

  // 1. Essayer le cache local
  final cached = await cache.loadCached();
  if (cached != null) return cached;

  // 2. Télécharger depuis le CDN
  final remote = await api.fetchCatalog();
  await cache.save(remote);
  return remote;
}

/// Boîtiers groupés par marque, pour l'affichage
@riverpod
Future<Map<BrandInfo, List<CatalogBody>>> bodiesByBrand(Ref ref) async {
  final catalog = await ref.watch(catalogProvider.future);

  final grouped = <BrandInfo, List<CatalogBody>>{};
  for (final brand in catalog.brands) {
    final brandBodies = catalog.bodies
        .where((b) => b.brandId == brand.id)
        .toList();
    if (brandBodies.isNotEmpty) {
      grouped[brand] = brandBodies;
    }
  }
  return grouped;
}

/// Objectifs compatibles avec le boîtier sélectionné, triés par popularité
@riverpod
List<CatalogLens> availableLenses(Ref ref) {
  final selectedBody = ref.watch(selectedBodyProvider);
  if (selectedBody == null) return [];

  final lenses = [...selectedBody.lenses];
  lenses.sort((a, b) => a.popularityRank.compareTo(b.popularityRank));
  return lenses;
}

/// Recherche dans les boîtiers
@riverpod
Future<List<CatalogBody>> bodySearchResults(Ref ref, String query) async {
  final catalog = await ref.watch(catalogProvider.future);
  if (query.trim().isEmpty) return [];

  final q = query.toLowerCase().trim();
  return catalog.bodies.where((b) {
    return b.name.toLowerCase().contains(q) ||
           b.displayName.toLowerCase().contains(q) ||
           b.brandId.toLowerCase().contains(q);
  }).toList();
}
```

---

## 3. Écran Sélection Boîtier — Implémentation

### 3.1. Widget

```dart
// features/onboarding/presentation/screens/body_selection_screen.dart

class BodySelectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodiesByBrand = ref.watch(bodiesByBrandProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.selectYourBody)),
      body: bodiesByBrand.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => ErrorDisplay(
          failure: _mapToFailure(e),
          onAction: () => ref.invalidate(catalogProvider),
        ),
        data: (grouped) => _BodySelectionContent(grouped: grouped),
      ),
    );
  }
}

class _BodySelectionContent extends ConsumerStatefulWidget {
  final Map<BrandInfo, List<CatalogBody>> grouped;
  const _BodySelectionContent({required this.grouped});

  @override
  ConsumerState<_BodySelectionContent> createState() => _BodySelectionContentState();
}

class _BodySelectionContentState extends ConsumerState<_BodySelectionContent> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Barre de recherche
      Padding(
        padding: const EdgeInsets.all(16),
        child: SearchBar(
          controller: _searchController,
          hintText: context.l10n.searchByName,
          onChanged: (q) => setState(() => _isSearching = q.isNotEmpty),
        ),
      ),

      // Résultats
      Expanded(
        child: _isSearching
            ? _SearchResults(query: _searchController.text)
            : _GroupedList(grouped: widget.grouped),
      ),

      // Bouton "Mon boîtier n'est pas listé"
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: () => _showNotListedSheet(context),
          child: Text(context.l10n.bodyNotListed),
        ),
      ),
    ]);
  }
}

class _GroupedList extends ConsumerWidget {
  final Map<BrandInfo, List<CatalogBody>> grouped;
  const _GroupedList({required this.grouped});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(children: [
      for (final entry in grouped.entries) ...[
        SectionHeader(title: entry.key.name),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entry.value.map((body) => _BodyChip(body: body)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    ]);
  }
}

class _BodyChip extends ConsumerWidget {
  final CatalogBody body;
  const _BodyChip({required this.body});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedBodyProvider);
    final isSelected = selected?.id == body.id;

    return ActionChip(
      label: Text(body.displayName),
      avatar: isSelected ? const Icon(Icons.check, size: 18) : null,
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      onPressed: () {
        ref.read(selectedBodyProvider.notifier).select(body);
        // Navigation automatique vers l'écran objectifs
        context.go('/onboarding/lens');
      },
    );
  }
}
```

### 3.2. "Mon boîtier n'est pas listé"

```dart
void _showNotListedSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.bodyNotListedTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(context.l10n.bodyNotListedMessage),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: context.l10n.bodyNotListedHint, // "Ex: Sony A7R V"
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                // Stocker localement pour feedback futur
                ref.read(bodyRequestProvider.notifier).submit(value.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.bodyNotListedThanks)),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.bodyNotListedCantContinue,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## 4. Écran Sélection Objectifs — Implémentation

### 4.1. Tri et affichage

Les objectifs sont triés par `popularity_rank`. Les objectifs kit sont marqués avec un badge.

```dart
// features/onboarding/presentation/screens/lens_selection_screen.dart

class LensSelectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = ref.watch(selectedBodyProvider);
    final lenses = ref.watch(availableLensesProvider);
    final selectedLenses = ref.watch(selectedLensesProvider);

    if (body == null) {
      // Normalement impossible — la navigation guard empêche d'arriver ici sans body
      return const ErrorDisplay(failure: GearMissingFailure());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.selectYourLenses),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${body.name} · ${_mountName(body.mountId)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: lenses.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (ctx, i) => _LensTile(
              lens: lenses[i],
              isSelected: selectedLenses.any((l) => l.id == lenses[i].id),
            ),
          ),
        ),

        // Bouton "Mon objectif n'est pas listé"
        TextButton(
          onPressed: () => _showLensNotListedSheet(context, ref),
          child: Text(context.l10n.lensNotListed),
        ),
      ]),

      // FAB : continuer (avec compteur)
      floatingActionButton: selectedLenses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/onboarding/language'),
              label: Text(
                context.l10n.continueWithNLenses(selectedLenses.length),
              ),
              icon: const Icon(Icons.arrow_forward),
            )
          : null,
    );
  }
}

class _LensTile extends ConsumerWidget {
  final CatalogLens lens;
  final bool isSelected;
  const _LensTile({required this.lens, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: isSelected,
      title: Text(lens.displayName),
      subtitle: Row(children: [
        if (lens.isKitLens) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Kit', style: Theme.of(context).textTheme.labelSmall),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          _lensTypeLabel(lens.type, context),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ]),
      onChanged: (_) => ref.read(selectedLensesProvider.notifier).toggle(lens),
    );
  }

  String _lensTypeLabel(String type, BuildContext context) => switch (type) {
    'zoom' => context.l10n.lensTypeZoom,
    'prime' => context.l10n.lensTypePrime,
    'macro' => context.l10n.lensTypeMacro,
    _ => type,
  };
}
```

### 4.2. Validation

```
RÈGLE : Minimum 1 objectif sélectionné.
  - Le FAB "Continuer" n'apparaît pas tant qu'aucun objectif n'est coché
  - Pas de maximum (l'utilisateur peut sélectionner tous ses objectifs)
  - Le premier objectif sélectionné devient l'objectif actif par défaut
```

---

## 5. Écran Langue Firmware — Implémentation

### 5.1. Liste dynamique par boîtier

La liste des langues affichées provient du catalogue : `body.supported_languages`. Chaque boîtier a un set différent.

```dart
// features/onboarding/presentation/screens/firmware_language_screen.dart

class FirmwareLanguageScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = ref.watch(selectedBodyProvider);
    final selectedLang = ref.watch(selectedFirmwareLanguageProvider);

    if (body == null) return const ErrorDisplay(failure: GearMissingFailure());

    final languages = body.supportedLanguages;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.selectFirmwareLanguage)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.firmwareLanguageExplanation(body.displayName),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: languages.length,
            itemBuilder: (ctx, i) {
              final lang = languages[i];
              return RadioListTile<String>(
                value: lang,
                groupValue: selectedLang,
                title: Text(_languageDisplayName(lang)),
                subtitle: Text(lang.toUpperCase()),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(selectedFirmwareLanguageProvider.notifier).select(v);
                  }
                },
              );
            },
          ),
        ),
      ]),
      floatingActionButton: selectedLang != null
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/onboarding/recap'),
              label: Text(context.l10n.continueButton),
              icon: const Icon(Icons.arrow_forward),
            )
          : null,
    );
  }

  String _languageDisplayName(String code) => switch (code) {
    'en' => 'English',
    'fr' => 'Français',
    'de' => 'Deutsch',
    'es' => 'Español',
    'it' => 'Italiano',
    'ja' => '日本語',
    'ko' => '한국어',
    'zh-cn' => '中文(简体)',
    'zh-tw' => '中文(繁體)',
    _ => code,
  };
}
```

### 5.2. Auto-sélection

Si la langue du téléphone correspond à une langue supportée par le boîtier, la pré-sélectionner.

```dart
// Dans le provider
@riverpod
class SelectedFirmwareLanguage extends _$SelectedFirmwareLanguage {
  @override
  String? build() {
    // Pré-sélection basée sur la locale du téléphone
    final body = ref.watch(selectedBodyProvider);
    if (body == null) return null;

    final deviceLang = PlatformDispatcher.instance.locale.languageCode;
    if (body.supportedLanguages.contains(deviceLang)) {
      return deviceLang;
    }
    return null; // Pas de pré-sélection
  }

  void select(String lang) => state = lang;
}
```

---

## 6. Écran Récap & Téléchargement

### 6.1. Affichage du récap

```dart
// features/onboarding/presentation/screens/recap_download_screen.dart

class RecapDownloadScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = ref.watch(selectedBodyProvider)!;
    final lenses = ref.watch(selectedLensesProvider);
    final lang = ref.watch(selectedFirmwareLanguageProvider)!;
    final downloadState = ref.watch(onboardingDownloadProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.yourSetup)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Récap
          _RecapCard(body: body, lenses: lenses, lang: lang),
          const SizedBox(height: 8),

          // Bouton modifier
          TextButton.icon(
            onPressed: downloadState.isLoading
                ? null
                : () => context.go('/onboarding/body'),
            icon: const Icon(Icons.edit, size: 18),
            label: Text(context.l10n.modify),
          ),

          const Spacer(),

          // Estimation de taille
          Text(
            context.l10n.downloadSizeEstimate(
              _formatBytes(body.packSizeBytes),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.offlineAfterDownload,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),

          // État du download
          switch (downloadState) {
            AsyncData() => _DownloadButton(body: body, lenses: lenses, lang: lang),
            AsyncLoading() => const _DownloadProgress(),
            AsyncError(:final error) => _DownloadError(error: error),
          },
        ]),
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  final CatalogBody body;
  final List<CatalogLens> lenses;
  final String lang;

  const _RecapCard({required this.body, required this.lenses, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.camera_alt, size: 20),
              const SizedBox(width: 8),
              Text(body.name, style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 12),
            for (final lens in lenses) ...[
              Row(children: [
                const Icon(Icons.lens_outlined, size: 16),
                const SizedBox(width: 8),
                Text(lens.displayName),
              ]),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.language, size: 16),
              const SizedBox(width: 8),
              Text('${context.l10n.menusIn} ${_languageName(lang)}'),
            ]),
          ],
        ),
      ),
    );
  }
}
```

### 6.2. Provider de download onboarding

```dart
// features/onboarding/presentation/providers/onboarding_download_provider.dart

@riverpod
class OnboardingDownload extends _$OnboardingDownload {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> startDownload({
    required CatalogBody body,
    required List<CatalogLens> lenses,
    required String firmwareLanguage,
  }) async {
    state = const AsyncLoading();

    try {
      // 1. Vérifier la connectivité
      final online = await ref.read(connectivityServiceProvider).hasInternetAccess();
      if (!online) {
        throw const NoNetworkException();
      }

      // 2. Télécharger le data pack
      final downloadUseCase = ref.read(downloadDataPackUseCaseProvider);
      await downloadUseCase.execute(
        bodyId: body.id,
        lensIds: lenses.map((l) => l.id).toList(),
        onProgress: (progress) {
          // Mettre à jour la progression via un provider séparé
          ref.read(downloadProgressProvider.notifier).update(progress);
        },
      );

      // 3. Sauvegarder le profil gear
      final profile = GearProfile(
        bodyId: body.id,
        lensIds: lenses.map((l) => l.id).toList(),
        activeLensId: lenses.first.id,
        firmwareLanguage: firmwareLanguage,
      );
      await ref.read(currentGearProvider.notifier).updateProfile(profile);

      // 4. Marquer l'onboarding comme terminé
      await ref.read(preferencesSourceProvider).setOnboardingComplete(true);

      // 5. Charger les données en mémoire
      final cache = ref.read(cameraDataCacheProvider);
      await cache.load(
        body.id,
        lenses.map((l) => l.id).toList(),
        ref.read(fileManagerProvider),
      );

      state = const AsyncData(null);

      // 6. Naviguer vers Home (via listener dans l'écran)
    } on ShootHelperException catch (e) {
      state = AsyncError(e, StackTrace.current);
    } catch (e, s) {
      state = AsyncError(UnexpectedException(e), s);
    }
  }
}

/// Progression granulaire du download (pour l'UI)
@riverpod
class DownloadProgressState extends _$DownloadProgressState {
  @override
  DownloadProgress build() => const DownloadProgress(
    currentItem: '',
    itemIndex: 0,
    totalItems: 0,
    fraction: 0,
  );

  void update(DownloadProgress progress) => state = progress;
}
```

### 6.3. UI de progression du download

```dart
class _DownloadProgress extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(downloadProgressStateProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(value: progress.fraction),
        const SizedBox(height: 12),
        Text(
          context.l10n.downloadingItem(progress.currentItem),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '${(progress.fraction * 100).round()}%',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _DownloadError extends ConsumerWidget {
  final Object error;
  const _DownloadError({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = _mapToFailure(error);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
        const SizedBox(height: 12),
        Text(failure.userMessage, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => _retryDownload(ref),
          child: Text(context.l10n.retry),
        ),
      ],
    );
  }
}
```

---

## 7. Post-onboarding : Gestion du gear

Après l'onboarding, l'utilisateur peut modifier son matériel depuis les Settings. Les actions possibles sont : ajouter un objectif, supprimer un objectif, changer de boîtier, et changer la langue firmware.

### 7.1. Ajouter un objectif

```
Prérequis : online
Données nécessaires : catalog.json (caché) + 1 fichier lens JSON (~5 KB)
Durée : < 1 seconde

Flow :
  1. [Settings] → Tap "Ajouter un objectif"
  2. [Sélection Objectif] — même écran que l'onboarding
     → Filtre : exclure les objectifs déjà dans le profil
  3. Sélection + confirmation
  4. Téléchargement du lens JSON (si pas déjà en local)
  5. Mise à jour du GearProfile (ajout du lens_id)
  6. Mise à jour du download_state.json
  7. Retour aux Settings
```

```dart
// features/gear/domain/use_cases/add_lens.dart

class AddLens {
  final GearRepository _gearRepo;
  final DataPackRepository _dataPackRepo;
  final FileManager _fm;

  Future<void> execute(String lensId) async {
    // 1. Vérifier si le fichier lens existe déjà
    final gear = await _gearRepo.loadGearProfile();
    if (gear == null) throw const GearMissingFailure();

    final lensPath = 'packs/${gear.bodyId}/lenses/$lensId.json';
    final exists = await _fm.fileExists(lensPath);

    if (!exists) {
      // 2. Télécharger le fichier
      final json = await _dataPackRepo.fetchLensJson(gear.bodyId, lensId);
      await _fm.writeJson(lensPath, json);
    }

    // 3. Mettre à jour le profil
    final updatedProfile = gear.copyWith(
      lensIds: [...gear.lensIds, lensId],
    );
    await _gearRepo.saveGearProfile(updatedProfile);

    // 4. Mettre à jour download_state
    // (via le DownloadStateSource)
  }
}
```

### 7.2. Supprimer un objectif

```
Prérequis : aucun (100% offline)
Contrainte : minimum 1 objectif restant
Si c'est l'objectif actif → switch vers le premier objectif restant

Flow :
  1. [Settings] → Tap sur un objectif → "Supprimer"
  2. Confirmation dialog
  3. Suppression du fichier lens JSON local
  4. Mise à jour du GearProfile (retrait du lens_id)
  5. Si c'était l'actif → switch activeLensId
  6. Invalidation du CameraDataCache pour ce lens
```

```dart
// features/gear/domain/use_cases/remove_lens.dart

class RemoveLens {
  final GearRepository _gearRepo;
  final FileManager _fm;

  Future<void> execute(String lensId) async {
    final gear = await _gearRepo.loadGearProfile();
    if (gear == null) throw const GearMissingFailure();
    if (gear.lensIds.length <= 1) {
      throw const ShootHelperException(
        'Impossible de supprimer le dernier objectif.',
      );
    }

    // 1. Supprimer le fichier local
    final lensPath = 'packs/${gear.bodyId}/lenses/$lensId.json';
    await _fm.deleteFile(lensPath);

    // 2. Mettre à jour le profil
    final newLensIds = gear.lensIds.where((id) => id != lensId).toList();
    final newActiveId = gear.activeLensId == lensId
        ? newLensIds.first
        : gear.activeLensId;

    final updatedProfile = gear.copyWith(
      lensIds: newLensIds,
      activeLensId: newActiveId,
    );
    await _gearRepo.saveGearProfile(updatedProfile);
  }
}
```

### 7.3. Changer de boîtier

```
Prérequis : online
Impact : LOURD — supprime l'ancien data pack, télécharge le nouveau
Confirmation obligatoire

Flow :
  1. [Settings] → Tap "Changer de boîtier"
  2. Dialog de confirmation : "Changer de boîtier supprimera les données
     de ton {current_body} et les objectifs incompatibles."
  3. [Sélection Boîtier] → [Sélection Objectifs] → [Langue Firmware]
     → [Récap & Download]
  4. Même flow que l'onboarding complet
  5. Suppression de l'ancien data pack APRÈS le download du nouveau
     (pas avant — en cas d'échec, l'ancien est intact)
```

```dart
// features/gear/domain/use_cases/change_body.dart

class ChangeBody {
  final GearRepository _gearRepo;
  final FileManager _fm;

  /// Phase 1 : préparer le changement (avant le download)
  Future<String?> getOldBodyId() async {
    final gear = await _gearRepo.loadGearProfile();
    return gear?.bodyId;
  }

  /// Phase 2 : nettoyer après le download réussi du nouveau body
  Future<void> cleanupOldBody(String oldBodyId) async {
    await _fm.deleteDirectory('packs/$oldBodyId');
  }
}
```

### 7.4. Changer la langue firmware

```
Prérequis : AUCUN (100% offline)
Pourquoi : le menu_tree.json contient TOUTES les langues (skill 04/07)

Flow :
  1. [Settings] → Tap sur la langue firmware
  2. [Sélection Langue] — même écran que l'onboarding
  3. Sélection → sauvegarde dans GearProfile
  4. L'UI se met à jour immédiatement (les providers cascadent)
  5. Pas de téléchargement, pas de rechargement de fichiers
```

```dart
// features/gear/domain/use_cases/switch_firmware_language.dart

class SwitchFirmwareLanguage {
  final GearRepository _gearRepo;

  Future<void> execute(String newLanguage) async {
    final gear = await _gearRepo.loadGearProfile();
    if (gear == null) throw const GearMissingFailure();

    final updated = gear.copyWith(firmwareLanguage: newLanguage);
    await _gearRepo.saveGearProfile(updated);
    // Le firmwareLanguageProvider cascade automatiquement
    // → menuNavDisplay se recalcule → l'UI affiche les menus dans la nouvelle langue
  }
}
```

---

## 8. Switch d'objectif actif (Home)

Le switch d'objectif depuis le Home est la micro-action la plus fréquente de gestion du gear. Ça doit être instantané.

```dart
// shared/presentation/widgets/lens_switcher.dart

class LensSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gear = ref.watch(currentGearProvider).valueOrNull;
    if (gear == null || gear.lensIds.length <= 1) {
      // Un seul objectif → pas de switcher
      return const SizedBox.shrink();
    }

    final cache = ref.watch(cameraDataCacheProvider);

    return DropdownButton<String>(
      value: gear.activeLensId,
      items: gear.lensIds.map((id) {
        final lens = cache.isLoaded ? cache.getLens(id) : null;
        return DropdownMenuItem(
          value: id,
          child: Text(lens?.displayName ?? id),
        );
      }).toList(),
      onChanged: (newLensId) {
        if (newLensId != null) {
          ref.read(currentGearProvider.notifier).switchActiveLens(newLensId);
          // Si des résultats sont affichés → ils sont automatiquement invalidés
          // car currentLensProvider change → settingsResultProvider recalcule
        }
      },
    );
  }
}
```

---

## 9. Résumé des actions gear et leur impact

| Action | Réseau | Téléchargement | Fichiers modifiés | Cache invalidé | Résultats recalculés |
|--------|--------|---------------|-------------------|---------------|---------------------|
| **Onboarding complet** | Obligatoire | Data pack entier (~250 KB) | GearProfile + data pack + download_state | Full load | N/A (pas encore de scène) |
| **Ajouter un objectif** | Obligatoire | 1 lens JSON (~5 KB) | GearProfile + download_state + lens file | Ajout dans le cache | Non (pas l'objectif actif) |
| **Supprimer un objectif** | Non | Aucun | GearProfile + suppression lens file | Retrait du cache | Oui si c'était l'actif |
| **Changer de boîtier** | Obligatoire | Data pack entier (~250 KB) | Tout (GearProfile + nouveau data pack) | Full reload | Oui |
| **Changer langue firmware** | Non | Aucun | GearProfile seulement | Non (données déjà en mémoire) | Non (juste l'affichage menu) |
| **Switch objectif actif** | Non | Aucun | GearProfile seulement | Non (le lens est déjà en mémoire) | Oui (si scène soumise) |

---

## 10. Séquence de test de la feature

| # | Scénario | Vérification |
|---|----------|-------------|
| T1 | Onboarding complet happy path | Sélection body → lenses → langue → download → Home accessible |
| T2 | Recherche de boîtier | Taper "a67" → Sony A6700 apparaît |
| T3 | Boîtier non listé | Tap "Non listé" → saisie → feedback → retour sélection |
| T4 | Aucun objectif sélectionné | Le FAB "Continuer" est absent |
| T5 | Langue auto-détectée | Téléphone en FR + body supporte FR → FR pré-sélectionné |
| T6 | Download offline | Tap "Télécharger" sans réseau → message erreur + "Réessayer" |
| T7 | Download interrompu + resume | Couper réseau à 50% → réessayer → reprend |
| T8 | Ajouter objectif (online) | Settings → Ajouter → Sélection → Download 5 KB → objectif dispo |
| T9 | Ajouter objectif (offline) | Bouton grisé "Connexion requise" |
| T10 | Supprimer dernier objectif | Bouton désactivé ou dialog bloquant |
| T11 | Changer de boîtier | Confirmation → full re-setup → ancien data pack supprimé |
| T12 | Changer langue firmware | Instantané, pas de download, menus dans la nouvelle langue |
| T13 | Switch objectif actif | Dropdown → switch → résultats recalculés si scène soumise |
| T14 | Catalogue cache expiré | Cache > 24h → re-télécharge le catalogue |
| T15 | Body dans catalogue mais data pack 404 | Message erreur + "Signaler" |

---

*Ce document est la référence d'implémentation pour les features `onboarding` et `gear` du skill 10. Chaque écran, chaque action, chaque edge case est couvert avec le code concret correspondant.*
