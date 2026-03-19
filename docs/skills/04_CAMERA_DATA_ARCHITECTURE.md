# Camera Data Architecture — ShootHelper

> **Skill 04/22** · Modèle de données caméras/objectifs
> Version 1.0 · Mars 2026
> Réf : 01_PRD.md, 02_USER_FLOWS.md

---

## 1. Vue d'ensemble

Ce document définit **comment les données caméra sont structurées, stockées et distribuées**. C'est le socle de l'app : le moteur de settings, le menu navigation mapper et l'affichage des résultats dépendent tous de ce modèle.

**Principes directeurs :**

- Les données sont **statiques par nature** (specs d'un boîtier = fixes entre deux firmwares)
- Le modèle doit supporter le **multi-langue** nativement (pas un ajout tardif)
- La structure doit permettre l'**ajout d'un nouveau boîtier sans toucher au code** (data-driven)
- Le format doit être **léger** pour le stockage mobile offline (< 5MB par boîtier)
- Le format doit être **facilement éditable par un humain** pour la saisie manuelle depuis les manuels PDF

---

## 2. Entités principales

```
┌─────────────┐       ┌─────────────┐
│   Brand     │──1:N──│    Body     │
└─────────────┘       └──────┬──────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────┴─────┐ ┌─────┴─────┐ ┌─────┴──────┐
        │BodySpec   │ │ MenuTree  │ │ Controls   │
        └───────────┘ └─────┬─────┘ └────────────┘
                            │
                      ┌─────┴─────┐
                      │ MenuItem  │──→ MenuItemLabel (i18n)
                      └─────┬─────┘
                            │
                      ┌─────┴─────┐
                      │ MenuItem  │ (enfants, récursif)
                      └───────────┘

┌─────────────┐       ┌─────────────┐
│   Mount     │──1:N──│   Lens     │
└─────────────┘       └──────┬──────┘
                             │
                       ┌─────┴─────┐
                       │ LensSpec  │
                       └───────────┘

┌─────────────┐
│SettingDef   │──→ SettingNavPath (par body, lié à MenuItem)
└─────────────┘
```

---

## 3. Schéma détaillé de chaque entité

### 3.1. Brand (Marque)

```json
{
  "id": "sony",
  "name": "Sony",
  "logo_asset": "brands/sony.svg"
}
```

Champs :

| Champ | Type | Description |
|-------|------|-------------|
| `id` | string (slug) | Identifiant unique, lowercase, pas d'espace |
| `name` | string | Nom d'affichage |
| `logo_asset` | string | Chemin relatif vers le logo (optionnel MVP) |

Valeurs MVP : `sony`, `canon`, `nikon`, `fujifilm`

---

### 3.2. Mount (Monture)

```json
{
  "id": "sony_e",
  "brand_id": "sony",
  "name": "Sony E-mount",
  "covers_sensor_sizes": ["aps-c", "full-frame"],
  "note": "Les objectifs FE (full-frame) sont compatibles APS-C avec crop. Les objectifs E (APS-C) sur full-frame = vignettage."
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `id` | string (slug) | Identifiant unique |
| `brand_id` | FK → Brand | Marque propriétaire de la monture |
| `name` | string | Nom courant |
| `covers_sensor_sizes` | string[] | Tailles de capteur supportées |
| `note` | string | Info de compatibilité pour l'utilisateur |

Valeurs MVP :

| Mount ID | Marque | Capteurs |
|----------|--------|----------|
| `sony_e` | Sony | aps-c, full-frame |
| `canon_rf` | Canon | aps-c, full-frame |
| `nikon_z` | Nikon | aps-c, full-frame |
| `fuji_x` | Fujifilm | aps-c |

---

### 3.3. Body (Boîtier)

```json
{
  "id": "sony_a6700",
  "brand_id": "sony",
  "mount_id": "sony_e",
  "name": "Sony A6700",
  "display_name": "A6700",
  "sensor_size": "aps-c",
  "crop_factor": 1.5,
  "firmware_versions": ["1.0", "2.0", "3.0"],
  "current_firmware": "3.0",
  "supported_languages": ["en", "fr", "de", "es", "it", "ja", "zh-cn", "ko"],
  "release_year": 2023,
  "spec": { ... },
  "controls": { ... },
  "menu_tree": { ... }
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `id` | string (slug) | Identifiant unique global |
| `brand_id` | FK → Brand | Marque |
| `mount_id` | FK → Mount | Système de monture |
| `name` | string | Nom complet |
| `display_name` | string | Nom court (pour l'UI) |
| `sensor_size` | enum | `aps-c`, `full-frame`, `micro-four-thirds` |
| `crop_factor` | float | Facteur de crop (1.0 pour FF, 1.5 Sony APS-C, 1.6 Canon APS-C) |
| `firmware_versions` | string[] | Versions firmware connues |
| `current_firmware` | string | Version firmware pour laquelle les données sont valides |
| `supported_languages` | string[] | Codes langue ISO 639-1 supportés par le firmware |
| `release_year` | int | Année de sortie |
| `spec` | BodySpec | Spécifications techniques (voir 3.4) |
| `controls` | Controls | Contrôles physiques (voir 3.6) |
| `menu_tree` | MenuTree | Arbre de menus complet (voir 3.7) |

---

### 3.4. BodySpec (Spécifications techniques du boîtier)

C'est le bloc utilisé par le **Settings Engine** pour calculer les réglages optimaux et connaître les limites du matériel.

```json
{
  "sensor": {
    "size": "aps-c",
    "megapixels": 26.0,
    "iso_range": { "min": 100, "max": 32000 },
    "iso_extended_range": { "min": 50, "max": 102400 },
    "iso_usable_max": 6400,
    "dynamic_range_ev": 14.0,
    "has_ibis": true,
    "ibis_stops": 5.0
  },

  "shutter": {
    "mechanical": { "min": "1/4000", "max": "30", "bulb": true },
    "electronic": { "min": "1/8000", "max": "30", "bulb": false },
    "electronic_front_curtain": true,
    "flash_sync_speed": "1/160"
  },

  "autofocus": {
    "system": "hybrid_pdaf",
    "points": 759,
    "modes": ["af-s", "af-c", "dmf", "mf"],
    "areas": ["wide", "zone", "center", "spot", "expanded-spot", "tracking"],
    "subject_detection": ["human_eye", "human_face", "animal_eye", "animal", "bird", "vehicle"],
    "has_eye_af": true,
    "eye_af_modes": ["af-c"],
    "min_ev": -3.0,
    "touch_af": true
  },

  "metering": {
    "modes": ["multi", "center", "spot", "highlight"]
  },

  "exposure": {
    "modes": ["P", "A", "S", "M"],
    "compensation_range": { "min": -5.0, "max": 5.0, "step": 0.3 },
    "bracketing": {
      "exposure": { "max_shots": 5, "max_ev_step": 3.0 },
      "focus": false
    }
  },

  "white_balance": {
    "presets": ["auto", "daylight", "shade", "cloudy", "tungsten", "fluorescent", "flash", "underwater"],
    "custom_kelvin": { "min": 2500, "max": 9900, "step": 100 },
    "custom_slots": 3
  },

  "file_formats": {
    "photo": ["raw", "jpeg", "raw+jpeg"],
    "raw_format": "ARW",
    "jpeg_quality_levels": ["extra-fine", "fine", "standard"],
    "video": ["xavc-s-4k", "xavc-s-hd"]
  },

  "stabilization": {
    "has_ibis": true,
    "ibis_stops": 5.0,
    "ibis_axes": 5
  },

  "drive": {
    "modes": ["single", "continuous-hi", "continuous-mid", "continuous-lo", "self-timer", "bracket"],
    "continuous_fps": { "hi": 11.0, "mid": 6.0, "lo": 3.0 }
  }
}
```

**Champs critiques pour le Settings Engine :**

| Champ | Utilisé pour |
|-------|-------------|
| `iso_range` | Borner les ISO recommandés |
| `iso_usable_max` | Seuil au-delà duquel le moteur avertit du bruit |
| `shutter.mechanical/electronic` | Borner les vitesses possibles |
| `autofocus.modes` | Filtrer les modes AF disponibles |
| `autofocus.subject_detection` | Activer/désactiver Eye-AF et suivi sujet |
| `has_ibis` + `ibis_stops` | Ajuster la vitesse min main levée |
| `crop_factor` (Body) | Calcul focale équivalente pour règle 1/focale |
| `exposure.compensation_range` | Borner la comp. expo |

**Convention `iso_usable_max`** : C'est un jugement éditorial, pas une spec constructeur. On le définit comme l'ISO au-delà duquel le bruit devient **visible et gênant** sur un crop 100% pour un débutant. Source : reviews DPReview/DXOMark + évaluation manuelle. Chaque boîtier a sa propre valeur.

---

### 3.5. Lens (Objectif)

```json
{
  "id": "sigma_18-50_f2.8_dc_dn_c",
  "brand_id": "sigma",
  "mount_id": "sony_e",
  "name": "Sigma 18-50mm f/2.8 DC DN | Contemporary",
  "display_name": "Sigma 18-50mm f/2.8",
  "type": "zoom",
  "designed_for": "aps-c",
  "spec": { ... }
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `id` | string (slug) | Identifiant unique global |
| `brand_id` | string | Marque de l'objectif (peut différer du boîtier) |
| `mount_id` | FK → Mount | Monture physique |
| `name` | string | Nom complet officiel |
| `display_name` | string | Nom court pour l'UI |
| `type` | enum | `prime`, `zoom`, `macro`, `super-telephoto` |
| `designed_for` | enum | `aps-c`, `full-frame` — pour le calcul de compatibilité |
| `spec` | LensSpec | Voir ci-dessous |

**Note MVP** : au lancement on inclut les objectifs natifs + les tiers les plus populaires (Sigma, Tamron) si le temps le permet. Les objectifs n'ont PAS d'arbre de menus — seul le boîtier a des menus. L'objectif n'intervient que dans le calcul des réglages (limites optiques).

### 3.5.1. LensSpec

```json
{
  "focal_length": {
    "type": "zoom",
    "min_mm": 18,
    "max_mm": 50
  },

  "aperture": {
    "type": "constant",
    "max_aperture": 2.8,
    "min_aperture": 22,
    "variable_aperture_map": null
  },

  "focus": {
    "min_focus_distance_m": 0.125,
    "min_focus_distance_at_focal_mm": 18,
    "min_focus_distance_map": [
      { "focal_mm": 18, "distance_m": 0.125 },
      { "focal_mm": 50, "distance_m": 0.30 }
    ],
    "autofocus": true,
    "af_motor": "stepping",
    "manual_override": true,
    "internal_focus": true
  },

  "stabilization": {
    "has_ois": false,
    "ois_stops": null
  },

  "optical": {
    "elements": 13,
    "groups": 10,
    "filter_diameter_mm": 55,
    "max_magnification": 0.33,
    "angle_of_view_diagonal_deg": { "wide": 76.5, "tele": 31.4 }
  },

  "physical": {
    "weight_g": 290,
    "length_mm": 74.5,
    "diameter_mm": 61.6
  }
}
```

**Variable aperture map** (pour les zooms à ouverture variable) :

```json
{
  "type": "variable",
  "max_aperture": 3.5,
  "min_aperture": 22,
  "variable_aperture_map": [
    { "focal_mm": 16, "max_aperture": 3.5 },
    { "focal_mm": 24, "max_aperture": 4.0 },
    { "focal_mm": 35, "max_aperture": 4.5 },
    { "focal_mm": 50, "max_aperture": 5.6 }
  ]
}
```

Le moteur interpole linéairement entre les points pour les focales intermédiaires.

**Champs critiques pour le Settings Engine :**

| Champ | Utilisé pour |
|-------|-------------|
| `focal_length` | Règle 1/focale, cadrage, PDC |
| `aperture.max_aperture` | Borne d'ouverture max |
| `aperture.variable_aperture_map` | Ouverture réelle à la focale utilisée |
| `min_focus_distance_m` | Valider la distance sujet (macro) |
| `has_ois` + `ois_stops` | Combiné avec IBIS pour calcul stabilisation totale |

---

### 3.6. Controls (Contrôles physiques du boîtier)

Ce bloc mappe les **boutons, molettes et raccourcis physiques** du boîtier aux réglages qu'ils contrôlent. C'est ce qui permet d'afficher la "Méthode rapide" dans le Menu Navigation Mapper.

```json
{
  "dials": [
    {
      "id": "rear_dial",
      "position": "rear_top_right",
      "label": { "en": "Rear dial", "fr": "Molette arrière" },
      "default_function": {
        "mode_M": "shutter_speed",
        "mode_A": "exposure_compensation",
        "mode_S": "shutter_speed",
        "mode_P": "program_shift"
      }
    },
    {
      "id": "front_dial",
      "position": "front_grip",
      "label": { "en": "Front dial", "fr": "Molette avant" },
      "default_function": {
        "mode_M": "aperture",
        "mode_A": "aperture",
        "mode_S": "exposure_compensation",
        "mode_P": "program_shift"
      }
    },
    {
      "id": "exposure_comp_dial",
      "position": "top_right",
      "label": { "en": "Exposure comp. dial", "fr": "Molette de compensation d'expo." },
      "default_function": {
        "all_modes": "exposure_compensation"
      }
    }
  ],

  "buttons": [
    {
      "id": "af_on",
      "position": "rear_top_right",
      "label": { "en": "AF-ON", "fr": "AF-ON" },
      "default_function": "af_activate",
      "customizable": true
    },
    {
      "id": "c1",
      "position": "top_right",
      "label": { "en": "C1", "fr": "C1" },
      "default_function": "white_balance",
      "customizable": true
    },
    {
      "id": "fn_button",
      "position": "rear_center",
      "label": { "en": "Fn", "fr": "Fn" },
      "default_function": "function_menu",
      "customizable": false
    }
  ],

  "quick_access": {
    "fn_menu_items": [
      "drive_mode", "focus_mode", "focus_area", "exposure_comp",
      "iso", "white_balance", "metering_mode", "creative_look",
      "flash_mode", "af_face_detect", "file_format", "stabilization"
    ]
  }
}
```

| Champ | Description |
|-------|-------------|
| `dials[].default_function` | Fonction par défaut par mode d'exposition. Le moteur utilise ça pour dire "tourne la molette arrière" au lieu de "va dans le menu". |
| `buttons[].customizable` | Si true, la fonction par défaut peut avoir été changée par l'utilisateur. On affiche quand même la valeur usine + un disclaimer. |
| `quick_access.fn_menu_items` | Réglages accessibles via le bouton Fn (accès rapide, pas besoin du menu complet). |

**Pourquoi mapper les contrôles physiques ?** Parce que pour 80% des réglages courants (ouverture, vitesse, ISO), on ne va PAS dans le menu. On utilise une molette ou le menu Fn. Le Menu Navigation Mapper affiche la "Méthode rapide" en priorité = c'est ces données-là.

---

### 3.7. MenuTree (Arbre de menus)

C'est le cœur du killer feature. L'arbre de menus est une **structure récursive** qui reproduit exactement la hiérarchie des menus telle qu'affichée sur l'écran du boîtier.

#### Structure globale

```json
{
  "firmware_version": "3.0",
  "root": [
    {
      "id": "shooting",
      "icon": "camera",
      "labels": { "en": "Shooting", "fr": "Prise de vue", "de": "Aufnahme", "ja": "撮影" },
      "children": [
        {
          "id": "shooting_mode",
          "labels": { "en": "Shoot Mode", "fr": "Mode de prise de vue" },
          "children": [ ... ]
        },
        {
          "id": "exposure",
          "labels": { "en": "Exposure", "fr": "Exposition/Couleur" },
          "children": [ ... ]
        }
      ]
    },
    {
      "id": "af_mf",
      "icon": "focus",
      "labels": { "en": "AF/MF", "fr": "AF/MF" },
      "children": [ ... ]
    },
    ...
  ]
}
```

#### MenuItem (nœud récursif)

```json
{
  "id": "focus_mode",
  "type": "setting",
  "labels": {
    "en": "Focus Mode",
    "fr": "Mode mise au point",
    "de": "Fokusmodus",
    "ja": "フォーカスモード"
  },
  "setting_id": "af_mode",
  "values": [
    {
      "id": "af-s",
      "labels": { "en": "Single-shot AF", "fr": "AF ponctuel", "de": "Einzelbild-AF", "ja": "シングルAF" },
      "short_labels": { "en": "AF-S", "fr": "AF-S", "de": "AF-S", "ja": "AF-S" }
    },
    {
      "id": "af-c",
      "labels": { "en": "Continuous AF", "fr": "AF continu", "de": "Nachführ-AF", "ja": "コンティニュアスAF" },
      "short_labels": { "en": "AF-C", "fr": "AF-C", "de": "AF-C", "ja": "AF-C" }
    },
    {
      "id": "dmf",
      "labels": { "en": "DMF", "fr": "DMF", "de": "DMF", "ja": "DMF" },
      "short_labels": { "en": "DMF", "fr": "DMF", "de": "DMF", "ja": "DMF" }
    },
    {
      "id": "mf",
      "labels": { "en": "Manual Focus", "fr": "MaP manuelle", "de": "Manueller Fokus", "ja": "マニュアルフォーカス" },
      "short_labels": { "en": "MF", "fr": "MF", "de": "MF", "ja": "MF" }
    }
  ],
  "children": null,
  "tab_index": 2,
  "page_index": 1,
  "item_index": 3,
  "note": null,
  "firmware_added": "1.0",
  "firmware_removed": null
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `id` | string | Identifiant unique dans l'arbre (snake_case) |
| `type` | enum | `category` (nœud navigable), `setting` (réglage modifiable), `info` (lecture seule) |
| `labels` | object<lang, string> | Nom du menu dans chaque langue firmware supportée |
| `setting_id` | string \| null | Lien vers SettingDef (voir 3.8). Null si `type` = `category`. |
| `values` | MenuValue[] \| null | Valeurs possibles si `type` = `setting`. Null si `category`. |
| `children` | MenuItem[] \| null | Sous-menus. Null si `type` = `setting`. |
| `tab_index` | int | Position dans l'onglet de menu principal (pour indiquer "3ème onglet") |
| `page_index` | int | Position de la page dans l'onglet |
| `item_index` | int | Position de l'item dans la page |
| `note` | string \| null | Info complémentaire ("Disponible uniquement en mode M") |
| `firmware_added` | string | Version firmware où cet item est apparu |
| `firmware_removed` | string \| null | Version firmware où cet item a été supprimé (null = toujours présent) |

**Règle importante** : `labels` doit contenir EXACTEMENT le texte affiché à l'écran du boîtier. Pas une traduction libre, pas un résumé — le texte exact. C'est la promesse du produit.

#### Pourquoi `tab_index` / `page_index` / `item_index` ?

La plupart des menus caméra ne sont pas un simple arbre de dossiers. Ils sont organisés en **onglets > pages > items**. Par exemple sur un Sony :

```
Onglet 1 : 📷 Prise de vue (tab_index: 0)
  Page 1 (page_index: 0)
    Item 1 : Mode de prise de vue
    Item 2 : Mode d'entraîn.
    Item 3 : ...
  Page 2 (page_index: 1)
    Item 1 : Exposition
    Item 2 : ISO
    ...
Onglet 2 : 🎥 Vidéo (tab_index: 1)
  ...
```

Ces indices permettent de dire : "Va à l'onglet 1, page 2, 3ème item" — une instruction physiquement actionnable.

---

### 3.8. SettingDef (Définition d'un réglage)

C'est la table de liaison entre le **Settings Engine** (qui calcule des réglages abstraits) et le **MenuTree** (qui sait où trouver chaque réglage dans les menus d'un boîtier précis).

```json
{
  "id": "af_mode",
  "category": "autofocus",
  "name": "Focus Mode",
  "description": "Détermine le comportement de l'autofocus",
  "data_type": "enum",
  "possible_values": ["af-s", "af-c", "dmf", "mf"],
  "adjustable_via_menu": true,
  "adjustable_via_dial": false,
  "adjustable_via_fn": true,
  "affects_exposure": false
}
```

```json
{
  "id": "aperture",
  "category": "exposure",
  "name": "Aperture",
  "description": "Ouverture du diaphragme",
  "data_type": "continuous",
  "unit": "f-stop",
  "step_values": [1.4, 1.8, 2, 2.8, 3.5, 4, 4.5, 5, 5.6, 6.3, 7.1, 8, 9, 10, 11, 13, 14, 16, 18, 20, 22],
  "adjustable_via_menu": false,
  "adjustable_via_dial": true,
  "adjustable_via_fn": false,
  "affects_exposure": true
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `id` | string | Identifiant universel du réglage (indépendant du boîtier) |
| `category` | enum | `exposure`, `autofocus`, `metering`, `white_balance`, `drive`, `file`, `stabilization` |
| `data_type` | enum | `enum` (choix fini), `continuous` (valeur numérique par cran), `boolean` (on/off), `range` (valeur dans un intervalle) |
| `adjustable_via_*` | bool | Indique comment ce réglage peut être modifié (menu, molette, Fn). Varie par boîtier → surchargeable dans SettingNavPath. |

**Liste complète des SettingDefs MVP :**

| id | category | data_type |
|----|----------|-----------|
| `exposure_mode` | exposure | enum |
| `aperture` | exposure | continuous |
| `shutter_speed` | exposure | continuous |
| `iso` | exposure | continuous |
| `iso_auto` | exposure | boolean |
| `exposure_compensation` | exposure | range |
| `af_mode` | autofocus | enum |
| `af_area` | autofocus | enum |
| `subject_detection` | autofocus | enum |
| `metering_mode` | metering | enum |
| `white_balance_mode` | white_balance | enum |
| `white_balance_kelvin` | white_balance | range |
| `file_format` | file | enum |
| `stabilization_body` | stabilization | boolean |
| `drive_mode` | drive | enum |

---

### 3.9. SettingNavPath (Chemin de navigation par boîtier)

C'est la table qui lie un **réglage abstrait** (SettingDef) à un **chemin concret** dans les menus d'un boîtier spécifique. C'est ce qui est affiché dans le flow F5 (Menu Navigation Mapper).

```json
{
  "body_id": "sony_a6700",
  "setting_id": "af_mode",
  "firmware_version": "3.0",

  "menu_path": ["af_mf", "af_mf_settings", "focus_mode"],
  "menu_item_id": "focus_mode",

  "quick_access": {
    "method": "fn_menu",
    "steps": [
      { "action": "press", "target": "fn_button", "labels": { "en": "Press Fn", "fr": "Appuyer sur Fn" } },
      { "action": "navigate", "target": "focus_mode", "labels": { "en": "Select Focus Mode", "fr": "Sélectionner Mode mise au point" } }
    ]
  },

  "dial_access": null,

  "tips": [
    {
      "labels": {
        "en": "You can assign Focus Mode to the C1 button for faster access.",
        "fr": "Tu peux assigner le mode de mise au point au bouton C1 pour un accès plus rapide."
      },
      "related_menu_path": ["setup", "operation_custom", "custom_key", "c1"]
    }
  ]
}
```

```json
{
  "body_id": "sony_a6700",
  "setting_id": "aperture",
  "firmware_version": "3.0",

  "menu_path": null,
  "menu_item_id": null,

  "quick_access": null,

  "dial_access": {
    "exposure_mode": "M",
    "dial_id": "front_dial",
    "labels": {
      "en": "In M mode, turn the front dial to adjust aperture.",
      "fr": "En mode M, tourne la molette avant pour régler l'ouverture."
    }
  },

  "tips": [
    {
      "labels": {
        "en": "In A mode, the front dial also controls aperture.",
        "fr": "En mode A, la molette avant contrôle aussi l'ouverture."
      }
    }
  ]
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `body_id` | FK → Body | Boîtier spécifique |
| `setting_id` | FK → SettingDef | Réglage abstrait |
| `firmware_version` | string | Version firmware pour laquelle ce chemin est valide |
| `menu_path` | string[] \| null | Chemin d'IDs dans le MenuTree (du root au setting). Null si pas accessible via menu. |
| `menu_item_id` | string \| null | ID du MenuItem final |
| `quick_access` | object \| null | Raccourci via Fn ou autre accès rapide |
| `dial_access` | object \| null | Accès via molette physique, conditionné au mode d'exposition |
| `tips` | Tip[] | Astuces contextuelles |

**Comment l'UI reconstruit le chemin affiché :**

1. L'engine calcule `setting_id: "af_mode"` avec `value: "af-c"`
2. L'app cherche le `SettingNavPath` pour `(body_id, setting_id, firmware_version)`
3. Si `dial_access` existe → afficher "Méthode rapide" avec le label localisé
4. Si `quick_access` existe → afficher les étapes Fn
5. Si `menu_path` existe → parcourir le MenuTree en suivant les IDs, récupérer les `labels[langue]` à chaque nœud → construire le breadcrumb "Menu > AF/MF > Mode mise au point"
6. Résoudre la `value` "af-c" dans `MenuItem.values` → afficher le label localisé "AF continu"

---

## 4. Format de stockage et distribution

### 4.1. Format fichier : JSON

Les données sont stockées en **JSON**. Pourquoi pas SQLite ou autre :

| Option | Pour | Contre | Verdict |
|--------|------|--------|---------|
| **JSON** | Lisible par un humain, éditable à la main, facilement versionnable (git), parsing natif sur toutes les plateformes | Pas de requêtes complexes, tout en mémoire | **✅ MVP** |
| SQLite | Requêtes performantes, stockage compact | Plus lourd à éditer manuellement, migration complexe | V2 si performance nécessaire |
| Protobuf/FlatBuffers | Ultra compact, parsing rapide | Illisible pour un humain, tooling supplémentaire | Overkill |

**Le choix JSON est motivé par la contrainte que les données sont construites manuellement.** On va passer des heures à transcrire des manuels PDF — il faut un format qu'un humain peut lire et corriger directement.

### 4.2. Structure du Data Pack

Un data pack = toutes les données nécessaires pour un couple (boîtier, langue).

```
data_packs/
├── sony_a6700/
│   ├── manifest.json          # Métadonnées, version, checksum
│   ├── body.json              # Body + BodySpec + Controls
│   ├── menu_tree.json         # MenuTree complet (toutes langues)
│   ├── nav_paths.json         # Tous les SettingNavPath
│   └── lenses/
│       ├── sony_e_16-50_f3.5-5.6.json
│       ├── sigma_18-50_f2.8.json
│       └── ...
├── canon_r50/
│   ├── manifest.json
│   ├── body.json
│   ├── menu_tree.json
│   ├── nav_paths.json
│   └── lenses/
│       └── ...
└── shared/
    ├── setting_defs.json      # SettingDefs (partagé entre tous les boîtiers)
    ├── brands.json            # Marques
    └── mounts.json            # Montures
```

### 4.3. Manifest

```json
{
  "body_id": "sony_a6700",
  "pack_version": "1.1.0",
  "firmware_version": "3.0",
  "languages_included": ["en", "fr", "de", "ja"],
  "lens_count": 12,
  "total_size_bytes": 1843200,
  "created_at": "2026-03-15T10:00:00Z",
  "checksum_sha256": "a1b2c3d4...",
  "min_app_version": "1.0.0",
  "changelog": [
    { "version": "1.1.0", "changes": ["Correction chemin AF en FR", "Ajout firmware 3.0"] },
    { "version": "1.0.0", "changes": ["Version initiale"] }
  ]
}
```

### 4.4. Estimation de taille

| Composant | Taille estimée |
|-----------|---------------|
| body.json (specs + controls) | ~15 KB |
| menu_tree.json (toutes langues, ~200 items × 4 langues) | ~150 KB |
| nav_paths.json (~15 settings × chemins + tips) | ~30 KB |
| 1 lens JSON | ~5 KB |
| 12 lenses | ~60 KB |
| **Total par boîtier** | **~250 KB** |
| shared/ (setting_defs + brands + mounts) | ~10 KB |

Bien en dessous de la contrainte de 5MB. Même avec 50 objectifs ça reste sous 500 KB par boîtier.

### 4.5. Téléchargement

```
Onboarding :
1. App télécharge shared/ (une seule fois, ~10KB)
2. App télécharge data_packs/{body_id}/manifest.json
3. App télécharge body.json + menu_tree.json + nav_paths.json
4. App télécharge chaque lens sélectionné par l'utilisateur
5. Tout est stocké dans le filesystem local de l'app

Ajout objectif :
→ Télécharger uniquement lenses/{lens_id}.json (~5KB)

Changement langue :
→ Rien à re-télécharger (menu_tree.json contient TOUTES les langues)
→ L'app change juste la clé de lookup dans les labels

Mise à jour data pack :
→ Re-télécharger manifest.json, comparer pack_version
→ Si nouvelle version : re-télécharger les fichiers modifiés (pas tout)
```

---

## 5. Compatibilité boîtier-objectif

### 5.1. Règles de compatibilité

```
Règle 1 : Même monture = compatible
  Body.mount_id == Lens.mount_id → ✅

Règle 2 : Full-frame lens sur APS-C body = compatible (avec crop)
  Lens.designed_for == "full-frame"
  AND Body.sensor_size == "aps-c"
  AND Body.mount_id == Lens.mount_id
  → ✅ compatible, crop_factor appliqué

Règle 3 : APS-C lens sur full-frame body = compatible avec limitation
  Lens.designed_for == "aps-c"
  AND Body.sensor_size == "full-frame"
  AND Body.mount_id == Lens.mount_id
  → ⚠️ compatible, mode APS-C auto (résolution réduite)
  → Note affichée à l'utilisateur

Règle 4 : Montures différentes = incompatible (au MVP)
  Body.mount_id != Lens.mount_id → ❌
  (Les adaptateurs sont hors scope MVP)
```

### 5.2. Matrice de compatibilité MVP

| Body mount | Lenses affichés |
|-----------|-----------------|
| sony_e (APS-C body) | Tous les sony_e (E + FE) |
| sony_e (FF body) | Tous les sony_e (FE natifs, E en mode crop) |
| canon_rf (APS-C body) | Tous les canon_rf (RF + RF-S) |
| canon_rf (FF body) | Tous les canon_rf (RF natifs, RF-S en mode crop) |
| nikon_z (APS-C body) | Tous les nikon_z (Z + Z DX) |
| nikon_z (FF body) | Tous les nikon_z (Z natifs, Z DX en mode crop) |
| fuji_x | Tous les fuji_x |

---

## 6. Internationalisation (i18n) des menus

### 6.1. Stratégie

Chaque texte visible dans les menus du boîtier est stocké dans un objet `labels` avec une clé par langue. **Il n'y a pas de fichier de traduction séparé** — les traductions font partie intégrante de l'entité qu'elles décrivent.

```json
"labels": {
  "en": "Focus Mode",
  "fr": "Mode mise au point",
  "de": "Fokusmodus",
  "ja": "フォーカスモード"
}
```

**Pourquoi inline plutôt qu'un fichier i18n séparé ?**

- Les traductions ne sont PAS des traductions libres — ce sont les **textes exacts affichés par le firmware**
- Chaque boîtier a potentiellement des traductions différentes pour le même concept (Sony dit "Mode mise au point", Canon dit "Mode AF")
- Séparer créerait un risque de désynchronisation entre la structure et les labels
- L'overhead en taille est minime (voir estimations §4.4)

### 6.2. Convention de langue

Codes ISO 639-1, avec extension régionale si nécessaire :

| Code | Langue | Note |
|------|--------|------|
| `en` | English | Anglais international (pas US/UK séparé — les menus caméra ne distinguent pas) |
| `fr` | Français | |
| `de` | Deutsch | |
| `es` | Español | |
| `it` | Italiano | |
| `ja` | 日本語 | |
| `zh-cn` | 中文(简体) | Chinois simplifié |
| `zh-tw` | 中文(繁體) | Chinois traditionnel |
| `ko` | 한국어 | |

**Toutes les langues ne sont pas disponibles pour tous les boîtiers.** Le champ `Body.supported_languages` est la source de vérité.

### 6.3. Fallback

Si un label manque dans la langue demandée :

```
1. Chercher labels[langue_utilisateur]
2. Si absent → labels["en"] (fallback anglais)
3. Si absent → labels[première_clé_disponible]
4. Si aucun label → afficher l'id en snake_case comme dernier recours
```

---

## 7. Versioning et mises à jour firmware

### 7.1. Stratégie

Les données sont versionnées à deux niveaux :

| Niveau | Quoi | Quand ça change |
|--------|------|-----------------|
| **pack_version** | Version du data pack (nos données) | Quand on corrige une erreur, ajoute un objectif, améliore un tip |
| **firmware_version** | Version firmware du boîtier | Quand le constructeur publie un firmware update |

Un firmware update peut :
- Ajouter des items de menu (`firmware_added`)
- Supprimer des items de menu (`firmware_removed`)
- Déplacer des items (changement de `tab_index`/`page_index`)
- Ajouter de nouvelles valeurs à un réglage existant

### 7.2. Gestion multi-firmware

Le menu_tree contient les annotations `firmware_added` et `firmware_removed`. L'app filtre au runtime :

```
Pour afficher le menu d'un boîtier en firmware X :
- Inclure si firmware_added <= X
- Exclure si firmware_removed != null AND firmware_removed <= X
```

Cela permet de supporter **plusieurs versions firmware avec un seul fichier de données** plutôt que de dupliquer tout l'arbre.

### 7.3. Sélection firmware par l'utilisateur

Au MVP, on supporte la **dernière version firmware** de chaque boîtier. Le champ `current_firmware` dans Body indique la version de référence.

En V2, on pourra ajouter un sélecteur firmware dans les settings de l'app pour les utilisateurs qui n'ont pas mis à jour.

---

## 8. Validation et qualité des données

### 8.1. Schéma de validation

Chaque fichier JSON doit passer un schéma de validation (JSON Schema) avant d'être intégré au data pack. Règles :

| Règle | Description |
|-------|-------------|
| Labels complets | Chaque `labels` doit contenir au moins `en` + toutes les langues listées dans `Body.supported_languages` |
| IDs uniques | Aucun doublon d'ID dans le MenuTree, SettingDefs, Lenses |
| Refs valides | Chaque `setting_id` dans MenuTree doit exister dans SettingDefs |
| Paths valides | Chaque `menu_path` dans NavPaths doit correspondre à un chemin réel dans MenuTree |
| Firmware cohérent | `firmware_added` <= `Body.current_firmware` |
| Valeurs cohérentes | Chaque valeur dans `SettingNavPath.value` doit exister dans `MenuItem.values` |
| Specs cohérentes | `BodySpec.autofocus.modes` doit matcher les `values` du MenuItem correspondant |

### 8.2. Pipeline de validation

```
1. Écriture manuelle du JSON (depuis manuels PDF)
2. Validation JSON Schema automatique (CI)
3. Cross-validation inter-fichiers (script custom)
4. Vérification manuelle boîtier en main (spot check sur les chemins de menu critiques)
5. Merge dans le repo de données
6. Build du data pack (minification, checksum)
7. Upload sur le CDN de distribution
```

### 8.3. Checklist par boîtier

Pour valider qu'un boîtier est "prêt" :

```
☐ body.json complet (toutes les specs renseignées)
☐ menu_tree.json avec tous les items de menu photographiquement pertinents
☐ Labels dans toutes les langues de Body.supported_languages
☐ nav_paths.json pour les 15 SettingDefs du MVP
☐ controls.json avec molettes et boutons principaux
☐ Au moins 3 objectifs kit populaires documentés
☐ Validation JSON Schema passée
☐ Cross-validation passée
☐ Spot check sur 5 chemins de menu (boîtier en main ou via manuel PDF)
```

---

## 9. Exemple complet : Sony A6700 + Sigma 18-50mm f/2.8

Voici comment les données se combinent pour un cas réel.

**Scénario** : L'engine recommande `af_mode: "af-c"` pour un portrait en extérieur.

**Résolution du chemin :**

```
1. Engine output : { setting_id: "af_mode", value: "af-c" }

2. Lookup SettingNavPath(body_id: "sony_a6700", setting_id: "af_mode")
   → quick_access: Fn > "Mode mise au point"
   → menu_path: ["af_mf", "af_mf_settings", "focus_mode"]
   → dial_access: null

3. Résolution menu_path dans MenuTree (langue: "fr") :
   root → "af_mf" → labels.fr = "AF/MF"
        → "af_mf_settings" → labels.fr = "Régl. AF/MF"
        → "focus_mode" → labels.fr = "Mode mise au point"

4. Résolution value "af-c" dans MenuItem.values :
   → labels.fr = "AF continu"
   → short_labels.fr = "AF-C"

5. Construction de l'affichage :

   📍 Mode AF → AF-C (AF continu)

   MÉTHODE RAPIDE
   🎛️ Appuyer sur Fn > Sélectionner "Mode mise au point" > AF continu

   VIA LE MENU
   ❶ Menu > AF/MF
   ❷ → Régl. AF/MF
   ❸ → Mode mise au point > AF continu (AF-C)

   💡 Tu peux assigner le mode de mise au point au bouton C1
      pour un accès plus rapide.
      Menu > Réglage > Opération perso. > Régl. Touche perso. > Touche C1
```

---

*Ce document est la référence pour les skills Data Sourcing Strategy (05), Settings Engine (06), i18n & Menu Localization (07), Local Database Design (12), et Menu Navigation Mapper (19).*
