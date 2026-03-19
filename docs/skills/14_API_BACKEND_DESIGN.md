# API & Backend Design — ShootHelper

> **Skill 14/22** · Backend léger pour distribution des data packs
> Version 1.0 · Mars 2026
> Réf : 04_CAMERA_DATA_ARCHITECTURE.md, 05_DATA_SOURCING_STRATEGY.md, 13_OFFLINE_FIRST_ARCHITECTURE.md

---

## 1. Philosophie : pas de backend

ShootHelper n'a **pas de backend applicatif**. Pas de serveur Node/Python/Go qui tourne. Pas de base de données côté serveur. Pas d'authentification. Pas d'API REST dynamique.

Le "backend" est un **dépôt de fichiers statiques servi par un CDN**. L'app télécharge des fichiers JSON, les stocke localement, et ne recontacte le serveur que pour vérifier les mises à jour ou télécharger de nouvelles données.

**Pourquoi :**

| Raison | Détail |
|--------|--------|
| Budget zéro | Un CDN statique est gratuit ou quasi-gratuit. Un backend applicatif a des coûts récurrents. |
| Zéro maintenance serveur | Pas de crash à 3h du matin, pas de scaling, pas de monitoring d'uptime complexe. |
| Performance | Un fichier JSON servi par un CDN est plus rapide que n'importe quelle API dynamique. |
| Offline-first | L'app ne dépend du serveur que pour le download. Pas d'appel API pendant le flow principal. |
| Sécurité | Pas de backend = pas de surface d'attaque, pas de données utilisateur côté serveur, pas de RGPD serveur. |
| Dev solo | Un seul humain ne peut pas maintenir une app mobile + un backend applicatif + un pipeline de données. |

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ┌──────────────┐    ┌─────────────────┐    ┌────────────────┐  │
│  │              │    │                 │    │                │  │
│  │  DATA REPO   │───→│  BUILD PIPELINE │───→│  CDN STATIQUE  │  │
│  │  (GitHub)    │    │  (GitHub Actions)│    │  (hébergement) │  │
│  │              │    │                 │    │                │  │
│  └──────────────┘    └─────────────────┘    └───────┬────────┘  │
│                                                     │           │
│  Fichiers JSON                Validation,           │           │
│  édités manuellement          minification,         │           │
│  ou par les scrapers          checksums             │ HTTPS     │
│                                                     │           │
│                                              ┌──────▼────────┐  │
│                                              │               │  │
│                                              │  APP MOBILE   │  │
│                                              │  (Flutter)    │  │
│                                              │               │  │
│                                              └───────────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

Les 3 composants :

1. **Data Repo** — Un repo GitHub contenant les fichiers JSON sources (body.json, menu_tree.json, etc.) édités manuellement ou par les scrapers (skill 05)
2. **Build Pipeline** — GitHub Actions qui valide, minifie, calcule les checksums, génère les manifests, et déploie
3. **CDN Statique** — Les fichiers JSON optimisés servis publiquement via HTTPS

---

## 3. Structure du Data Repo

```
shoothelper-data/                          # Repo GitHub
├── README.md
├── .github/
│   └── workflows/
│       ├── validate.yml                   # CI : valide à chaque push
│       └── deploy.yml                     # CD : déploie sur le CDN
│
├── schemas/                               # JSON Schemas de validation
│   ├── body.schema.json
│   ├── lens.schema.json
│   ├── menu_tree.schema.json
│   ├── nav_paths.schema.json
│   ├── manifest.schema.json
│   └── catalog.schema.json
│
├── tools/                                 # Scripts de build
│   ├── validate.py                        # Validation JSON Schema + cross-refs
│   ├── build_manifests.py                 # Génère les manifest.json
│   ├── build_catalog.py                   # Génère le catalog.json
│   ├── minify.py                          # Minification JSON
│   ├── checksum.py                        # SHA-256 checksums
│   └── deploy.sh                          # Upload vers le CDN
│
├── sources/                               # Fichiers JSON SOURCES (lisibles, indentés)
│   ├── shared/
│   │   ├── setting_defs.json
│   │   ├── brands.json
│   │   └── mounts.json
│   │
│   ├── sony_a6700/
│   │   ├── body.json
│   │   ├── menu_tree.json
│   │   ├── nav_paths.json
│   │   └── lenses/
│   │       ├── sigma_18-50_f2.8.json
│   │       ├── sony_e_16-50_f3.5-5.6.json
│   │       └── sony_fe_50_f1.8.json
│   │
│   ├── canon_r50/
│   │   ├── body.json
│   │   ├── menu_tree.json
│   │   ├── nav_paths.json
│   │   └── lenses/
│   │       └── ...
│   └── ...
│
└── dist/                                  # Fichiers CONSTRUITS (minifiés, avec manifests)
    ├── catalog.json                       # Généré par build_catalog.py
    ├── health.json                        # Fichier healthcheck (~10 bytes)
    ├── shared/
    │   ├── setting_defs.json
    │   ├── brands.json
    │   └── mounts.json
    │
    ├── sony_a6700/
    │   ├── manifest.json                  # Généré par build_manifests.py
    │   ├── body.json
    │   ├── menu_tree.json
    │   ├── nav_paths.json
    │   └── lenses/
    │       └── ...
    └── ...
```

**Séparation `sources/` vs `dist/`** : les fichiers sources sont indentés, commentés (via `_comment` keys), lisibles. Les fichiers dist sont minifiés, avec checksums, sans commentaires. On édite dans `sources/`, on déploie `dist/`. Le build pipeline fait la transformation.

---

## 4. Build Pipeline (GitHub Actions)

### 4.1. CI — Validation à chaque push

```yaml
# .github/workflows/validate.yml
name: Validate Data Packs

on:
  push:
    paths: ['sources/**']
  pull_request:
    paths: ['sources/**']

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: pip install jsonschema

      - name: Validate JSON Schema
        run: python tools/validate.py --schemas schemas/ --data sources/

      - name: Cross-reference validation
        run: python tools/validate.py --cross-refs --data sources/

      - name: Check i18n completeness
        run: python tools/validate.py --i18n --data sources/
```

### 4.2. CD — Build & Deploy

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy Data Packs

on:
  push:
    branches: [main]
    paths: ['sources/**']
  workflow_dispatch: # Manual trigger

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Validate
        run: python tools/validate.py --all --data sources/

      - name: Clean dist/
        run: rm -rf dist/ && mkdir dist/

      - name: Minify JSON
        run: python tools/minify.py --input sources/ --output dist/

      - name: Generate manifests
        run: python tools/build_manifests.py --data dist/

      - name: Generate catalog
        run: python tools/build_catalog.py --data dist/ --output dist/catalog.json

      - name: Generate checksums
        run: python tools/checksum.py --data dist/

      - name: Generate health check
        run: echo '{"status":"ok"}' > dist/health.json

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
          cname: data.shoothelper.app  # Custom domain (optionnel)
```

### 4.3. Outils du pipeline

#### validate.py

```python
# tools/validate.py
"""
Validation en 3 passes :
1. JSON Schema : chaque fichier conforme à son schéma
2. Cross-refs : chaque setting_id dans nav_paths existe dans setting_defs,
   chaque menu_path correspond à un chemin réel dans menu_tree
3. i18n : chaque labels{} contient toutes les langues de body.supported_languages
"""

def validate_schema(schemas_dir, data_dir):
    """Valide chaque JSON contre son schéma"""
    # body.json → body.schema.json
    # lens/*.json → lens.schema.json
    # etc.

def validate_cross_refs(data_dir):
    """Vérifie la cohérence inter-fichiers"""
    # Pour chaque nav_path.setting_id → existe dans setting_defs.json
    # Pour chaque nav_path.menu_path → chemin valide dans menu_tree.json
    # Pour chaque nav_path.menu_item_id → existe dans menu_tree.json
    # Pour chaque body.mount_id → existe dans mounts.json
    # Pour chaque body.brand_id → existe dans brands.json

def validate_i18n(data_dir):
    """Vérifie la complétude des traductions"""
    # Pour chaque body : lire supported_languages
    # Pour chaque labels{} dans menu_tree : vérifier que toutes les langues sont présentes
    # Pour chaque labels{} dans nav_paths : idem
    # Pour chaque labels{} dans controls : idem
```

#### build_manifests.py

```python
# tools/build_manifests.py
"""
Génère un manifest.json pour chaque data pack.
Le manifest contient : version, firmware, langues, taille, checksum, changelog.
"""

import hashlib, json, os

def build_manifest(pack_dir):
    body = json.load(open(f"{pack_dir}/body.json"))

    # Calculer la taille totale
    total_size = sum(
        os.path.getsize(os.path.join(root, f))
        for root, _, files in os.walk(pack_dir)
        for f in files if f != 'manifest.json'
    )

    # Calculer le checksum global (hash de tous les fichiers concaténés)
    hasher = hashlib.sha256()
    for root, _, files in sorted(os.walk(pack_dir)):
        for f in sorted(files):
            if f == 'manifest.json': continue
            with open(os.path.join(root, f), 'rb') as fh:
                hasher.update(fh.read())

    # Compter les objectifs
    lens_dir = os.path.join(pack_dir, 'lenses')
    lens_count = len(os.listdir(lens_dir)) if os.path.isdir(lens_dir) else 0

    manifest = {
        "body_id": body["id"],
        "pack_version": body.get("_pack_version", "1.0.0"),
        "firmware_version": body.get("current_firmware", "1.0"),
        "languages_included": body.get("supported_languages", ["en"]),
        "lens_count": lens_count,
        "total_size_bytes": total_size,
        "created_at": datetime.utcnow().isoformat() + "Z",
        "checksum_sha256": hasher.hexdigest(),
        "min_app_version": "1.0.0",
        "changelog": body.get("_changelog", [])
    }

    with open(f"{pack_dir}/manifest.json", 'w') as f:
        json.dump(manifest, f)
```

#### build_catalog.py

```python
# tools/build_catalog.py
"""
Génère le catalog.json global à partir de tous les manifests.
C'est le fichier téléchargé par l'app pendant l'onboarding
pour afficher la liste des boîtiers disponibles.
"""

def build_catalog(data_dir, output_path):
    bodies = []
    for pack_dir in sorted(glob(f"{data_dir}/*/manifest.json")):
        manifest = json.load(open(pack_dir))
        body = json.load(open(os.path.join(os.path.dirname(pack_dir), "body.json")))

        bodies.append({
            "id": manifest["body_id"],
            "brand_id": body["brand_id"],
            "display_name": body["display_name"],
            "sensor_size": body["sensor_size"],
            "pack_version": manifest["pack_version"],
            "pack_size_bytes": manifest["total_size_bytes"],
            "lens_count": manifest["lens_count"],
            "supported_languages": manifest["languages_included"],
        })

    catalog = {
        "version": date.today().isoformat(),
        "bodies": bodies,
    }

    with open(output_path, 'w') as f:
        json.dump(catalog, f)
```

---

## 5. Endpoints (URLs publiques)

### 5.1. Base URL

```
MVP :  https://shoothelper.github.io/data/
V2  :  https://data.shoothelper.app/       (custom domain Cloudflare R2)
```

### 5.2. Catalogue & Healthcheck

| Endpoint | Méthode | Taille | Cache | Description |
|----------|---------|--------|-------|-------------|
| `/catalog.json` | GET | ~5 KB | 1h | Liste de tous les boîtiers supportés avec métadonnées |
| `/health.json` | GET | ~10 B | Pas de cache | Healthcheck pour le ping de connectivité |

**`catalog.json`** est le seul fichier que l'app doit télécharger *avant* que l'utilisateur ait choisi son boîtier. C'est ce qui peuple l'écran de sélection de boîtier dans l'onboarding.

**`health.json`** est le fichier utilisé par `ConnectivityService.hasInternetAccess()` (skill 13). Un GET qui retourne `{"status":"ok"}`. Si ça répond → on a internet. Sinon → offline.

### 5.3. Données partagées

| Endpoint | Taille | Cache | Description |
|----------|--------|-------|-------------|
| `/shared/setting_defs.json` | ~3 KB | 24h | Définitions des 15 réglages MVP |
| `/shared/brands.json` | ~1 KB | 24h | Sony, Canon, Nikon, Fujifilm |
| `/shared/mounts.json` | ~1 KB | 24h | Sony E, Canon RF, Nikon Z, Fuji X |

### 5.4. Data Packs

| Endpoint | Taille | Cache | Description |
|----------|--------|-------|-------------|
| `/{body_id}/manifest.json` | ~1 KB | 1h | Métadonnées + checksum du pack |
| `/{body_id}/body.json` | ~15 KB | 24h | Specs boîtier + contrôles physiques |
| `/{body_id}/menu_tree.json` | ~150 KB | 24h | Arbre de menus complet (toutes langues) |
| `/{body_id}/nav_paths.json` | ~30 KB | 24h | Chemins de navigation pour les 15 réglages |
| `/{body_id}/lenses/{lens_id}.json` | ~5 KB | 24h | Specs d'un objectif |

**Convention body_id** : slug lowercase sans tiret. Exemples : `sony_a6700`, `canon_r50`, `nikon_z50ii`, `fuji_xt5`.

**Convention lens_id** : slug lowercase. Exemples : `sigma_18-50_f2.8_dc_dn_c`, `sony_e_16-50_f3.5-5.6_oss`, `canon_rf-s_18-45_f4.5-6.3_is_stm`.

### 5.5. Tableau récapitulatif des requêtes par flow

| Flow | Requêtes | Quand |
|------|----------|-------|
| Onboarding (sélection boîtier) | `GET /catalog.json` | Afficher la liste des boîtiers |
| Onboarding (après sélection) | `GET /shared/*.json` + `GET /{body_id}/*.json` + `GET /{body_id}/lenses/*.json` | Téléchargement initial |
| Flow principal (scène → résultats) | **Aucune** | 100% offline |
| Check MAJ | `GET /{body_id}/manifest.json` | Au lancement (si online) |
| Appliquer MAJ | `GET /{body_id}/*.json` (les fichiers modifiés) | Action explicite |
| Ajouter un objectif | `GET /{body_id}/lenses/{lens_id}.json` | Action explicite |
| Healthcheck | `HEAD /health.json` | Détection connectivité |

---

## 6. Headers HTTP & Cache

### 6.1. Stratégie de cache

L'app utilise **ETag + If-None-Match** pour le cache HTTP. Le CDN gère les ETags automatiquement (basé sur le hash du fichier).

```
Premier téléchargement :
  GET /{body_id}/manifest.json
  → 200 OK
  → ETag: "abc123"
  → Body: { ... }

Check MAJ (même URL) :
  GET /{body_id}/manifest.json
  If-None-Match: "abc123"
  → 304 Not Modified (pas de body, pas de bandwidth)
  → L'app sait qu'il n'y a pas de MAJ

Après un deploy :
  GET /{body_id}/manifest.json
  If-None-Match: "abc123"
  → 200 OK
  → ETag: "def456"
  → Body: { nouveau manifest }
  → L'app détecte la MAJ
```

### 6.2. Cache-Control headers

Configurés côté CDN :

| Fichier | Cache-Control | Raison |
|---------|--------------|--------|
| `health.json` | `no-cache` | Doit toujours être frais pour le ping |
| `catalog.json` | `public, max-age=3600` | Peut être caché 1h — la liste des boîtiers change rarement |
| `manifest.json` | `public, max-age=3600` | Caché 1h — c'est le fichier de check MAJ |
| `body.json`, `menu_tree.json`, etc. | `public, max-age=86400` | Caché 24h — ne change qu'avec un deploy |
| `lenses/*.json` | `public, max-age=86400` | Caché 24h |
| `shared/*.json` | `public, max-age=86400` | Caché 24h |

### 6.3. CORS

Les fichiers sont publics. CORS n'est pas un problème pour une app mobile (pas de navigateur), mais on le configure quand même pour le debug web :

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, HEAD
```

---

## 7. Versioning

### 7.1. Les 3 niveaux de version (rappel skill 12)

```
APP VERSION       : 1.0.0, 2.0.0 — version de l'app dans les stores
PACK VERSION      : 1.0.0, 1.1.0 — version du contenu d'un data pack
API VERSION       : v1             — version de la structure des URLs et du format JSON
```

### 7.2. API Version

Au MVP, pas de version dans l'URL. Si un jour on fait un breaking change dans le format des JSON (renommer un champ, restructurer une entité), on introduit un préfixe de version.

```
MVP :
  https://data.shoothelper.app/sony_a6700/body.json

Si breaking change :
  https://data.shoothelper.app/v2/sony_a6700/body.json
  L'app v2.0+ pointe vers /v2/
  L'app v1.x continue de pointer vers / (les anciens fichiers restent)
```

**Quand considérer un breaking change :**
- Renommage d'un champ JSON (ex: `iso_range` → `iso_limits`)
- Changement de structure (ex: `controls` passe d'un objet à un tableau)
- Ajout d'un champ requis par l'app (que les anciens data packs n'ont pas)

**Comment éviter les breaking changes :**
- Toujours ajouter des champs optionnels (l'app gère le `null`)
- Ne jamais renommer — ajouter le nouveau champ et déprécier l'ancien
- Versionner dans le manifest : `"min_app_version": "2.0.0"` pour signaler à l'ancienne app qu'elle doit se mettre à jour

### 7.3. Pack Version (semver)

```
MAJOR.MINOR.PATCH

MAJOR : Breaking change dans la structure (rare, couplé à un API version bump)
MINOR : Nouveau contenu (nouveau firmware, nouveaux objectifs, nouvelles langues)
PATCH : Correction (typo dans un label, chemin de menu corrigé)

Exemples :
  1.0.0 → Version initiale du Sony A6700
  1.0.1 → Correction typo "Mode mise au point" FR
  1.1.0 → Ajout firmware 3.0, 3 nouveaux objectifs
  2.0.0 → Restructuration du menu_tree (breaking, nécessite app v2.0+)
```

### 7.4. min_app_version dans le manifest

```json
{
  "body_id": "sony_a6700",
  "pack_version": "2.0.0",
  "min_app_version": "2.0.0",
  ...
}
```

L'app compare `min_app_version` avec sa propre version. Si le data pack exige une version plus récente que l'app installée, l'app affiche un message :

```
"Une mise à jour de l'app est nécessaire pour utiliser les dernières données.
 Mets à jour ShootHelper depuis le store."
```

L'app continue de fonctionner avec l'ancien data pack en attendant.

---

## 8. Sécurité

### 8.1. Intégrité des données

Les data packs sont validés par **checksum SHA-256** (skill 13 §4). Le checksum est dans le manifest, qui est le premier fichier téléchargé. Après download de tous les fichiers, l'app recalcule le checksum et compare.

```
Attaque possible : un CDN compromis sert un body.json modifié
Mitigation : le checksum dans le manifest détecte la modification

Attaque possible : le manifest lui-même est compromis
Mitigation MVP : aucune (on fait confiance au CDN)
Mitigation V2 : signer le manifest avec une clé privée, vérifier côté app
```

### 8.2. HTTPS obligatoire

Toutes les URLs utilisent HTTPS. L'app refuse les connexions HTTP. Configurer dans Dio :

```dart
final dio = Dio(BaseOptions(
  baseUrl: AppConstants.cdnBaseUrl, // https://...
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
));
```

### 8.3. Pas de données sensibles

Le CDN ne sert que des données publiques (specs caméra, menus). Aucune donnée utilisateur ne transite par le réseau. Pas de token, pas d'authentification, pas de cookies. Le RGPD côté serveur est trivial : il n'y a pas de données personnelles.

### 8.4. Rate limiting

Au MVP avec GitHub Pages, le rate limiting est géré par GitHub (60K requêtes/heure pour le site). Largement suffisant.

Avec Cloudflare R2 : configurer un rate limit par IP si nécessaire (ex: 100 requêtes/minute). Ça protège contre un bot qui scraperaient tous les data packs en boucle.

---

## 9. Options d'hébergement détaillées

### 9.1. Option A — GitHub Pages (MVP)

```
Setup :
  1. Créer le repo shoothelper-data
  2. Activer GitHub Pages sur la branche gh-pages
  3. Le workflow deploy.yml publie dist/ vers gh-pages
  4. URL : https://shoothelper.github.io/data/

Coût : GRATUIT

Limites :
  • 1 GB de stockage (on utilise ~5 MB)
  • 100 GB/mois de bandwidth (à ~250 KB par download, ça fait ~400K downloads/mois)
  • Pas de custom headers (Cache-Control géré par GitHub)
  • Pas de custom domain sans config DNS

Quand migrer : > 10K utilisateurs actifs OU besoin de custom domain
```

### 9.2. Option B — Cloudflare R2 + Pages

```
Setup :
  1. Créer un bucket R2
  2. Configurer un worker Cloudflare pour servir les fichiers
  3. Ou utiliser Cloudflare Pages (déploie depuis GitHub)
  4. Custom domain : data.shoothelper.app

Coût : QUASI-GRATUIT
  • R2 : 10 GB de stockage gratuit, pas de frais d'egress
  • Workers : 100K requêtes/jour gratuit
  • Pages : gratuit

Avantages vs GitHub Pages :
  • Custom domain natif
  • Custom Cache-Control headers
  • Analytics intégrés (nombre de downloads)
  • CDN global Cloudflare (150+ PoP)

Quand migrer : quand tu veux un custom domain ou des analytics
```

### 9.3. Option C — Firebase Hosting

```
Setup :
  1. firebase init hosting
  2. Copier dist/ vers public/
  3. firebase deploy

Coût : GRATUIT (tier Spark)
  • 10 GB de stockage
  • 10 GB/mois de transfert (~40K downloads)
  • Custom domain

Avantages :
  • Intégration Firebase (si on ajoute Analytics, Crashlytics plus tard)
  • CLI simple

Inconvénients :
  • 10 GB/mois de transfert = limitant si l'app grandit
  • Pas de frais d'egress gratuits comme R2
```

### 9.4. Recommandation

```
Phase 1 (MVP, 0 utilisateur)     → GitHub Pages
Phase 2 (lancement, 1-10K users) → Cloudflare R2 + Pages
Phase 3 (scale, 10K+ users)      → Cloudflare R2 (déjà en place)
```

La migration de GitHub Pages vers Cloudflare R2 est triviale : changer `cdnBaseUrl` dans l'app et publier une mise à jour. Les fichiers sont les mêmes, seule l'URL change.

---

## 10. Monitoring (MVP minimal)

### 10.1. Ce qu'on veut savoir

| Métrique | Pourquoi | Comment |
|----------|----------|---------|
| Nombre de downloads de catalog.json | Combien de nouveaux utilisateurs | Analytics CDN ou compteur GitHub Pages |
| Quels body_ids sont téléchargés | Quels boîtiers sont populaires | Log CDN |
| Erreurs 404 | Un fichier manquant ou une URL mal formée | Log CDN |
| Requêtes sur health.json | Combien d'utilisateurs actifs (approximation) | Log CDN |

### 10.2. MVP : GitHub Pages insights

GitHub Pages fournit des stats basiques de traffic dans les Settings du repo. Pas de granularité par fichier, mais suffisant pour démarrer.

### 10.3. V2 : Cloudflare Analytics

Cloudflare R2/Pages fournit des analytics par URL, par pays, par jour. Gratuit et intégré. Suffisant pour savoir quels boîtiers sont populaires et prioriser les prochains data packs.

### 10.4. Feedback utilisateur (boîtier non supporté)

L'écran "Mon boîtier n'est pas listé" (skill 02, F1) permet à l'utilisateur de saisir sa marque/modèle. Ce feedback est stocké **localement** dans l'app (pas envoyé au serveur au MVP). En V2, on peut ajouter un endpoint simple pour collecter ces demandes.

---

## 11. Processus de publication d'un data pack

### 11.1. Nouveau boîtier

```
1. Scraping + data entry (skill 05)
   → Produit les fichiers JSON dans sources/{body_id}/

2. Pull Request sur shoothelper-data
   → CI valide automatiquement (validate.yml)
   → Review des chemins de menu (spot check)

3. Merge sur main
   → CD build + deploy automatique (deploy.yml)
   → catalog.json mis à jour avec le nouveau boîtier
   → Le nouveau boîtier apparaît dans l'app au prochain chargement du catalog

TEMPS : ~5 minutes du merge au déploiement
```

### 11.2. Correction d'un data pack

```
1. Identifier l'erreur (ex: chemin menu AF incorrect en FR)
2. Corriger dans sources/{body_id}/nav_paths.json
3. Incrémenter _pack_version dans body.json (ex: 1.0.0 → 1.0.1)
4. Pull Request → CI → Merge → CD
5. Le manifest.json est régénéré avec la nouvelle version
6. Les utilisateurs de ce boîtier voient un badge "MAJ disponible"

TEMPS : ~5 minutes du fix au déploiement
```

### 11.3. Ajout d'un objectif

```
1. Créer sources/{body_id}/lenses/{lens_id}.json
2. Incrémenter _pack_version (ex: 1.0.1 → 1.1.0)
3. Pull Request → CI → Merge → CD
4. Le catalog.json reflète le nouveau lens_count
5. L'objectif est disponible immédiatement pour les utilisateurs du boîtier

TEMPS : ~5 minutes
```

---

## 12. Client HTTP côté app

### 12.1. DataPackApi

```dart
// shared/data/data_sources/remote/data_pack_api.dart

class DataPackApi {
  final Dio _dio;

  DataPackApi({required Dio dio}) : _dio = dio;

  /// Télécharge le catalogue global
  Future<CatalogModel> fetchCatalog() async {
    final response = await RetryPolicy.execute(
      () => _dio.get<Map<String, dynamic>>('/catalog.json'),
    );
    return CatalogModel.fromJson(response.data!);
  }

  /// Télécharge le manifest d'un data pack
  Future<ManifestModel> fetchManifest(String bodyId) async {
    final response = await RetryPolicy.execute(
      () => _dio.get<Map<String, dynamic>>('/$bodyId/manifest.json'),
    );
    return ManifestModel.fromJson(response.data!);
  }

  /// Télécharge un fichier JSON brut
  Future<Map<String, dynamic>> fetchJson(String path) async {
    final response = await RetryPolicy.execute(
      () => _dio.get<Map<String, dynamic>>(path),
    );
    return response.data!;
  }

  /// Télécharge un fichier comme bytes (pour le checksum)
  Future<List<int>> fetchBytes(String path) async {
    final response = await RetryPolicy.execute(
      () => _dio.get<List<int>>(path,
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    return response.data!;
  }

  /// Healthcheck (HEAD request, pas de body)
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.head('/health.json',
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

### 12.2. Configuration Dio

```dart
// shared/data/data_sources/remote/dio_config.dart

Dio createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.cdnBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
    },
  ));

  // Interceptor : log en debug
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
    ));
  }

  return dio;
}
```

---

## 13. Résumé

```
╔══════════════════════════════════════════════════════════════════╗
║                     LE "BACKEND" DE SHOOTHELPER                  ║
║                                                                  ║
║  C'est :                                                         ║
║    ✅ Un repo GitHub avec des fichiers JSON                       ║
║    ✅ Un pipeline CI/CD qui valide et déploie                     ║
║    ✅ Un CDN statique qui sert des fichiers via HTTPS             ║
║                                                                  ║
║  Ce n'est PAS :                                                  ║
║    ❌ Un serveur qui tourne                                       ║
║    ❌ Une API REST avec des endpoints dynamiques                  ║
║    ❌ Une base de données côté serveur                            ║
║    ❌ Un système d'authentification                               ║
║                                                                  ║
║  Coût total :                                                    ║
║    MVP → 0€/mois (GitHub Pages)                                  ║
║    Scale → ~0€/mois (Cloudflare R2, pas de frais d'egress)       ║
║                                                                  ║
║  Temps de deploy :                                               ║
║    ~5 minutes du git push au fichier disponible sur le CDN       ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

*Ce document est la référence pour le setup du repo de données, la configuration du CDN, et l'implémentation du client HTTP dans l'app. Combiné avec le skill 13 (Offline-First), il couvre tout le cycle réseau de bout en bout.*
