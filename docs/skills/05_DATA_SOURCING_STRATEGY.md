# Data Sourcing Strategy — ShootHelper

> **Skill 05/22** · Sources concrètes, pipeline d'ingestion, manuels PDF, APIs constructeurs
> Version 1.0 · Mars 2026
> Réf : 01_PRD.md, 04_CAMERA_DATA_ARCHITECTURE.md

---

## 1. Vue d'ensemble

Ce document répond à UNE question : **où et comment obtenir les données définies dans le skill 04 (Camera Data Architecture) ?**

Les données à sourcer se répartissent en 3 catégories de difficulté très différente :

| Catégorie | Exemples | Difficulté | Source principale |
|-----------|----------|-----------|-------------------|
| **Specs techniques** | ISO range, vitesse obtu, points AF, capteur | Facile | Sites de specs, bases open-source, manuels |
| **Arbre de menus + labels i18n** | Structure complète des menus, noms exacts par langue | Difficile | Help Guides officiels en ligne (multi-langue) |
| **Contrôles physiques + chemins de navigation** | Molettes, boutons, raccourcis, chemin menu→réglage | Très difficile | Manuels + vérification boîtier en main |

**Vérité fondamentale** : il n'existe aucune API constructeur qui donne ces données. Tout sera construit manuellement ou semi-automatiquement à partir de sources publiques. C'est un travail de data entry, pas de développement API.

---

## 2. Sources par constructeur

### 2.1. Sony

#### Help Guide en ligne (SOURCE PRIMAIRE)

Sony publie un **Help Guide interactif** pour chaque boîtier, disponible en HTML multi-langue à des URLs prédictibles.

| Boîtier | Code produit | URL pattern |
|---------|-------------|-------------|
| A6700 | ILCE-6700 | `helpguide.sony.net/ilc/2320/v1/{lang}/` |
| A6400 | ILCE-6400 | `helpguide.sony.net/ilc/1910/v1/{lang}/` |
| A7 IV | ILCE-7M4 | `helpguide.sony.net/ilc/2130/v1/{lang}/` |
| A7C II | ILCE-7CM2 | `helpguide.sony.net/ilc/2330/v1/{lang}/` |

Langues disponibles : `en`, `fr`, `de`, `es`, `it`, `ja`, `zh-cn`, `zh-tw`, `ko`, et d'autres selon le modèle.

**Contenu exploitable :**

- Liste complète des items de menu avec structure hiérarchique (page "Finding functions from MENU")
- Descriptions de chaque réglage avec valeurs possibles
- Noms exacts des menus **dans chaque langue** (chaque Help Guide existe en version localisée)
- Spécifications complètes (page "Specifications")
- Descriptions des boutons et molettes

**Qualité** : Excellente. Les Help Guides Sony sont les plus structurés des 4 constructeurs. La navigation HTML est propre, les pages sont bien découpées par réglage. Le fait que chaque langue soit un site séparé avec les mêmes URLs rend la correspondance des labels triviale.

**Méthode d'extraction** : Scraping HTML des pages de menu. Chaque page a une structure DOM cohérente. On peut écrire un script qui parcourt la page "Finding functions from MENU" (ex: `contents/221h_list_of_menu_items_ilc2320.html`) et extrait l'arbre.

#### Manuels PDF

Disponibles sur `sony.com/electronics/support/e-mount-body-ilce-6000-series/ilce-6700/manuals`. Les PDFs "Help Guide" sont des exports des Help Guides en ligne — même contenu, format moins exploitable. **Préférer le Help Guide HTML.**

Le "Startup Manual" (guide rapide) contient les diagrammes des boutons/molettes — utile pour la partie Controls.

#### Sites tiers

- **DPReview** (`dpreview.com/products`) : Specs détaillées, comparaisons. Utile pour cross-vérification.
- **Sony Alpha Shooters** (`alphashooters.com`) : Guides utilisateur communautaires, liens vers manuels.

---

### 2.2. Canon

#### Help Guide en ligne (SOURCE PRIMAIRE)

Canon publie un "Advanced User Guide" en HTML.

| Boîtier | Code doc | URL pattern |
|---------|---------|-------------|
| R50 | C011 | `cam.start.canon/{lang}/C011/manual/html/` |
| R10 | C009 | `cam.start.canon/{lang}/C009/manual/html/` |
| R7 | C008 | `cam.start.canon/{lang}/C008/manual/html/` |
| R6 Mark II | C010 | `cam.start.canon/{lang}/C010/manual/html/` |

Langues : `en`, `fr`, `de`, `es`, `it`, `ja`, `zh`, `ko`, et autres.

**Contenu exploitable :**

- Pages "Tab Menus" avec structure complète par onglet (Shooting, AF, Playback, Setup, Custom Functions)
- Chaque item de menu a sa propre page HTML avec description et valeurs
- Structure très claire : Shooting Menu 1-8, AF Menu 1-5, Playback 1-2, Setup 1-5, Custom Functions 1-3

**Qualité** : Très bonne. Canon structure ses menus par numéro d'onglet (Shooting 1, Shooting 2…), ce qui correspond directement au `tab_index` et `page_index` de notre modèle de données.

**Méthode d'extraction** : Les pages "Tab Menus" (ex: `UG-03_Shooting_0020.html`) listent tous les items avec liens vers les pages détaillées. Scraping structuré possible.

**Particularité Canon** : En modes "Basic Zone" (auto), certains onglets/items sont masqués. Nos données ne documenteront que les modes P/Tv/Av/M (cohérent avec notre cible utilisateur : débutant qui passe en manuel).

---

### 2.3. Nikon

#### Reference Guide en ligne (SOURCE PRIMAIRE)

Nikon publie un "Reference Guide" en HTML.

| Boîtier | URL |
|---------|-----|
| Z50 II | `onlinemanual.nikonimglib.com/z50II/{lang}/` |
| Z30 | `onlinemanual.nikonimglib.com/z30/{lang}/` |
| Zf | `onlinemanual.nikonimglib.com/zf/{lang}/` |
| Z6 III | `onlinemanual.nikonimglib.com/z6III/{lang}/` |

Langues : `en`, `fr`, `de`, `es`, `it`, `ja`, `zh_CN`, `ko`, et autres.

**Contenu exploitable :**

- Section "Menu Guide" avec structure hiérarchique complète
- Pages dédiées par item de menu
- Section "Control index" (diagramme des boutons avec descriptions)
- Section "Display index" (éléments affichés à l'écran)

**Qualité** : Bonne. La structure est un peu moins propre que Sony/Canon pour le scraping, mais le contenu est complet. La section "Control index" est particulièrement utile pour mapper les contrôles physiques.

**Particularité Nikon** : Les menus Nikon utilisent le "G button" (bouton Menu) avec des onglets en haut, et un "i button" (i menu) pour l'accès rapide. Deux systèmes de navigation à documenter.

---

### 2.4. Fujifilm

#### Manuels en ligne (SOURCE PRIMAIRE)

Fujifilm publie ses manuels sur un domaine dédié.

| Boîtier | URL |
|---------|-----|
| X-T5 | `fujifilm-dsc.com/en/manual/x-t5/` |
| X-S20 | `fujifilm-dsc.com/en/manual/x-s20/` |

Langues : `en`, `fr`, `de`, `es`, `it`, `ja`, `zh_cn`, `ko`, et autres.

**Contenu exploitable :**

- Structure de menu complète dans la section "Menus"
- Chaque item de menu documenté avec valeurs possibles
- Section "Parts of the Camera" pour les contrôles physiques

**Qualité** : Correcte mais moins structurée pour le scraping que Sony/Canon. Les pages sont plus narratives. La structure de menu est documentée mais pas aussi proprement hiérarchisée.

**Particularité Fujifilm** : Les menus Fuji utilisent un Q Menu (accès rapide) très riche. La molette avant et arrière ont des fonctions contextuelles. Fuji a aussi les "Film Simulations" — un système unique qui n'existe pas chez les autres.

---

## 3. Sources pour les specs techniques (BodySpec)

Les specs sont la partie la plus facile à sourcer car de nombreuses bases de données existent.

### 3.1. Sources primaires (constructeurs)

| Source | URL | Contenu | Format |
|--------|-----|---------|--------|
| Sony Help Guide - Specs | `helpguide.sony.net/.../specifications` | Specs complètes officielles | HTML |
| Canon Product Page | `canon.com/cameras/eos-r50` | Specs détaillées | HTML |
| Nikon Product Page | `nikon.com/products/mirrorless-cameras/` | Specs détaillées | HTML |
| Fujifilm Product Page | `fujifilm-x.com/products/cameras/` | Specs détaillées | HTML |

### 3.2. Sources secondaires (agrégateurs)

| Source | URL | Contenu | Licence |
|--------|-----|---------|---------|
| **open-product-data/digital-cameras** | `github.com/open-product-data/digital-cameras` | Base communautaire YAML, specs détaillées, 3700+ caméras | Open (community) |
| **DPReview** | `dpreview.com/products` | 1700+ cameras, specs détaillées, reviews | Copyright DPReview |
| **digicamdb.com** | `digicamdb.com` | Specs capteur, comparaisons | Copyright |
| **Camera Database API** | `rapidapi.com (Camera Database)` | API REST avec specs (ISO, shutter, mount…) + lenses | Freemium API |

### 3.3. Sources pour les specs objectifs (LensSpec)

| Source | URL | Contenu | Licence |
|--------|-----|---------|---------|
| **Lensfun** | `github.com/lensfun/lensfun` | Base XML open-source : mounts, cameras, lenses avec specs optiques | LGPL-3.0 |
| **Pages produit constructeurs** | Varies | Specs complètes officielles | Copyright |
| **DPReview Lens database** | `dpreview.com/products` | 450+ lenses avec specs | Copyright |

**Lensfun** est particulièrement intéressant : c'est une base open-source maintenue par la communauté qui contient les mounts, les compatibilités body-lens, et les specs optiques de base. Le format XML est structuré avec des entrées par constructeur. On ne l'utilisera pas directement (pas les bonnes données pour nos besoins menu), mais c'est une excellente source de cross-validation pour les specs objectifs et les compatibilités de monture.

### 3.4. Source pour `iso_usable_max` (jugement éditorial)

Ce champ n'est dans aucune base de données — c'est un jugement subjectif.

| Source | Usage |
|--------|-------|
| DPReview Studio Scene comparisons | Comparaison visuelle du bruit par ISO |
| DXOMark ISO scores | Score numérique de performance high-ISO |
| YouTube reviews (ex: Gerald Undone, DPReview TV) | Tests terrain bruit high-ISO |
| Expérience personnelle (ton A6700) | Validation terrain |

**Méthode** : Pour chaque boîtier, définir `iso_usable_max` comme l'ISO au-delà duquel le bruit est **clairement visible sur un crop 100% et gênant pour un tirage standard**. Ordre de grandeur :

| Catégorie | iso_usable_max typique |
|-----------|----------------------|
| APS-C récent (A6700, X-T5) | 6400 |
| APS-C entrée de gamme (A6400, R50) | 3200-6400 |
| Full-frame récent (A7 IV, Z6 III) | 12800 |
| Full-frame entrée de gamme (A7C II) | 6400-12800 |

---

## 4. Sources pour l'arbre de menus (MenuTree + i18n)

C'est **la partie la plus critique et la plus coûteuse** du projet. Aucune base de données n'existe pour ça — c'est du travail manual/semi-automatisé.

### 4.1. Stratégie d'extraction

```
Pour chaque boîtier MVP :

ÉTAPE 1 : Extraction automatisée (scraping)
├── Scraper le Help Guide EN pour la structure de base
├── Extraire la hiérarchie des menus (onglets > pages > items)
├── Extraire les valeurs possibles de chaque réglage
└── Sortie : menu_tree.json avec labels EN uniquement

ÉTAPE 2 : Enrichissement multi-langue (scraping)
├── Pour chaque langue supportée par le boîtier :
│   ├── Scraper la même page dans la version localisée du Help Guide
│   ├── Matcher chaque item par sa position/URL (identique entre langues)
│   └── Extraire le label dans cette langue
└── Sortie : menu_tree.json avec labels complets

ÉTAPE 3 : Mapping des SettingNavPaths (semi-manuel)
├── Pour chaque SettingDef du MVP (15 réglages) :
│   ├── Identifier l'item de menu correspondant dans le MenuTree
│   ├── Documenter le chemin complet (menu_path)
│   ├── Documenter l'accès rapide (Fn, dial, bouton)
│   └── Rédiger les tips contextuels
└── Sortie : nav_paths.json

ÉTAPE 4 : Vérification (manuel)
├── Spot check sur 5 chemins critiques minimum
├── Vérification boîtier en main OU vidéo YouTube du menu
└── Correction des erreurs
```

### 4.2. Faisabilité du scraping par constructeur

| Constructeur | Faisabilité scraping | Pourquoi |
|-------------|---------------------|----------|
| **Sony** | ★★★★★ | URLs prédictibles, même structure HTML entre langues, page "Finding functions from MENU" avec arbre complet |
| **Canon** | ★★★★☆ | Pages "Tab Menus" bien structurées, liens vers chaque item, HTML propre |
| **Nikon** | ★★★☆☆ | Structure HTML moins propre, "Menu Guide" narrative plutôt que tabulaire, mais contenu complet |
| **Fujifilm** | ★★☆☆☆ | Pages plus narratives, structure moins évidente pour le scraping. Plus de travail manuel. |

### 4.3. Correspondance inter-langue

Le trick qui rend le multi-langue faisable : **les Help Guides de chaque constructeur utilisent les mêmes URLs/identifiants de page entre les langues**. Seule la partie `{lang}` change dans l'URL.

Exemple Sony A6700 :
```
EN : helpguide.sony.net/ilc/2320/v1/en/contents/0201B_using_menu.html
FR : helpguide.sony.net/ilc/2320/v1/fr/contents/0201B_using_menu.html
DE : helpguide.sony.net/ilc/2320/v1/de/contents/0201B_using_menu.html
JA : helpguide.sony.net/ilc/2320/v1/ja/contents/0201B_using_menu.html
```

Même page, même identifiant (`0201B_using_menu`), contenu traduit. On peut donc :
1. Parser la version EN pour extraire la structure + les IDs
2. Parser chaque autre langue avec les mêmes IDs pour extraire les labels localisés
3. Merger le tout dans un seul `menu_tree.json`

**C'est la raison pour laquelle le multi-langue est faisable pour un side project.** On n'a pas à traduire manuellement — on extrait les traductions officielles.

---

## 5. Sources pour les contrôles physiques (Controls)

### 5.1. Diagrammes du boîtier

| Source | Contenu |
|--------|---------|
| Help Guide (toutes marques) - "Parts of the camera" | Diagrammes annotés avec chaque bouton/molette nommé |
| Startup Manual / Quick Start Guide (PDF) | Diagrammes simplifiés, souvent plus clairs |
| Ken Rockwell user guides | Descriptions détaillées de chaque contrôle avec fonction par mode |

### 5.2. Fonctions des molettes et boutons

Les Help Guides documentent les fonctions par défaut de chaque contrôle. Exemple Sony :
- Page "Control wheel" : décrit ce que font haut/bas/gauche/droite par mode
- Page "Rear dial / Front dial" : fonction par mode d'exposition
- Page "Custom Key" : liste des fonctions assignables

**Méthode** : Extraction manuelle depuis les Help Guides. Volume faible (5-10 contrôles par boîtier), pas besoin de scraping.

### 5.3. Menu Fn / Quick Menu

Chaque constructeur a un système d'accès rapide :

| Constructeur | Système | Documentation |
|-------------|---------|---------------|
| Sony | Fn Menu (12 items par défaut) | Help Guide "Fn (Function) button" |
| Canon | Q Menu (Quick Menu) | Help Guide "Quick Control" |
| Nikon | i Menu | Reference Guide "i button (i menu)" |
| Fujifilm | Q Menu | Manuel "Q (Quick Menu) Button" |

---

## 6. Pipeline d'ingestion complet

### 6.1. Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                    PIPELINE D'INGESTION                         │
│                                                                 │
│  ┌──────────────┐     ┌──────────────┐     ┌───────────────┐   │
│  │  SCRAPING     │ ──→ │  PARSING     │ ──→ │  STRUCTURING  │   │
│  │              │     │              │     │               │   │
│  │ Help Guides  │     │ HTML → JSON  │     │ Raw → Schema  │   │
│  │ multi-langue │     │ brut         │     │ conforme      │   │
│  └──────────────┘     └──────────────┘     └───────┬───────┘   │
│                                                     │           │
│  ┌──────────────┐     ┌──────────────┐     ┌───────┴───────┐   │
│  │  PACKAGING   │ ←── │  VALIDATION  │ ←── │  ENRICHMENT   │   │
│  │              │     │              │     │               │   │
│  │ Data Packs   │     │ JSON Schema  │     │ NavPaths +    │   │
│  │ + Manifests  │     │ + Cross-ref  │     │ Controls +    │   │
│  └──────┬───────┘     └──────────────┘     │ Tips (manuel) │   │
│         │                                   └───────────────┘   │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │  DISTRIBUTION │                                               │
│  │              │                                               │
│  │ CDN / API    │                                               │
│  └──────────────┘                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2. Étape par étape

#### Étape 1 : Scraping (automatisé)

**Outil** : Script Python custom (requests + BeautifulSoup).

**Pour chaque boîtier** :
1. Télécharger la page index du Help Guide (version EN)
2. Identifier la page "Menu list" / "Finding functions from MENU"
3. Parser la structure hiérarchique (onglets → pages → items)
4. Pour chaque item : suivre le lien vers la page détaillée, extraire :
   - Nom du réglage
   - Description
   - Valeurs possibles avec descriptions
5. Répéter pour chaque langue supportée (même URLs, lang différent)
6. Exporter en JSON brut

**Temps estimé par boîtier** : 2-4h de dev du scraper (la première fois), puis ~30min par boîtier supplémentaire (ajustements mineurs par constructeur).

**Sortie** : `raw/{body_id}/menu_tree_raw.json`

#### Étape 2 : Parsing & Structuring (semi-automatisé)

**Outil** : Script Python custom.

1. Transformer le JSON brut en format conforme au schéma `MenuItem` (skill 04)
2. Générer les `id` en snake_case à partir des noms EN
3. Associer chaque item à un `type` (category, setting, info)
4. Matcher les items de type `setting` avec les `SettingDef` correspondants
5. Fusionner les labels multi-langue dans un seul objet `labels`
6. Attribuer les `tab_index`, `page_index`, `item_index`

**Temps estimé par boîtier** : 1-2h (surtout le matching setting_id qui nécessite du jugement humain).

**Sortie** : `structured/{body_id}/menu_tree.json`

#### Étape 3 : Enrichissement (manuel)

C'est là qu'un humain intervient pour les données qui ne peuvent pas être scrapées.

**body.json — Controls** :
1. Ouvrir le Startup Manual PDF + la page "Parts of the camera"
2. Lister les molettes et boutons
3. Documenter la fonction par défaut par mode d'exposition
4. Documenter les fonctions assignables

**nav_paths.json** :
1. Pour chaque SettingDef MVP (15 réglages) :
   - Identifier le chemin dans le MenuTree
   - Documenter l'accès molette (si applicable)
   - Documenter l'accès Fn/Q Menu (si applicable)
   - Rédiger 1-2 tips contextuels
2. Vérifier la cohérence : le `menu_path` doit correspondre à un chemin réel dans `menu_tree.json`

**Temps estimé par boîtier** : 3-5h (la partie la plus chronophage).

**Sortie** : `structured/{body_id}/body.json`, `structured/{body_id}/nav_paths.json`

#### Étape 4 : Specs (semi-automatisé)

1. Extraire les specs depuis la page "Specifications" du Help Guide
2. Cross-vérifier avec DPReview et open-product-data
3. Compléter les champs manquants (ex: `iso_usable_max`) manuellement
4. Intégrer dans `body.json` sous la clé `spec`

**Temps estimé par boîtier** : 1h.

#### Étape 5 : Objectifs (semi-automatisé)

1. Identifier les objectifs kit + populaires pour chaque monture
2. Extraire les specs depuis les pages produit constructeur
3. Cross-vérifier avec Lensfun (pour les specs optiques) et DPReview
4. Structurer en format `Lens` / `LensSpec` (skill 04)

**Temps estimé par objectif** : 30min.

#### Étape 6 : Validation (automatisé + manuel)

1. **JSON Schema validation** : vérifier la conformité structurelle de chaque fichier
2. **Cross-validation** : vérifier les refs entre fichiers (setting_id, menu_path, etc.)
3. **Spot check** : ouvrir le boîtier (ou une vidéo YouTube du menu), vérifier 5 chemins
4. Corriger les erreurs, recommencer si nécessaire

**Temps estimé par boîtier** : 1-2h.

#### Étape 7 : Packaging & Distribution

1. Minifier les JSON (retirer les espaces/indentation)
2. Calculer les checksums SHA-256
3. Générer le `manifest.json`
4. Uploader sur le CDN (ou serveur statique simple pour le MVP)

**Temps estimé** : Automatisé via script, 5min par boîtier.

### 6.3. Estimation de temps total

| Tâche | Par boîtier | 14 boîtiers | Note |
|-------|------------|-------------|------|
| Dev des scrapers | 8h (one-time) | 8h | 4 scrapers, un par constructeur |
| Scraping | 30min | 7h | Quasi automatique après le dev initial |
| Parsing & Structuring | 1.5h | 21h | Semi-auto |
| Enrichissement (Controls + NavPaths) | 4h | 56h | La plus grosse charge |
| Specs | 1h | 14h | |
| Objectifs (× ~8 par boîtier) | 4h | 56h | ~112 objectifs au total |
| Validation | 1.5h | 21h | |
| Packaging | 5min | 1h | Automatisé |
| **TOTAL** | **~13h** | **~184h** | **≈ 23 jours à 8h** |

**C'est beaucoup.** Stratégie de mitigation :

1. **Commencer par 2-3 boîtiers** (Sony A6700, Canon R50, Nikon Z50 II) pour valider le pipeline
2. **Réutiliser entre modèles** d'une même marque : la structure de menu Sony est similaire entre A6700 et A6400 — diff plutôt que refaire from scratch
3. **Prioriser les langues** : commencer avec EN + FR uniquement, ajouter les autres langues après validation
4. **Limiter les objectifs** : 3-5 par boîtier au lancement, pas 8

**Estimation révisée avec cette stratégie** :
- Phase 1 (3 boîtiers, 2 langues, 3-5 objectifs/boîtier) : ~50h ≈ 6-7 jours
- Phase 2 (11 boîtiers restants, toutes langues) : ~130h ≈ 16-17 jours

---

## 7. Outils à développer

### 7.1. Scrapers (4 scripts, un par constructeur)

```
tools/
├── scrapers/
│   ├── sony_scraper.py       # Parse helpguide.sony.net
│   ├── canon_scraper.py      # Parse cam.start.canon
│   ├── nikon_scraper.py      # Parse onlinemanual.nikonimglib.com
│   └── fuji_scraper.py       # Parse fujifilm-dsc.com
├── parsers/
│   ├── menu_parser.py        # Raw HTML → JSON brut
│   ├── structurer.py         # JSON brut → Schema conforme
│   └── merger.py             # Fusion multi-langue
├── validators/
│   ├── schema_validator.py   # Validation JSON Schema
│   ├── cross_validator.py    # Refs inter-fichiers
│   └── diff_checker.py       # Diff entre versions firmware
├── packager/
│   ├── build_pack.py         # Minification + manifest
│   └── checksum.py           # SHA-256
└── helpers/
    ├── spec_extractor.py     # Extraction specs depuis Help Guide
    └── lens_builder.py       # Template pour créer un lens.json
```

### 7.2. Templates de saisie manuelle

Pour les parties manuelles (Controls, NavPaths, Tips), créer des templates JSON pré-remplis avec la structure attendue et des commentaires inline :

```json
// nav_path_template.json
{
  "_comment": "Remplir pour chaque SettingDef. Supprimer les _comment avant packaging.",
  "body_id": "TODO",
  "setting_id": "af_mode",
  "firmware_version": "TODO",

  "menu_path": ["TODO_tab", "TODO_group", "TODO_item"],
  "menu_item_id": "TODO",

  "quick_access": {
    "_comment": "Remplir si accessible via Fn/Q menu. null sinon.",
    "method": "fn_menu",
    "steps": [
      { "action": "press", "target": "fn_button", "labels": { "en": "TODO", "fr": "TODO" } },
      { "action": "navigate", "target": "TODO", "labels": { "en": "TODO", "fr": "TODO" } }
    ]
  },

  "dial_access": {
    "_comment": "Remplir si accessible via molette. null sinon.",
    "exposure_mode": "M",
    "dial_id": "TODO",
    "labels": { "en": "TODO", "fr": "TODO" }
  },

  "tips": []
}
```

---

## 8. Gestion des mises à jour

### 8.1. Quand re-scraper ?

| Événement | Action |
|-----------|--------|
| Nouveau firmware majeur | Re-scraper le Help Guide, diffing avec la version précédente |
| Nouveau boîtier ajouté | Pipeline complet pour ce boîtier |
| Erreur signalée par un utilisateur | Correction manuelle ciblée |
| Nouveau objectif à ajouter | Template lens_builder + specs constructeur |

### 8.2. Workflow de mise à jour firmware

```
1. Constructeur publie firmware X.Y pour Body Z
2. Vérifier si le Help Guide en ligne a été mis à jour
3. Re-scraper la page "Menu list" (EN uniquement d'abord)
4. Diff avec la version précédente :
   - Items ajoutés → firmware_added = "X.Y"
   - Items supprimés → firmware_removed = "X.Y"
   - Items déplacés → mise à jour tab/page/item_index
5. Re-scraper les langues pour les nouveaux items uniquement
6. Mettre à jour nav_paths.json si nécessaire
7. Validation + packaging
8. Incrémenter pack_version
9. Distribuer
```

**Tool** : `diff_checker.py` prend deux versions du menu_tree et sort un rapport des changements.

---

## 9. Considérations légales

### 9.1. Ce qu'on extrait vs ce qui est protégé

| Données extraites | Statut juridique | Justification |
|-------------------|-----------------|---------------|
| Noms de menus ("Mode mise au point") | **Fait non protégeable** | Un label d'interface est un fait fonctionnel, pas une œuvre créative |
| Structure hiérarchique des menus | **Fait non protégeable** | L'organisation d'un menu est une structure fonctionnelle |
| Valeurs de réglages (AF-S, AF-C) | **Fait non protégeable** | Terminologie technique standardisée |
| Spécifications techniques | **Fait non protégeable** | Données factuelles |
| Descriptions/explications des réglages | **Protégé par copyright** | Texte éditorial original — on ne le copie PAS |
| Diagrammes/images du boîtier | **Protégé par copyright** | Œuvres graphiques — on ne les copie PAS |

**Règle** : on extrait des **faits** (noms, structures, valeurs numériques) et on ne reproduit JAMAIS le texte éditorial des manuels. Les explications dans l'app seront rédigées par nous.

### 9.2. Conditions d'utilisation des sites

Les Help Guides Sony/Canon/Nikon/Fuji sont publiés gratuitement sans restriction d'accès. Cependant :
- **Respecter le robots.txt** de chaque site
- **Rate-limiter le scraping** (1 requête/seconde max)
- **Ne pas redistribuer les manuels** eux-mêmes
- **Citer la source** dans les métadonnées de l'app (ex: "Menu data derived from official help guides")

### 9.3. Noms de marques

Les noms Sony, Canon, Nikon, Fujifilm sont utilisés de manière **nominative** (description de compatibilité). C'est autorisé tant qu'on ne suggère pas de partenariat ou d'endorsement. L'app doit inclure un disclaimer type : "ShootHelper n'est pas affilié à Sony, Canon, Nikon ou Fujifilm."

---

## 10. Ordre de priorité

### Phase 1 — Proof of Pipeline (3 boîtiers)

| Priorité | Boîtier | Pourquoi |
|----------|---------|----------|
| 1 | **Sony A6700** | Ton appareil — tu peux vérifier boîtier en main. Help Guide le plus propre. |
| 2 | **Canon R50** | Best-seller entrée de gamme, structure Canon bien documentée. |
| 3 | **Nikon Z50 II** | Concurrent direct du R50, valide le 3ème constructeur. |

Langues Phase 1 : `en` + `fr` uniquement.
Objectifs Phase 1 : 3 par boîtier (kit + 1-2 populaires).

### Phase 2 — Complétion MVP (11 boîtiers restants)

Ordre par facilité d'ajout (même constructeur = structure similaire) :

1. Sony : A6400, A7 IV, A7C II (réutilisation du scraper Sony)
2. Canon : R10, R7, R6 Mark II (réutilisation du scraper Canon)
3. Nikon : Z30, Zf, Z6 III (réutilisation du scraper Nikon)
4. Fujifilm : X-T5, X-S20 (scraper le plus complexe, en dernier)

Langues Phase 2 : toutes les langues supportées par chaque boîtier.

---

*Ce document est la référence pour le développement des outils de scraping et la planification du travail de data entry. Il sera révisé après la Phase 1 pour ajuster les estimations de temps.*
