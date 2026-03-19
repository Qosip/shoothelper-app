# Extensibility Playbook — ShootHelper

> **Skill 21/22** · Guides concrets pour étendre l'app sans casser l'existant
> Version 1.0 · Mars 2026
> Réf : Tous les skills précédents

---

## 1. Objectif

Ce document est le **mode d'emploi pour ton futur toi**. Dans 3 mois, 6 mois, 1 an, tu voudras ajouter un boîtier, créer une feature, modifier le moteur. Tu auras oublié les détails. Ce playbook te donne la procédure exacte, étape par étape, sans relire les 21 skills.

Chaque playbook est autonome — tu lis celui dont tu as besoin, tu suis les étapes, c'est fait.

---

## 2. Playbook A — Ajouter un nouveau boîtier

**Temps estimé : 8-15h** (selon la familiarité avec le constructeur)

### Pré-requis

- Le scraper du constructeur existe déjà (skill 05)
- Le boîtier est un hybride supporté par une monture déjà dans `mounts.json`

### Checklist

```
PHASE 1 — Data sourcing (~4-8h)
  ☐ Identifier le Help Guide en ligne du boîtier
  ☐ Vérifier les langues disponibles dans le Help Guide
  ☐ Lancer le scraper pour extraire la structure de menu (EN)
  ☐ Lancer le scraper pour chaque langue supplémentaire
  ☐ Extraire les specs depuis la page "Specifications"
  ☐ Extraire les contrôles physiques depuis "Parts of the camera"
  ☐ Cross-vérifier les specs avec DPReview / open-product-data
  ☐ Définir iso_usable_max (jugement éditorial, voir DXOMark)

PHASE 2 — Structuration (~2-3h)
  ☐ Créer le dossier sources/{body_id}/ dans le data repo
  ☐ Remplir body.json à partir du template (voir §2.1)
  ☐ Générer menu_tree.json depuis le scraping
  ☐ Créer nav_paths.json pour les 15 SettingDefs MVP (voir §2.2)
  ☐ Créer les fichiers lenses/ pour 3-5 objectifs populaires (voir Playbook B)

PHASE 3 — Validation (~1-2h)
  ☐ Lancer python tools/validate.py --all --data sources/
  ☐ Vérifier 0 erreurs de schéma
  ☐ Vérifier 0 erreurs de cross-refs
  ☐ Vérifier 0 erreurs i18n (labels complets pour toutes les langues)
  ☐ Spot check : 5 chemins de menu vérifiés manuellement
      ☐ af_mode (le plus critique)
      ☐ iso
      ☐ white_balance
      ☐ file_format
      ☐ stabilization (si IBIS)

PHASE 4 — Publication (~5min)
  ☐ Ajouter _pack_version: "1.0.0" dans body.json
  ☐ Pull Request sur shoothelper-data → CI valide
  ☐ Review + merge → CD build + deploy automatique
  ☐ Vérifier que le boîtier apparaît dans catalog.json sur le CDN
  ☐ Tester le download depuis l'app (émulateur ou device)

PHASE 5 — Tests (~1h)
  ☐ Ajouter le body aux fixtures de test (test/fixtures/bodies/)
  ☐ Ajouter un scénario snapshot au moteur (test portrait + ce body)
  ☐ Ajouter le body au test cross-brand menu_nav (si nouvelle marque)
  ☐ Lancer flutter test → tout vert
```

### 2.1. Template body.json

Copier depuis un boîtier existant de la même marque et adapter :

```json
{
  "_pack_version": "1.0.0",
  "_changelog": [{ "version": "1.0.0", "changes": ["Version initiale"] }],

  "id": "NEW_BODY_ID",
  "brand_id": "sony|canon|nikon|fujifilm",
  "mount_id": "sony_e|canon_rf|nikon_z|fuji_x",
  "name": "Nom complet officiel",
  "display_name": "Nom court UI",
  "sensor_size": "aps-c|full-frame",
  "crop_factor": 1.5,
  "firmware_versions": ["1.0"],
  "current_firmware": "1.0",
  "supported_languages": ["en", "fr"],
  "release_year": 2025,

  "spec": {
    "sensor": {
      "iso_range": { "min": 100, "max": 32000 },
      "iso_usable_max": 6400,
      "has_ibis": true,
      "ibis_stops": 5.0
    },
    "shutter": {
      "mechanical": { "min": "1/4000", "max": "30", "bulb": true },
      "electronic": { "min": "1/8000", "max": "30" }
    },
    "autofocus": {
      "modes": ["af-s", "af-c", "mf"],
      "areas": ["wide", "zone", "center", "spot", "tracking"],
      "has_eye_af": true,
      "eye_af_modes": ["af-c"],
      "subject_detection": ["human_eye", "human_face", "animal_eye"]
    },
    "metering": { "modes": ["multi", "center", "spot"] },
    "white_balance": {
      "presets": ["auto", "daylight", "shade", "cloudy", "tungsten", "fluorescent"],
      "custom_kelvin": { "min": 2500, "max": 9900 }
    },
    "stabilization": { "has_ibis": true, "ibis_stops": 5.0 },
    "file_formats": { "photo": ["raw", "jpeg", "raw+jpeg"] }
  },

  "controls": {
    "_comment": "Remplir depuis le Startup Manual / Parts of the camera",
    "dials": [],
    "buttons": [],
    "quick_access": { "fn_menu_items": [] }
  }
}
```

### 2.2. Template nav_paths.json

Un fichier avec les 15 SettingDefs MVP. Copier depuis un boîtier de la même marque (la structure des menus est souvent similaire au sein d'une marque) et adapter les `menu_path` et `labels`.

```json
[
  {
    "body_id": "NEW_BODY_ID",
    "setting_id": "af_mode",
    "firmware_version": "1.0",
    "menu_path": ["REMPLIR", "REMPLIR", "REMPLIR"],
    "menu_item_id": "REMPLIR",
    "quick_access": null,
    "dial_access": null,
    "tips": []
  },
  {
    "body_id": "NEW_BODY_ID",
    "setting_id": "aperture",
    "firmware_version": "1.0",
    "menu_path": null,
    "menu_item_id": null,
    "quick_access": null,
    "dial_access": {
      "exposure_mode": "M",
      "dial_id": "REMPLIR",
      "labels": { "en": "REMPLIR", "fr": "REMPLIR" }
    },
    "tips": []
  }
]
```

**Les 15 settings à documenter :**
`exposure_mode`, `aperture`, `shutter_speed`, `iso`, `iso_auto`, `exposure_compensation`, `af_mode`, `af_area`, `subject_detection`, `metering_mode`, `white_balance_mode`, `white_balance_kelvin`, `file_format`, `stabilization_body`, `drive_mode`

### 2.3. Réutilisation intra-marque

Si tu ajoutes un Sony A6400 et que le Sony A6700 est déjà fait :

```bash
# Copier la base
cp -r sources/sony_a6700/ sources/sony_a6400/

# Diff le Help Guide EN pour identifier les changements
# (items de menu ajoutés/supprimés, specs différentes)

# Adapter body.json (specs, id, nom, firmware)
# Adapter menu_tree.json (diff du scraping)
# Adapter nav_paths.json (chemins qui changent)
# Adapter les labels si la structure de menu diffère
```

**Estimation gain : ~50% de temps** par rapport à un boîtier from scratch de la même marque.

---

## 3. Playbook B — Ajouter un objectif

**Temps estimé : 20-30 minutes**

### Checklist

```
☐ Récupérer les specs sur la page produit du constructeur
☐ Cross-vérifier avec Lensfun / DPReview si disponible
☐ Créer sources/{body_id}/lenses/{lens_id}.json (template §3.1)
☐ Vérifier la monture (lens.mount_id == body.mount_id)
☐ Si zoom variable : remplir variable_aperture_map
☐ Si OIS : renseigner has_ois + ois_stops
☐ Lancer python tools/validate.py --schema --data sources/{body_id}/lenses/
☐ Incrémenter _pack_version dans body.json (minor bump)
☐ PR → merge → deploy
```

### 3.1. Template lens.json

```json
{
  "id": "BRAND_FOCAL_APERTURE_SUFFIX",
  "brand_id": "sigma|sony|canon|nikon|fuji|tamron",
  "mount_id": "sony_e|canon_rf|nikon_z|fuji_x",
  "name": "Nom complet officiel (ex: Sigma 18-50mm f/2.8 DC DN | Contemporary)",
  "display_name": "Nom court UI (ex: Sigma 18-50mm f/2.8)",
  "type": "zoom|prime|macro|super-telephoto",
  "designed_for": "aps-c|full-frame",

  "spec": {
    "focal_length": {
      "type": "zoom|prime",
      "min_mm": 18,
      "max_mm": 50
    },
    "aperture": {
      "type": "constant|variable",
      "max_aperture": 2.8,
      "min_aperture": 22,
      "variable_aperture_map": null
    },
    "focus": {
      "min_focus_distance_m": 0.125,
      "autofocus": true,
      "internal_focus": true
    },
    "stabilization": {
      "has_ois": false,
      "ois_stops": null
    },
    "optical": {
      "filter_diameter_mm": 55,
      "max_magnification": 0.33
    },
    "physical": {
      "weight_g": 290,
      "length_mm": 74.5
    }
  }
}
```

### 3.2. Convention lens_id

```
Format : {marque}_{focale}_{ouverture}_{suffixe}
Exemples :
  sigma_18-50_f2.8_dc_dn_c
  sony_e_16-50_f3.5-5.6_oss
  sony_fe_50_f1.8
  canon_rf-s_18-45_f4.5-6.3_is_stm
  nikon_z_50_f1.8_s
  fuji_xf_18-55_f2.8-4_r_lm_ois
```

---

## 4. Playbook C — Ajouter une nouvelle feature

**Temps estimé : variable** (de quelques heures à quelques semaines selon la feature)

### Checklist

```
PHASE 1 — Design (avant de coder)
  ☐ Définir le périmètre de la feature en 2-3 phrases
  ☐ Lister les écrans nécessaires
  ☐ Identifier les entités nouvelles (propres à la feature)
  ☐ Identifier les entités partagées existantes réutilisées
  ☐ Identifier les repositories nécessaires (nouveau ou existant ?)
  ☐ Définir les use cases
  ☐ Vérifier que la feature ne crée PAS d'import cross-feature

PHASE 2 — Scaffolding
  ☐ Créer le dossier features/{feature_name}/
  ☐ Suivre le template de feature (§4.1)
  ☐ Créer le fichier de routes {feature}_routes.dart
  ☐ Ajouter les routes dans core/router/app_router.dart (1 ligne)

PHASE 3 — Domain
  ☐ Créer les entités dans features/{feature}/domain/entities/
  ☐ Créer les interfaces repository (si nouveau repo)
  ☐ Créer les use cases dans features/{feature}/domain/use_cases/
  ☐ Écrire les tests unitaires des use cases

PHASE 4 — Data (si nécessaire)
  ☐ Créer les models + mappers dans features/{feature}/data/
  ☐ Créer les data sources
  ☐ Implémenter le repository
  ☐ Écrire les tests du mapper et du data source

PHASE 5 — Presentation
  ☐ Créer les providers dans features/{feature}/presentation/providers/
  ☐ Créer les screens et widgets
  ☐ Si besoin d'un provider "pont" avec d'autres features :
      → Le créer dans shared/presentation/providers/
  ☐ Écrire les widget tests

PHASE 6 — Intégration
  ☐ Lancer bash ci/check_imports.sh → 0 violation
  ☐ Lancer flutter test → tout vert
  ☐ Lancer flutter analyze → 0 erreur
  ☐ Tester le flow complet manuellement
```

### 4.1. Template de dossier feature

```bash
# Script pour scaffolder une nouvelle feature
mkdir -p features/$1/domain/entities
mkdir -p features/$1/domain/use_cases
mkdir -p features/$1/presentation/providers
mkdir -p features/$1/presentation/screens
mkdir -p features/$1/presentation/widgets

# Fichier route vide
cat > features/$1/${1}_routes.dart << 'EOF'
import 'package:go_router/go_router.dart';

final ${1}Routes = <RouteBase>[
  // GoRoute(path: '/$1', builder: (_, __) => const ${1^}Screen()),
];
EOF

echo "Feature '$1' scaffoldée dans features/$1/"
echo "N'oublie pas d'ajouter ...${1}Routes dans app_router.dart"
```

### 4.2. Où placer quoi — Arbre de décision

```
Q : L'entité est-elle utilisée par cette feature UNIQUEMENT ?
  ├─ OUI → features/{feature}/domain/entities/
  └─ NON (2+ features) → shared/domain/entities/

Q : Le repository est-il spécifique à cette feature ?
  ├─ OUI → Interface dans features/{feature}/domain/repositories/
  │         Impl dans features/{feature}/data/repositories/
  └─ NON (partagé) → shared/domain/repositories/ + shared/data/repositories/

Q : Le widget est-il réutilisable hors de cette feature ?
  ├─ OUI → shared/presentation/widgets/
  └─ NON → features/{feature}/presentation/widgets/

Q : Le provider doit-il être lu par une autre feature ?
  ├─ OUI → shared/presentation/providers/ (provider "pont")
  └─ NON → features/{feature}/presentation/providers/
```

### 4.3. Connecter la feature au flow existant

**Pattern : listener dans la feature, pas modification de l'existant.**

```dart
// CORRECT — la nouvelle feature écoute un provider existant
// features/history/presentation/providers/auto_save_provider.dart
@Riverpod(keepAlive: true)
class AutoSaveHistory extends _$AutoSaveHistory {
  @override
  void build() {
    ref.listen(settingsResultProvider, (prev, next) {
      if (next.hasValue && next.value != null && prev?.value == null) {
        _saveToHistory(next.value!);
      }
    });
  }
}

// INCORRECT — modifier la feature existante pour appeler la nouvelle
// features/results/presentation/providers/results_providers.dart
// ❌ import '../../history/...' → violation cross-feature
```

### 4.4. Fichiers modifiés hors de la feature

Toute nouvelle feature devrait modifier **au maximum 3 fichiers** hors de son dossier :

| Fichier | Modification |
|---------|-------------|
| `core/router/app_router.dart` | `...{feature}Routes,` (1 ligne) |
| `main.dart` ou `app.dart` | Initialisation d'un provider keepAlive (si nécessaire) |
| `shared/presentation/providers/` | Un nouveau provider "pont" (si la feature produit des données consommées ailleurs) |

Si tu modifies plus de 3 fichiers → quelque chose est mal découpé.

---

## 5. Playbook D — Ajouter un réglage au moteur

**Temps estimé : 2-4h**

Exemple : ajouter la recommandation "Film Simulation" pour les boîtiers Fujifilm.

### Checklist

```
PHASE 1 — Domain
  ☐ Ajouter le SettingDef dans shared/setting_defs.json
      { "id": "film_simulation", "category": "color", "data_type": "enum" }
  ☐ Créer un nouveau resolver
      features/settings_engine/domain/engine/resolvers/film_simulation_resolver.dart
  ☐ Le resolver implémente SettingResolver (interface existante)
  ☐ Enregistrer le resolver dans SettingsEngine (1 ligne)
  ☐ Écrire les tests du resolver

PHASE 2 — Data (par boîtier)
  ☐ Ajouter les items de menu correspondants dans menu_tree.json (boîtiers Fuji)
  ☐ Ajouter le NavPath dans nav_paths.json (boîtiers Fuji)
  ☐ Pour les boîtiers non-Fuji : le resolver retourne null → le réglage n'est pas affiché

PHASE 3 — Presentation
  ☐ Ajouter le label i18n dans app_fr.arb / app_en.arb
  ☐ Ajouter le template d'explication dans ExplanationGenerator
  ☐ Le SettingRow et SettingDetailScreen gèrent déjà n'importe quel setting_id
     → pas de modification UI nécessaire

PHASE 4 — Validation
  ☐ Les tests snapshot existants ne doivent PAS changer
     (le nouveau resolver retourne null pour les boîtiers non-Fuji)
  ☐ Ajouter un snapshot test pour un scénario Fuji avec film_simulation
  ☐ Lancer flutter test → tout vert
```

### 5.1. Créer le resolver

```dart
// features/settings_engine/domain/engine/resolvers/film_simulation_resolver.dart

class FilmSimulationResolver implements SettingResolver {
  @override
  String get settingId => 'film_simulation';

  @override
  SettingRecommendation? resolve(EngineContext context) {
    // Seulement pour Fujifilm
    if (context.body.brandId != 'fujifilm') return null;

    final value = switch (context.scene.subject) {
      Subject.portrait => 'astia',       // Tons doux pour les portraits
      Subject.landscape => 'velvia',     // Couleurs vives pour le paysage
      Subject.street => 'classic_chrome', // Look rétro pour le street
      _ => 'provia',                      // Standard par défaut
    };

    return SettingRecommendation(
      settingId: settingId,
      value: value,
      valueDisplay: _displayName(value),
      explanationShort: _explain(value, context),
      // ...
    );
  }
}
```

### 5.2. Enregistrer le resolver

```dart
// features/settings_engine/domain/engine/settings_engine.dart

final engine = SettingsEngine(resolvers: [
  ExposureModeResolver(),
  ExposureResolver(),
  AfModeResolver(),
  AfAreaResolver(),
  MeteringResolver(),
  WbResolver(),
  DriveResolver(),
  StabilizationResolver(),
  FileFormatResolver(),
  FilmSimulationResolver(),  // ← UNE LIGNE AJOUTÉE
]);
```

**C'est tout.** Le resolver retourne `null` pour les non-Fuji → le réglage n'apparaît pas dans les résultats. L'UI (`SettingRow`, `SettingDetailScreen`, `MenuNavigationScreen`) gère n'importe quel `setting_id` dynamiquement — pas besoin de modifier l'UI.

---

## 6. Playbook E — Modifier le moteur de settings

**Temps estimé : 1-4h** selon l'ampleur du changement

### 6.1. Modifier un arbre de décision existant

Exemple : changer la logique du mode AF pour les portraits en mouvement.

```
CHECKLIST :
  ☐ Identifier le resolver concerné (af_mode_resolver.dart)
  ☐ Modifier la logique
  ☐ Lancer les tests du resolver → vérifier que les cas existants passent
  ☐ Si un test casse :
      → Le changement est voulu ? Mettre à jour le test.
      → Le changement est un effet de bord ? Revoir la logique.
  ☐ Lancer les snapshot tests → si un snapshot change :
      → Vérifier que le changement est une AMÉLIORATION
      → Mettre à jour le snapshot : flutter test --update-goldens
  ☐ Documenter le changement dans un commentaire en tête du resolver
```

### 6.2. Modifier la table EV

```
CHECKLIST :
  ☐ Modifier photography_constants.dart
  ☐ Lancer TOUS les tests du moteur (pas juste le resolver concerné)
      → La table EV affecte tous les calculs d'exposition
  ☐ Vérifier chaque snapshot test modifié manuellement
  ☐ Prioriser le réalisme : comparer avec les résultats d'un posemètre réel
```

### 6.3. Ajouter un nouveau cas spécial (ex: photo de concert)

```
CHECKLIST :
  ☐ Décider si c'est un nouveau subject ou une combinaison existante
      → Nouveau subject : ajouter une valeur à l'enum Subject
      → Combinaison : indoor_dark + portrait + low_light couvre déjà le cas ?
  ☐ Si nouveau subject :
      ☐ Ajouter à l'enum Subject (domain)
      ☐ Ajouter le label i18n
      ☐ Ajouter le chip dans SubjectSelector (scene_input)
      ☐ Mettre à jour chaque resolver pour gérer le nouveau subject
      ☐ Ajouter un scénario de test
      ☐ Ajouter un snapshot test
  ☐ Si combinaison existante : rien à changer dans le code
```

---

## 7. Playbook F — Corriger un chemin de menu

**Temps estimé : 10 minutes**

Le cas le plus fréquent : un utilisateur signale que le chemin affiché ne correspond pas à ce qu'il voit sur son appareil.

```
CHECKLIST :
  ☐ Identifier le body_id et le setting_id concernés
  ☐ Ouvrir sources/{body_id}/nav_paths.json
  ☐ Trouver l'entrée du setting_id
  ☐ Corriger menu_path, menu_item_id, ou labels
  ☐ Si le problème est dans menu_tree.json : corriger le label
  ☐ Vérifier contre le Help Guide officiel (URL dans skill 05)
  ☐ Incrémenter _pack_version (patch bump : 1.0.0 → 1.0.1)
  ☐ PR → CI valide → merge → deploy
  ☐ Les utilisateurs verront un badge "MAJ disponible" dans l'app
```

---

## 8. Playbook G — Supporter un nouveau firmware

**Temps estimé : 1-3h**

Un constructeur publie une mise à jour firmware qui ajoute/modifie des menus.

```
CHECKLIST :
  ☐ Vérifier si le Help Guide en ligne a été mis à jour
  ☐ Re-scraper la page "Menu list" (EN d'abord)
  ☐ Comparer avec le menu_tree.json existant (diff)
  ☐ Pour chaque item AJOUTÉ :
      ☐ Ajouter dans menu_tree.json avec firmware_added: "X.Y"
      ☐ Scraper les labels dans toutes les langues
  ☐ Pour chaque item SUPPRIMÉ :
      ☐ Ajouter firmware_removed: "X.Y" (ne PAS supprimer l'item)
  ☐ Pour chaque item DÉPLACÉ :
      ☐ Mettre à jour tab_index/page_index/item_index
  ☐ Mettre à jour current_firmware dans body.json
  ☐ Mettre à jour firmware_versions dans body.json
  ☐ Si des nav_paths sont affectés → les mettre à jour
  ☐ Incrémenter _pack_version (minor bump)
  ☐ Valider + PR + merge + deploy
```

---

## 9. Playbook H — Ajouter une langue firmware

**Temps estimé : 1-2h** (principalement du scraping)

Exemple : ajouter le portugais pour le Sony A6700.

```
CHECKLIST :
  ☐ Vérifier que le Help Guide existe dans cette langue
      (helpguide.sony.net/ilc/2320/v1/pt/)
  ☐ Lancer le scraper avec la nouvelle langue
  ☐ Merger les labels dans menu_tree.json
      (chaque labels{} reçoit une nouvelle clé "pt": "...")
  ☐ Merger les labels dans nav_paths.json (tips, dial labels)
  ☐ Merger les labels dans controls (buttons, dials)
  ☐ Ajouter "pt" dans body.supported_languages
  ☐ Lancer la validation i18n (python tools/validate.py --i18n)
  ☐ Incrémenter _pack_version (minor bump)
  ☐ PR + merge + deploy
  ☐ La langue apparaît automatiquement dans le sélecteur de langue firmware
```

---

## 10. Playbook I — Ajouter une langue d'app (Couche 1 i18n)

**Temps estimé : 4-8h** (traduction de ~200 clés)

Exemple : ajouter l'espagnol à l'interface de l'app.

```
CHECKLIST :
  ☐ Copier l10n/app_fr.arb → l10n/app_es.arb
  ☐ Traduire chaque clé (ou utiliser un service de traduction)
  ☐ Attention aux templates : les variables {value}, {lens}, etc. ne se traduisent pas
  ☐ Attention au genre/pluriel : utiliser les ICU message format si nécessaire
  ☐ Lancer flutter gen-l10n pour générer le code
  ☐ Ajouter const Locale('es') dans supportedLocales
  ☐ Tester chaque écran en espagnol (widget tests avec locale: Locale('es'))
  ☐ Vérifier que les labels firmware restent dans la langue firmware
     (pas contaminés par la langue app)
```

---

## 11. Playbook J — Ajouter un nouveau constructeur

**Temps estimé : 20-30h** (le plus gros playbook)

Exemple : ajouter Olympus/OM System.

```
PHASE 1 — Infrastructure data (~4h)
  ☐ Ajouter la marque dans shared/brands.json
  ☐ Ajouter la monture dans shared/mounts.json
  ☐ Identifier le format du Help Guide en ligne (URL pattern, structure HTML)
  ☐ Écrire un nouveau scraper (tools/scrapers/om_scraper.py)
  ☐ Tester le scraper sur un boîtier pilote

PHASE 2 — Premier boîtier (~8-15h)
  ☐ Suivre le Playbook A pour le premier boîtier du constructeur
  ☐ Plus long que d'habitude : pas de boîtier de référence pour comparer
  ☐ Valider exhaustivement les chemins de menu (pas juste 5 spot checks)

PHASE 3 — Cross-brand validation (~2h)
  ☐ Vérifier que la table cross-brand (skill 07 §4.3) est à jour
      → Le nouveau constructeur a-t-il des noms différents pour les mêmes concepts ?
  ☐ Ajouter le constructeur au test cross-brand resolve_menu_path
  ☐ Vérifier que le moteur gère les éventuelles particularités
      (comme Canon Av/Tv ou Fuji Film Simulation)

PHASE 4 — Catalogage
  ☐ Le catalog.json est automatiquement mis à jour par le pipeline
  ☐ Vérifier que la nouvelle marque apparaît dans l'écran de sélection de boîtier
  ☐ Vérifier le logo (si ajouté) dans brands.json
```

---

## 12. Diagramme de décision — "Qu'est-ce que je dois faire ?"

```
Qu'est-ce que tu veux faire ?
│
├─ Ajouter du contenu (pas de code)
│  ├─ Nouveau boîtier (même marque) → Playbook A
│  ├─ Nouveau boîtier (nouvelle marque) → Playbook J puis A
│  ├─ Nouvel objectif → Playbook B
│  ├─ Nouvelle langue firmware → Playbook H
│  ├─ Nouvelle langue app → Playbook I
│  ├─ Correction chemin menu → Playbook F
│  └─ Mise à jour firmware → Playbook G
│
├─ Ajouter du code
│  ├─ Nouvelle feature (écrans, logique) → Playbook C
│  ├─ Nouveau réglage dans le moteur → Playbook D
│  └─ Modifier le moteur existant → Playbook E
│
└─ Corriger un bug
   ├─ Bug dans un chemin de menu → Playbook F
   ├─ Bug dans le moteur → Playbook E §6.1
   └─ Bug UI → localiser le widget, fixer, ajouter un widget test
```

---

## 13. Conventions à respecter (rappel condensé)

### Code

| Règle | Détail |
|-------|--------|
| **Pas d'import cross-feature** | `features/X/` n'importe jamais `features/Y/` |
| **Domain = Dart pur** | Aucun import Flutter/Riverpod/IO dans `domain/` |
| **Entities immutables** | Freezed partout, copyWith pour les modifications |
| **Un use case = une action** | Méthode unique `execute()` |
| **Un resolver = un réglage** | Implémente `SettingResolver`, retourne `null` si non applicable |
| **Providers ponts dans shared/** | Pas de logique, juste du state passthrough |

### Data

| Règle | Détail |
|-------|--------|
| **Labels = texte exact firmware** | Pas de reformulation, pas de correction de casse |
| **IDs en snake_case** | `af_mode`, `sony_a6700`, `sigma_18-50_f2.8` |
| **Version semver** | MAJOR.MINOR.PATCH pour pack_version |
| **Validation CI obligatoire** | Aucun merge sans `validate.py` vert |

### Tests

| Règle | Détail |
|-------|--------|
| **Nouveau resolver = tests** | Chaque branche de l'arbre de décision testée |
| **Nouveau boîtier = snapshot** | Au moins 1 scénario snapshot avec ce boîtier |
| **Modifier le moteur = vérifier snapshots** | Si un snapshot change, vérifier que c'est une amélioration |
| **Couverture moteur ≥ 95%** | Non négociable |

---

## 14. Template de PR pour le data repo

```markdown
## Type de changement
- [ ] Nouveau boîtier
- [ ] Nouvel objectif
- [ ] Correction de données
- [ ] Mise à jour firmware
- [ ] Nouvelle langue

## Boîtier(s) concerné(s)
- {body_id}

## Changements
- ...

## Vérification
- [ ] `python tools/validate.py --all` → 0 erreur
- [ ] Spot check : 5 chemins de menu vérifiés
- [ ] pack_version incrémentée
- [ ] changelog mis à jour dans body.json
```

---

## 15. Template de PR pour l'app

```markdown
## Type de changement
- [ ] Nouvelle feature
- [ ] Nouveau resolver
- [ ] Bug fix
- [ ] Refactoring

## Feature / Skill concerné
- {feature_name} / Skill {N}

## Changements
- ...

## Tests
- [ ] Tests unitaires ajoutés/mis à jour
- [ ] Widget tests ajoutés/mis à jour (si UI modifiée)
- [ ] Snapshot tests vérifiés (si moteur modifié)
- [ ] `flutter test` → tout vert
- [ ] `flutter analyze` → 0 erreur
- [ ] `bash ci/check_imports.sh` → 0 violation

## Fichiers modifiés hors de features/{feature}/
- {liste — devrait être ≤ 3 fichiers}
```

---

*Ce document est le guide de survie pour maintenir et étendre ShootHelper sur le long terme. Imprime-le, bookmark-le, garde-le à portée. C'est le skill qui fait que le projet survit au-delà du MVP.*
