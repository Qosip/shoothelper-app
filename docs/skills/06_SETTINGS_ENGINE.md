# Settings Engine — ShootHelper

> **Skill 06/22** · Algorithmes de calcul des réglages optimaux
> Version 1.0 · Mars 2026
> Réf : 01_PRD.md, 04_CAMERA_DATA_ARCHITECTURE.md

---

## 1. Vue d'ensemble

Le Settings Engine est le **cerveau** de l'app. Il prend en entrée les données du gear (BodySpec + LensSpec) et la description de scène (Scene Input), et produit en sortie une liste de réglages optimaux avec explications.

**Principes fondamentaux :**

- **Déterministe** : pas de random, pas d'IA. Le même input produit toujours le même output.
- **Auditable** : chaque réglage est accompagné d'une trace du raisonnement. On peut expliquer *pourquoi*.
- **Borné par le matériel** : le moteur ne recommandera jamais un réglage que le boîtier ou l'objectif ne supporte pas.
- **Compromis explicites** : quand le moteur ne peut pas satisfaire toutes les contraintes, il le dit et propose des alternatives.
- **Offline** : calcul 100% local, pas de dépendance réseau. Cible < 500ms.

---

## 2. Architecture du moteur

### 2.1. Pipeline de calcul

```
┌─────────────────────────────────────────────────────────────────┐
│                       SETTINGS ENGINE                           │
│                                                                 │
│  INPUTS                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │BodySpec  │  │LensSpec  │  │SceneInput│                     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                     │
│       │              │              │                           │
│       ▼              ▼              ▼                           │
│  ┌──────────────────────────────────────────────┐              │
│  │  PHASE 1 : Contexte & Contraintes            │              │
│  │  → Déterminer les limites matérielles         │              │
│  │  → Résoudre la focale effective               │              │
│  │  → Calculer l'EV cible                        │              │
│  └────────────────────┬─────────────────────────┘              │
│                       ▼                                         │
│  ┌──────────────────────────────────────────────┐              │
│  │  PHASE 2 : Réglages indépendants              │              │
│  │  → Mode AF, Zone AF, Mesure, WB, Format,     │              │
│  │    Stabilisation, Drive                       │              │
│  └────────────────────┬─────────────────────────┘              │
│                       ▼                                         │
│  ┌──────────────────────────────────────────────┐              │
│  │  PHASE 3 : Triangle d'exposition              │              │
│  │  → Prioriser selon l'intention                │              │
│  │  → Calculer ouverture, vitesse, ISO           │              │
│  │  → Résoudre les conflits                      │              │
│  └────────────────────┬─────────────────────────┘              │
│                       ▼                                         │
│  ┌──────────────────────────────────────────────┐              │
│  │  PHASE 4 : Compromis & Alternatives           │              │
│  │  → Détecter les impossibilités                │              │
│  │  → Proposer des compromis                     │              │
│  │  → Générer les explications                   │              │
│  └────────────────────┬─────────────────────────┘              │
│                       ▼                                         │
│  OUTPUT                                                         │
│  ┌──────────────────────────────────────────────┐              │
│  │  SettingsResult                               │              │
│  │  → Liste de (setting_id, value, explanation)  │              │
│  │  → Liste de compromis                         │              │
│  │  → Score de confiance                         │              │
│  └──────────────────────────────────────────────┘              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2. Structures de données du moteur

#### SceneInput (entrée)

```typescript
interface SceneInput {
  // Niveau 1 (obligatoire)
  shoot_type: "photo" | "video";
  environment: "outdoor_day" | "outdoor_night" | "indoor_bright" | "indoor_dark" | "studio";
  subject: "landscape" | "portrait" | "street" | "architecture" | "macro" | "astro" | "sport" | "wildlife" | "product";
  intention: "max_sharpness" | "bokeh" | "freeze_motion" | "motion_blur" | "low_light";

  // Niveau 2 (optionnel)
  light_condition?: "direct_sun" | "shade" | "overcast" | "golden_hour" | "blue_hour" | "starry_night" | "neon" | "tungsten" | "led";
  subject_motion?: "still" | "slow" | "fast" | "very_fast";
  subject_distance?: "very_close" | "close" | "medium" | "far" | "infinity";
  mood?: "dramatic" | "soft" | "high_contrast" | "natural" | "silhouette";
  support?: "handheld" | "tripod" | "monopod" | "gimbal";
  constraint_iso_max?: number;      // ex: 3200
  constraint_shutter_min?: string;  // ex: "1/500"

  // Niveau 3 (optionnel, override)
  wb_override?: "auto" | "daylight" | "shade" | "cloudy" | "tungsten" | "fluorescent" | "flash" | number;
  dof_preference?: "shallow" | "medium" | "deep";
  af_area_override?: "center" | "wide" | "tracking" | "eye_af";
  bracketing?: "none" | "exposure" | "focus";
  file_format_override?: "raw" | "jpeg" | "raw+jpeg";
}
```

#### SettingsResult (sortie)

```typescript
interface SettingsResult {
  settings: SettingRecommendation[];
  compromises: Compromise[];
  scene_summary: string;        // Résumé en une ligne de la scène interprétée
  confidence: "high" | "medium" | "low";
}

interface SettingRecommendation {
  setting_id: string;           // Réf vers SettingDef (skill 04)
  value: string | number;       // La valeur recommandée
  value_display: string;        // Affichage formaté (ex: "f/2.8", "1/250s")
  explanation_short: string;    // 1 phrase
  explanation_detail: string;   // Paragraphe complet
  is_override: boolean;         // true si l'utilisateur a forcé cette valeur (Niveau 3)
  is_compromised: boolean;      // true si ce réglage fait partie d'un compromis
  alternatives: Alternative[];  // Autres valeurs possibles avec trade-offs
}

interface Alternative {
  value: string | number;
  value_display: string;
  trade_off: string;            // Ce qu'on gagne et ce qu'on perd
  cascade_changes: CascadeChange[];  // Quels autres réglages changent si on prend cette alternative
}

interface CascadeChange {
  setting_id: string;
  from_value: string;
  to_value: string;
  reason: string;
}

interface Compromise {
  type: "noise" | "motion_blur" | "depth_of_field" | "exposure" | "gear_limit" | "impossible";
  severity: "info" | "warning" | "critical";
  message: string;
  affected_settings: string[];  // setting_ids impliqués
  suggestion: string;           // Conseil pour améliorer (ex: "utilise un trépied")
}
```

---

## 3. Phase 1 : Contexte & Contraintes

### 3.1. Résolution de la focale effective

La focale affecte plusieurs calculs (règle 1/focale, profondeur de champ). On doit d'abord la résoudre.

```
SI lens.type == "prime" :
  focal_mm = lens.focal_length.min_mm
SINON (zoom) :
  focal_mm = choisir_focale_optimale(subject, subject_distance, lens)

focale_equivalente = focal_mm × body.crop_factor
```

**Choisir la focale optimale pour un zoom :**

| Sujet | Focale préférée | Logique |
|-------|----------------|---------|
| Paysage | `lens.focal_length.min_mm` (grand angle) | Cadrage large |
| Portrait | `min(lens.focal_length.max_mm, 85/crop_factor)` | Compression flatteuse, ~85mm eq. idéal |
| Street | `35/crop_factor` ou milieu de plage | Polyvalent, ~35mm eq. classique |
| Architecture | `lens.focal_length.min_mm` | Grand angle pour les bâtiments |
| Macro | `lens.focal_length.max_mm` | Distance de travail maximale |
| Astro | `lens.focal_length.min_mm` | Champ large pour les étoiles |
| Sport/Action | `lens.focal_length.max_mm` | Rapprocher le sujet |
| Animalier | `lens.focal_length.max_mm` | Rapprocher le sujet |
| Produit | Milieu de plage | Distorsion minimale |

Note : la focale choisie est une **suggestion**, pas un calcul absolu. L'utilisateur compose son cadrage comme il veut — mais on en a besoin pour les calculs d'exposition et de PDC.

### 3.2. Résolution de l'ouverture maximale

Pour un zoom à ouverture variable, l'ouverture max dépend de la focale :

```
SI lens.aperture.type == "constant" :
  max_aperture = lens.aperture.max_aperture
SINON :
  max_aperture = interpoler(lens.aperture.variable_aperture_map, focal_mm)

Interpolation linéaire entre les deux points les plus proches de la map.
```

### 3.3. Calcul de l'EV cible (Exposure Value)

L'EV cible est déterminé par les conditions de lumière. C'est le point de départ du calcul du triangle d'exposition.

**Table de référence EV (ISO 100) :**

| Condition | EV | Source |
|-----------|-----|--------|
| Soleil direct, pleine lumière | 15 | Sunny 16 rule |
| Soleil direct, ombre légère | 14 | |
| Couvert lumineux | 13 | |
| Couvert dense | 12 | |
| Ombre profonde | 11 | |
| Golden hour (début) | 12 | |
| Golden hour (fin, soleil bas) | 10 | |
| Blue hour (début) | 8 | |
| Blue hour (fin) | 5 | |
| Intérieur bien éclairé | 9-10 | |
| Intérieur sombre | 6-7 | |
| Nuit urbaine (éclairage rue) | 4-6 | |
| Nuit étoilée (pas de lune) | -4 à -2 | |
| Studio (éclairage standard) | 10-12 | |
| Néon/Fluorescent | 8-9 | |
| Tungstène (lampe intérieur) | 7-8 | |
| LED (variable) | 7-10 | |

**Résolution de l'EV :**

```
1. Si light_condition (Niveau 2) est renseigné :
   → Utiliser la table directement

2. Sinon, dériver de environment (Niveau 1) :
   outdoor_day     → EV 14 (moyenne soleil/couvert)
   outdoor_night   → EV 4  (moyenne nuit urbaine)
   indoor_bright   → EV 9
   indoor_dark     → EV 6
   studio          → EV 11

3. Ajustements par mood (Niveau 2) :
   silhouette      → EV -2 (sous-exposer volontairement)
   dramatic        → EV -0.5 (légèrement sombre)
   soft            → EV +0.3 (légèrement lumineux)
   high_contrast   → EV 0 (pas d'ajustement, géré par comp. expo)
```

### 3.4. Calcul de la vitesse minimum de sécurité

La vitesse min dépend du support et de la focale (pour éviter le flou de bougé).

```
SI support == "tripod" :
  shutter_min_safe = pas de limite (on accepte jusqu'à 30s, ou BULB pour astro)

SI support == "gimbal" :
  shutter_min_safe = 1/30s (le gimbal stabilise le bougé, pas le sujet)

SI support == "monopod" :
  shutter_min_safe = 1 / (focale_equivalente × 0.5)  
  // Le monopode offre ~1 stop de stabilité

SI support == "handheld" OU support non renseigné :
  base = 1 / focale_equivalente   // Règle classique 1/focale

  // Bonus stabilisation
  ibis_stops = body.spec.stabilization.has_ibis ? body.spec.stabilization.ibis_stops : 0
  ois_stops = lens.spec.stabilization.has_ois ? lens.spec.stabilization.ois_stops : 0
  total_stab = max(ibis_stops, ois_stops)  // Ils ne s'additionnent pas parfaitement
  // Estimation conservatrice : on prend le max, pas la somme

  shutter_min_safe = base / (2 ^ total_stab)
  
  // Clamp : jamais en dessous de 1/15s handheld même avec stabilisation
  shutter_min_safe = max(shutter_min_safe, 1/15)
```

**Exemple Sony A6700 + Sigma 18-50 f/2.8 à 50mm :**

```
focale_equivalente = 50 × 1.5 = 75mm
base = 1/75s
IBIS = 5 stops, OIS = 0
total_stab = 5
shutter_min_safe = (1/75) / 2^5 = (1/75) / 32 ≈ 1/2.3s

Clamp à 1/15s (on reste conservateur pour un débutant)
→ shutter_min_safe = 1/15s
```

Note : pour un débutant, la stabilisation ne compense pas autant que les specs l'annoncent. On est délibérément conservateur.

### 3.5. Vitesse minimum dictée par le sujet

Indépendamment du bougé, le sujet en mouvement impose une vitesse minimum :

| Mouvement sujet | Vitesse min |
|----------------|-------------|
| `still` | Pas de contrainte (limité par bougé seulement) |
| `slow` (personne qui marche) | 1/125s |
| `fast` (coureur, cycliste) | 1/500s |
| `very_fast` (oiseau en vol, voiture) | 1/1000s — 1/2000s |

**Cas spéciaux par sujet :**

| Sujet | Override vitesse min | Logique |
|-------|---------------------|---------|
| Astro | Règle NPF (voir §3.6) | Étoiles ponctuelles |
| Macro | 1/250s min (handheld) | Micro-mouvements amplifiés |
| Sport | 1/500s min par défaut | Même si subject_motion pas renseigné |

**La vitesse minimum effective** est le MAX entre la vitesse de sécurité (bougé) et la vitesse dictée par le sujet :

```
shutter_min_effective = max(shutter_min_safe, shutter_min_subject)
```

Si l'utilisateur a renseigné `constraint_shutter_min`, elle s'ajoute :

```
shutter_min_effective = max(shutter_min_effective, constraint_shutter_min)
```

### 3.6. Règle NPF pour l'astrophotographie

La "règle des 500" est obsolète. On utilise la **règle NPF** qui est plus précise :

```
t_max = (35 × N + 30 × p) / (focal_mm × cos(δ))

Où :
  t_max = temps d'exposition max en secondes (étoiles ponctuelles)
  N     = ouverture (f-number)
  p     = pixel pitch en µm (calculé depuis BodySpec)
  δ     = déclinaison du sujet (on simplifie à 0° = équateur céleste, cas le plus strict)

pixel_pitch = sqrt((sensor_width_mm × sensor_height_mm) / megapixels) × 1000

Simplification MVP : δ = 0 → cos(δ) = 1
```

**Exemple Sony A6700 à 18mm f/2.8 :**

```
Capteur APS-C : 23.5 × 15.6 mm, 26 MP
pixel_pitch = sqrt((23.5 × 15.6) / 26000000) × 1000 = sqrt(0.0000141) × 1000 ≈ 3.75 µm

t_max = (35 × 2.8 + 30 × 3.75) / 18 = (98 + 112.5) / 18 ≈ 11.7s

→ Vitesse max recommandée : ~12 secondes
```

---

## 4. Phase 2 : Réglages indépendants

Ces réglages ne font pas partie du triangle d'exposition et sont calculés via des arbres de décision simples. Chacun est un arbre séparé.

### 4.1. Mode AF

```
SI subject == "astro" ET intention == "max_sharpness" :
  → MF (mise au point manuelle sur l'infini)
  explication: "En astrophoto, l'autofocus ne peut pas accrocher les étoiles.
               Passe en MF et fais la mise au point sur une étoile brillante avec le zoom d'aide."

SI subject == "landscape" ET subject_distance == "infinity" :
  → MF ou AF-S
  explication: "Pour un paysage à l'infini, AF-S suffit. Tu peux aussi utiliser MF
               pour fixer la mise au point sur l'hyperfocale."

SI subject_motion == "still" OU subject_motion == null :
  → AF-S (Single-shot AF)
  explication: "Sujet immobile : AF-S verrouille la mise au point en une fois."

SI subject_motion IN ["slow", "fast", "very_fast"] :
  → AF-C (Continuous AF)
  explication: "Sujet en mouvement : AF-C ajuste la mise au point en continu
               pour suivre le sujet."

SI subject == "macro" :
  → AF-S ou MF
  explication: "En macro, la profondeur de champ est si fine que l'AF peut manquer le sujet.
               AF-S pour les sujets stables, MF pour le contrôle total."
```

**Fallback** : Si le mode recommandé n'est pas supporté par le boîtier (`BodySpec.autofocus.modes`), choisir le mode le plus proche disponible et avertir.

### 4.2. Zone AF

```
SI af_area_override (Niveau 3) est renseigné :
  → Utiliser l'override (si supporté par le boîtier)

SI subject == "portrait" ET body.autofocus.has_eye_af :
  → Eye-AF
  explication: "Eye-AF verrouille la mise au point sur l'œil du sujet —
               idéal pour les portraits où la netteté de l'œil est critique."

SI subject IN ["sport", "wildlife"] ET subject_motion IN ["fast", "very_fast"] :
  SI "tracking" IN body.autofocus.areas :
    → Tracking (suivi)
    explication: "Le suivi AF suit le sujet dans le cadre même s'il se déplace rapidement."
  SINON :
    → Zone large (wide)

SI subject == "landscape" OU subject == "architecture" :
  → Zone large (wide) ou Centre
  explication: "Pour les sujets statiques et les scènes larges,
               la zone large ou le point central suffisent."

SI subject == "macro" :
  → Spot ou Centre
  explication: "En macro, la zone de netteté est très fine.
               Un point AF précis te donne le contrôle exact."

SI subject == "street" :
  → Zone large (wide)
  explication: "En street, les sujets sont imprévisibles.
               Une zone large laisse l'AF réagir rapidement."

DÉFAUT :
  → Zone large (wide)
```

### 4.3. Mode de mesure

```
SI mood == "silhouette" :
  → Spot (mesurer le ciel/fond)
  explication: "Pour une silhouette, mesure sur le fond lumineux.
               Le sujet sera naturellement sous-exposé."

SI mood == "dramatic" OU mood == "high_contrast" :
  → Spot ou Centre pondéré
  explication: "Mesure ciblée pour contrôler précisément l'exposition
               sur la zone d'intérêt."

SI subject == "portrait" :
  → Centre pondéré
  explication: "La mesure centre pondéré expose correctement le visage
               sans être trop influencée par l'arrière-plan."

SI subject == "landscape" :
  → Matricielle/Multi
  explication: "La mesure matricielle évalue l'ensemble de la scène
               pour une exposition équilibrée du paysage."

SI environment == "studio" :
  → Spot
  explication: "En studio, la mesure spot permet de mesurer précisément
               la lumière sur le sujet."

DÉFAUT :
  → Matricielle/Multi
```

### 4.4. Balance des blancs

```
SI wb_override (Niveau 3) est renseigné :
  → Utiliser l'override

SI file_format == "raw" OU file_format == "raw+jpeg" :
  → Auto WB
  explication: "En RAW, la balance des blancs est modifiable en post-traitement
               sans perte de qualité. Auto WB est suffisant."
  // Note : on recommande quand même une valeur Kelvin indicative

SINON (JPEG) :
  Mapper light_condition → preset WB :
  
  | Condition | WB Preset | Kelvin approx |
  |-----------|-----------|---------------|
  | direct_sun | Daylight | 5200K |
  | shade | Shade | 7000K |
  | overcast | Cloudy | 6000K |
  | golden_hour | Daylight ou 5000K | 5000K |
  | blue_hour | Auto (laisser le bleu) | 3500-4500K |
  | starry_night | 3800K manuel | 3800K |
  | tungsten | Tungsten | 3200K |
  | neon/fluorescent | Fluorescent | 4000K |
  | led | Auto | Variable |
  | studio | Flash ou 5500K | 5500K |

  SI light_condition non renseigné → Auto WB
```

### 4.5. Format fichier

```
SI file_format_override (Niveau 3) est renseigné :
  → Utiliser l'override

DÉFAUT :
  → RAW
  explication: "RAW capture toute l'information du capteur. Tu pourras ajuster
               l'exposition, la balance des blancs et les couleurs en post-traitement
               sans perte de qualité. C'est le choix recommandé pour apprendre."
```

### 4.6. Stabilisation

```
SI body.spec.stabilization.has_ibis == false :
  → Pas de recommandation (pas de stabilisation dans le boîtier)
  // La stabilisation optique de l'objectif est toujours active automatiquement

SI support == "tripod" :
  → Stabilisation OFF
  explication: "Sur trépied, la stabilisation peut introduire des micro-vibrations
               parasites. Désactive-la pour des images plus nettes."

SINON :
  → Stabilisation ON
  explication: "Main levée / monopode : la stabilisation compense les micro-mouvements
               et te permet d'utiliser des vitesses plus lentes."
```

### 4.7. Mode d'entraînement (Drive)

```
SI subject_motion IN ["fast", "very_fast"] :
  → Rafale haute (continuous-hi)
  explication: "La rafale haute multiplie tes chances de capturer
               le bon moment avec un sujet rapide."

SI subject == "sport" OU subject == "wildlife" :
  → Rafale haute (continuous-hi)

SI bracketing != "none" :
  → Bracket (mode dédié)

SI subject == "portrait" :
  → Single
  explication: "En portrait, une seule image suffit.
               La rafale n'est pas nécessaire."

DÉFAUT :
  → Single
```

---

## 5. Phase 3 : Triangle d'exposition

C'est le cœur mathématique du moteur. Le triangle d'exposition lie ouverture (A), vitesse (S) et ISO par la relation :

```
EV = log2(A² / S) - log2(ISO / 100)

Ou sous forme d'addition en "stops" :
EV = EV_aperture + EV_shutter + EV_iso

EV_aperture = 2 × log2(f_number)
EV_shutter = -log2(shutter_seconds)
EV_iso = -log2(ISO / 100)
```

### 5.1. Stratégie de priorisation

Le moteur ne résout pas le triangle de la même façon selon l'intention. L'intention détermine quel paramètre est fixé en premier (le "pivot"), et quels paramètres s'ajustent.

```
┌──────────────────────────────────────────────────────────────┐
│  INTENTION          │  PIVOT (fixé d'abord)  │  ORDRE       │
├─────────────────────┼────────────────────────┼──────────────┤
│  bokeh              │  Ouverture (min f/)    │  A → S → ISO │
│  max_sharpness      │  Ouverture (sweet spot)│  A → S → ISO │
│  freeze_motion      │  Vitesse (rapide)      │  S → A → ISO │
│  motion_blur        │  Vitesse (lente)       │  S → A → ISO │
│  low_light          │  ISO (balance)         │  A → ISO → S │
└──────────────────────────────────────────────────────────────┘
```

### 5.2. Détail de chaque stratégie

#### 5.2.1. Intention : `bokeh` (Flou d'arrière-plan)

```
ÉTAPE 1 — Fixer l'ouverture au maximum du flou
  aperture = max_aperture (du lens, à la focale choisie)
  // Le flou max = ouverture la plus grande = f-number le plus bas

ÉTAPE 2 — Calculer la vitesse nécessaire
  EV_needed = EV_cible
  EV_from_aperture = 2 × log2(aperture)
  EV_from_shutter_needed = EV_needed - EV_from_aperture + log2(ISO_base / 100)
  shutter = 1 / (2 ^ EV_from_shutter_needed)

  SI shutter < shutter_min_effective :
    // Pas assez rapide pour le sujet/bougé → monter les ISO
    shutter = shutter_min_effective
    → Recalculer ISO

  SI shutter > body.shutter.mechanical.max (ex: > 30s) :
    // Trop de lumière (surexposition même à vitesse max)
    → Fermer l'ouverture progressivement
    → Compromis : moins de bokeh

ÉTAPE 3 — Calculer l'ISO
  ISO = 100 × 2 ^ (EV_from_aperture + EV_from_shutter - EV_cible)
  
  Clamp : ISO ∈ [body.iso_range.min, body.iso_range.max]
  
  SI ISO > body.iso_usable_max :
    → Avertissement bruit
  SI ISO > body.iso_range.max :
    → Impossible sans compromis
```

#### 5.2.2. Intention : `max_sharpness` (Netteté maximale)

```
ÉTAPE 1 — Fixer l'ouverture au sweet spot
  // Le sweet spot d'un objectif est généralement 2-3 stops fermé par rapport au max
  sweet_spot = max_aperture × 2.8  // ~2.5 stops
  sweet_spot = clamp(sweet_spot, max_aperture, 11)
  
  // Ne jamais dépasser f/11 sur APS-C (diffraction)
  // Ne jamais dépasser f/16 sur Full-Frame (diffraction)
  SI body.sensor_size == "aps-c" :
    aperture = min(sweet_spot, 11)
  SINON :
    aperture = min(sweet_spot, 16)
    
  // Pour paysage : on ferme davantage pour la PDC
  SI subject == "landscape" ET dof_preference != "shallow" :
    aperture = clamp(8, max_aperture, 11)  // f/8-f/11 compromis PDC/diffraction

ÉTAPE 2-3 — Identique à bokeh
```

#### 5.2.3. Intention : `freeze_motion` (Figer le mouvement)

```
ÉTAPE 1 — Fixer la vitesse minimum
  SI subject_motion est renseigné :
    shutter_target = shutter_min_subject (table §3.5)
  SINON :
    // Deviner à partir du sujet
    SI subject == "sport" : shutter_target = 1/500s
    SI subject == "wildlife" : shutter_target = 1/1000s
    SINON : shutter_target = 1/250s

  shutter = max(shutter_target, shutter_min_safe)

ÉTAPE 2 — Ouvrir l'ouverture au maximum
  aperture = max_aperture
  // Pour maximiser la lumière, on ouvre à fond

ÉTAPE 3 — Calculer l'ISO
  ISO = résoudre_triangle(aperture, shutter, EV_cible)
  
  SI ISO > iso_usable_max :
    → Compromis : l'utilisateur devra accepter du bruit OU baisser la vitesse
```

#### 5.2.4. Intention : `motion_blur` (Filé de mouvement)

```
ÉTAPE 1 — Fixer une vitesse lente
  SI subject_motion == "slow" : shutter_target = 1/15s
  SI subject_motion == "fast" : shutter_target = 1/30s
  SI subject_motion == "very_fast" : shutter_target = 1/60s
  SINON : shutter_target = 1/15s

  // Le filé nécessite un trépied ou une bonne stabilisation
  SI support != "tripod" ET support != "monopod" :
    → Compromis warning : "Le filé de mouvement est plus facile avec un trépied.
       Main levée, le risque de bougé global est élevé."

ÉTAPE 2 — Fermer l'ouverture pour éviter la surexposition
  // Avec une vitesse lente + bonne lumière, il y a souvent trop de lumière
  aperture = résoudre_triangle(shutter_target, ISO_100, EV_cible)
  
  SI aperture > lens.aperture.min_aperture :
    → Pas assez fermé même au minimum → Surexposition
    → Recommander un filtre ND
    → Compromis : "Tu as besoin d'un filtre ND pour cette vitesse en plein jour."

ÉTAPE 3 — ISO au minimum
  ISO = body.iso_range.min (typiquement 100)
```

#### 5.2.5. Intention : `low_light` (Performance basse lumière)

```
ÉTAPE 1 — Ouvrir l'ouverture au max
  aperture = max_aperture

ÉTAPE 2 — Vitesse la plus lente acceptable
  shutter = shutter_min_effective
  // On profite de la stabilisation au maximum

ÉTAPE 3 — ISO en résultante
  ISO = résoudre_triangle(aperture, shutter, EV_cible)
  
  SI ISO > iso_usable_max :
    → Compromis : "ISO élevé nécessaire. Bruit visible mais acceptable
       pour capturer la scène. Shooter en RAW pour réduire le bruit en post."
  
  SI ISO > iso_range.max :
    → Impossible : "Pas assez de lumière même avec les réglages les plus extrêmes.
       Solutions : trépied (vitesse plus lente), flash, ou objectif plus lumineux."
```

### 5.3. Fonction de résolution du triangle

```
/**
 * Résout le triangle d'exposition.
 * Fixe 2 des 3 paramètres et calcule le 3ème.
 * 
 * EV = log2(A² / S) - log2(ISO / 100)
 * → ISO = 100 × A² / (S × 2^EV)
 * → S = A² / (ISO/100 × 2^EV)
 * → A = sqrt(S × ISO/100 × 2^EV)
 */

function resolve_iso(aperture, shutter_seconds, ev_target) → number :
  return 100 × (aperture² / shutter_seconds) / (2 ^ ev_target)

function resolve_shutter(aperture, iso, ev_target) → number :
  return aperture² / (iso/100 × 2 ^ ev_target)

function resolve_aperture(shutter_seconds, iso, ev_target) → number :
  return sqrt(shutter_seconds × (iso/100) × 2 ^ ev_target)
```

### 5.4. Arrondi aux valeurs standard

Les appareils photo n'acceptent pas n'importe quelle valeur — ils fonctionnent par crans (1/3 stop ou 1/2 stop).

**Valeurs d'ouverture standard (crans 1/3 stop) :**
```
1.0, 1.1, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.5, 2.8, 3.2, 3.5, 4.0,
4.5, 5.0, 5.6, 6.3, 7.1, 8.0, 9.0, 10, 11, 13, 14, 16, 18, 20, 22
```

**Valeurs de vitesse standard (crans 1/3 stop) :**
```
1/8000, 1/6400, 1/5000, 1/4000, 1/3200, 1/2500, 1/2000, 1/1600,
1/1250, 1/1000, 1/800, 1/640, 1/500, 1/400, 1/320, 1/250, 1/200,
1/160, 1/125, 1/100, 1/80, 1/60, 1/50, 1/40, 1/30, 1/25, 1/20,
1/15, 1/13, 1/10, 1/8, 1/6, 1/5, 1/4, 0.3, 0.4, 0.5, 0.6, 0.8,
1, 1.3, 1.6, 2, 2.5, 3.2, 4, 5, 6, 8, 10, 13, 15, 20, 25, 30
```

**Valeurs ISO standard (crans 1/3 stop) :**
```
50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800,
1000, 1250, 1600, 2000, 2500, 3200, 4000, 5000, 6400, 8000,
10000, 12800, 16000, 20000, 25600, 32000, 51200, 102400
```

**Règle d'arrondi** : toujours arrondir vers la valeur standard **la plus proche qui maintient l'exposition correcte**. Si on arrondit l'ouverture vers le haut (moins de lumière), compenser en arrondissant l'ISO vers le haut ou la vitesse vers le bas.

---

## 6. Phase 4 : Compromis & Alternatives

### 6.1. Détection des compromis

Le moteur détecte automatiquement les situations où le réglage optimal n'est pas atteignable.

| Condition | Type | Sévérité |
|-----------|------|----------|
| ISO > `iso_usable_max` | `noise` | warning |
| ISO > `iso_range.max` | `noise` | critical |
| Vitesse < `shutter_min_effective` (forcé) | `motion_blur` | warning |
| Ouverture demandée < `max_aperture` | `gear_limit` | info |
| Ouverture > `min_aperture` (surexposition) | `exposure` | warning |
| Sujet astro + pas de trépied | `impossible` | critical |
| Filé + plein soleil + pas de filtre ND | `exposure` | warning |
| Contrainte utilisateur impossible | `impossible` | critical |

### 6.2. Résolution des compromis

Quand un compromis est détecté, le moteur applique un algorithme de **dégradation gracieuse** :

```
PRIORITÉ DE DÉGRADATION (du moins grave au plus grave) :

1. Monter l'ISO (jusqu'à iso_usable_max)
   → Impact : plus de bruit
   → Réversible en post : partiellement (débruitage)

2. Monter l'ISO au-delà de iso_usable_max (jusqu'à iso_range.max)
   → Impact : bruit significatif
   → Warning à l'utilisateur

3. Baisser la vitesse d'obturation (risque de flou)
   → Impact : flou de mouvement possible
   → Acceptable si sujet immobile

4. Ouvrir l'ouverture au max (si pas déjà fait)
   → Impact : moins de PDC
   → Souvent acceptable

5. Signaler l'impossibilité
   → "Cette scène nécessite plus de lumière que ton matériel peut capturer.
      Suggestions : trépied, flash, objectif plus lumineux."
```

### 6.3. Génération des alternatives

Pour chaque réglage clé du triangle d'exposition, le moteur génère **1-2 alternatives** avec leurs conséquences en cascade.

```
Exemple pour ISO 3200 (recommandé) :

Alternative 1 : ISO 1600
  → Vitesse passe de 1/500s à 1/250s
  → Trade-off : "Moins de bruit, mais risque de flou si le sujet bouge vite"
  → cascade_changes: [{ shutter_speed: "1/500s" → "1/250s" }]

Alternative 2 : ISO 6400
  → Vitesse passe de 1/500s à 1/1000s
  → Trade-off : "Plus de bruit, mais sujet figé plus net"
  → cascade_changes: [{ shutter_speed: "1/500s" → "1/1000s" }]
```

La génération est mécanique : on décale d'1 stop dans chaque direction et on recalcule le triangle.

---

## 7. Compensation d'exposition

La comp. expo est recommandée dans des cas spécifiques où le posemètre de l'appareil sera systématiquement trompé :

| Situation | Comp. expo | Raison |
|-----------|-----------|--------|
| Scène très lumineuse (neige, plage) | +1 à +2 EV | Le posemètre sous-expose les scènes claires |
| Scène très sombre (sujet sur fond noir) | -1 à -2 EV | Le posemètre surexpose les scènes sombres |
| Contre-jour | +1 à +2 EV | Le fond lumineux fait sous-exposer le sujet |
| Mood "silhouette" | -2 à -3 EV | Sous-exposition volontaire du sujet |
| Mood "dramatic" | -0.3 à -0.7 EV | Légèrement sombre pour l'ambiance |
| Mood "soft" | +0.3 à +0.7 EV | Légèrement lumineux et aérien |
| Sujet blanc (robe de mariée) | +1 EV | Empêcher le gris |
| Sujet noir (costume, chat noir) | -1 EV | Empêcher le gris |

**Règle** : la comp. expo est **recommandée uniquement en mode M comme aide à l'exposition**, ou **appliquée en mode A/S/P**. En mode M pur, la comp. expo n'a pas d'effet direct — mais on indique quand même la correction à appliquer mentalement.

---

## 8. Cas spéciaux

### 8.1. Astrophotographie

L'astro a son propre flow presque entièrement dédié :

```
SI subject == "astro" :

  Mode expo : M (obligatoire — le posemètre ne fonctionne pas dans le noir)
  
  Ouverture : max_aperture (grand ouvert pour capter max de lumière)
  
  Vitesse : règle NPF (§3.6)
    → Typiquement 10-25s selon focale/capteur
    → Si lens.focal_length.min_mm > 24 : warning "Focale trop longue pour la voie lactée.
       Un grand angle (< 24mm eq.) est recommandé."
  
  ISO : calcul spécifique
    → APS-C : 3200-6400 (le bruit est acceptable, on l'enlève en stacking)
    → Full-Frame : 1600-3200
    → ISO target = iso_usable_max (on pousse volontairement)
  
  Mode AF : MF
  Zone AF : N/A
  Mesure : N/A (pas pertinent dans le noir)
  WB : 3800K (nuit étoilée naturelle) ou Auto si RAW
  Stabilisation : OFF (trépied obligatoire)
  Drive : Single ou timer 2s (éviter vibration du déclenchement)
  Format : RAW (obligatoire pour le stacking et le traitement astro)

  SI support != "tripod" :
    → Compromis CRITICAL : "L'astrophoto nécessite un trépied.
       Main levée, les temps de pose de 10+ secondes sont impossibles."
```

### 8.2. Vidéo

```
SI shoot_type == "video" :

  Vitesse : règle du double (shutter angle 180°)
    → shutter = 1 / (2 × framerate)
    → À 24fps : 1/50s
    → À 30fps : 1/60s
    → À 60fps : 1/125s
    // Exception : cette règle ne s'applique pas si intention == "freeze_motion"
    // Dans ce cas, vitesse plus rapide pour des images nettes frame par frame

  ISO : identique au mode photo, mais le bruit est plus visible en vidéo
    → iso_usable_max_video = iso_usable_max × 0.7 (seuil plus bas)

  Ouverture : selon l'intention, identique au mode photo

  Stabilisation : ON (presque toujours en vidéo)
  
  Mode AF : AF-C (toujours, pour la vidéo)
  
  Note : "Si tu filmes en plein soleil avec la règle du double (1/50s),
         tu auras peut-être besoin d'un filtre ND pour éviter la surexposition
         sans fermer trop le diaphragme."
```

### 8.3. Macro

```
SI subject == "macro" :

  Ouverture : f/8-f/11 (compromis netteté/PDC en macro)
    → En macro, même f/8 donne une PDC de quelques mm
    → f/2.8 en macro = PDC quasi inutilisable (< 1mm)
  
  Distance MAP : vérifier lens.focus.min_focus_distance_m
    SI subject_distance == "very_close" :
      SI distance demandée < min_focus_distance :
        → Compromis : "Ton objectif ne peut pas faire la MAP aussi près.
           Distance minimum : {min_focus_distance_m}m à {focal}mm."
  
  Vitesse : 1/250s minimum handheld (micro-mouvements amplifiés)
  
  Flash : "Un flash macro ou un ring flash est recommandé pour compenser
           l'ouverture fermée et la vitesse élevée."
```

---

## 9. Système d'explications

### 9.1. Templates d'explication

Chaque réglage a un template d'explication paramétré. Le moteur remplit les variables.

**Exemple : Ouverture**

```
Template court :
"Ouverture {value_display} {reason_fragment} avec ton {lens_display_name}."

Templates de reason_fragment par intention :
  bokeh     → "grande ouverte pour maximiser le flou d'arrière-plan"
  sharpness → "au sweet spot de netteté"
  low_light → "grande ouverte pour capter le maximum de lumière"
  freeze    → "grande ouverte pour compenser la vitesse élevée"
  blur      → "fermée pour réduire la lumière et permettre une pose longue"

Résultat : "Ouverture f/2.8 grande ouverte pour maximiser le flou d'arrière-plan
avec ton Sigma 18-50mm f/2.8."
```

**Exemple : ISO**

```
Template court :
"ISO {value} — {noise_assessment}."

noise_assessment :
  SI value <= 400 : "bruit quasi inexistant"
  SI value <= body.iso_usable_max / 2 : "bruit très faible"
  SI value <= body.iso_usable_max : "bruit visible mais acceptable"
  SI value <= body.iso_usable_max × 2 : "bruit notable, shooter en RAW recommandé"
  SINON : "bruit élevé — accepter le compromis ou modifier les conditions"
```

### 9.2. Explication détaillée

L'explication détaillée suit un format structuré :

```
1. POURQUOI cette valeur
   → "f/2.8 parce que c'est l'ouverture max de ton objectif,
      et l'intention est de maximiser le flou d'arrière-plan."

2. CE QUE ÇA IMPLIQUE
   → "À f/2.8 et 50mm sur APS-C, la profondeur de champ est d'environ 30cm
      à 3m de distance. Tout ce qui est hors de cette zone sera flou."

3. ALTERNATIVES (si pertinent)
   → "Si tu passes à f/4 : PDC ~45cm (plus de zone nette),
      mais tu devras monter l'ISO de 200 à 400."

4. LIMITES DU MATÉRIEL (si pertinent)
   → "Ton Sigma 18-50 ne descend pas en dessous de f/2.8.
      Pour plus de flou, il faudrait un objectif type 50mm f/1.4."
```

---

## 10. Mode exposition recommandé

Le mode d'exposition (P/A/S/M) est une recommandation pédagogique. Le moteur calcule toujours les valeurs comme en mode M, mais suggère le mode le plus adapté à la situation :

```
SI subject == "astro" :
  → M (pas le choix)
  "Le mode M est obligatoire en astro. Le posemètre ne fonctionne pas dans le noir."

SI intention == "bokeh" OU intention == "max_sharpness" :
  → A (Aperture Priority)
  "Le mode A te laisse contrôler l'ouverture — le paramètre clé ici —
   et l'appareil ajuste la vitesse automatiquement."

SI intention == "freeze_motion" OU intention == "motion_blur" :
  → S (Shutter Priority)
  "Le mode S te laisse contrôler la vitesse — le paramètre clé ici —
   et l'appareil ajuste l'ouverture automatiquement."

SI intention == "low_light" :
  → M
  "En basse lumière, le mode M te donne le contrôle total pour pousser
   chaque paramètre à son maximum."

SI environment == "studio" :
  → M
  "En studio, la lumière est contrôlée. Le mode M est standard."

DÉFAUT :
  → A (Aperture Priority)
  "Le mode A est le plus polyvalent pour apprendre.
   Tu contrôles le flou (ouverture), l'appareil gère le reste."
```

---

## 11. Score de confiance

Le moteur attribue un score de confiance au résultat global :

```
confidence = "high"

SI aucun paramètre Niveau 2 renseigné :
  confidence = max(confidence, "medium")
  // On devine la lumière → incertitude

SI compromis de sévérité "critical" :
  confidence = "low"

SI compromis de sévérité "warning" :
  confidence = max(confidence, "medium")

SI environment == "outdoor_day" ET aucune info complémentaire :
  confidence = "medium"
  // "outdoor_day" couvre un range EV très large (11-15)

SI tous les paramètres Niveau 1+2 renseignés ET aucun compromis :
  confidence = "high"
```

Le score de confiance est affiché dans l'UI et conditionne le message :
- **high** : "Ces réglages sont optimaux pour ta scène."
- **medium** : "Ces réglages sont une bonne base. Affine la description de ta scène pour des résultats plus précis."
- **low** : "Ces réglages sont un point de départ, mais des compromis importants ont été faits. Voir les détails."

---

## 12. Performance

### 12.1. Complexité algorithmique

Chaque phase est O(1) ou O(n) avec n très petit (nombre de réglages = 15) :
- Phase 1 : quelques calculs mathématiques + lookups dans des tables → O(1)
- Phase 2 : 7 arbres de décision, chacun ~5-10 conditions → O(1)
- Phase 3 : 3-5 calculs de triangle + arrondis → O(1)
- Phase 4 : parcours des résultats pour détecter les compromis → O(n), n=15

**Total** : O(1) en pratique. Quelques centaines d'opérations. Exécution < 1ms même sur mobile low-end. L'objectif de 500ms est largement dépassé.

### 12.2. Pas de dépendance externe

Le moteur n'a besoin que de :
- Les données `BodySpec` et `LensSpec` (déjà en mémoire après le téléchargement du data pack)
- Le `SceneInput` de l'utilisateur
- Les tables de référence (EV, vitesses standard, etc.) embarquées dans le code

Aucun appel réseau, aucun fichier à lire au runtime.

---

## 13. Testabilité

### 13.1. Scénarios de test essentiels

| # | Scénario | Input simplifié | Output attendu | Ce qu'on vérifie |
|---|----------|----------------|-----------------|------------------|
| T1 | Portrait sunny | A6700 + Sigma 18-50 f/2.8, outdoor_day, portrait, bokeh | f/2.8, 1/250-1/500s, ISO 100-200 | Ouverture max, ISO bas |
| T2 | Paysage couvert | A6700 + 18-50, outdoor_day, landscape, max_sharpness | f/8, 1/125-1/250s, ISO 100-400 | Sweet spot f/8, PDC |
| T3 | Sport indoor | A6700 + 18-50, indoor_dark, sport, freeze_motion | f/2.8, 1/500s, ISO 3200+ | Vitesse prioritaire, ISO monte |
| T4 | Astro | A6700 + 18-50 @18mm, outdoor_night, astro, max_sharpness, tripod | f/2.8, ~12s, ISO 3200-6400, MF | Règle NPF, ISO poussé |
| T5 | Street golden hour | A6700 + 18-50, outdoor_day, street, bokeh, golden_hour | f/2.8, 1/125-1/250s, ISO 100-400 | EV golden hour |
| T6 | Portrait nuit | A6700 + 18-50, outdoor_night, portrait, low_light, handheld | f/2.8, 1/60-1/125s, ISO 3200+ | Compromis bruit |
| T7 | Macro | A6700 + 18-50, outdoor_day, macro, max_sharpness | f/8, 1/250s+, ISO variable | PDC macro, vitesse haute |
| T8 | Impossible | A6700 + 18-50, outdoor_night, sport, freeze_motion, handheld, ISO max 1600 | Compromis critical | Détection impossibilité |
| T9 | Filé en plein jour | A6700 + 18-50, outdoor_day, sport, motion_blur, direct_sun | f/22, 1/15s, ISO 100, warning ND | Surexposition détectée |
| T10 | Vidéo portrait | A6700, video, indoor_bright, portrait, bokeh | f/2.8, 1/50s, ISO variable | Règle du double |

### 13.2. Stratégie de test

```
1. Tests unitaires par phase :
   - Phase 1 : calcul EV, calcul focale, calcul vitesse min
   - Phase 2 : chaque arbre de décision isolément
   - Phase 3 : résolution du triangle (précision mathématique)
   - Phase 4 : détection de compromis

2. Tests d'intégration (scénarios complets) :
   - Les 10 scénarios ci-dessus
   - Matrix : 14 boîtiers × 5 scènes courantes = 70 tests

3. Tests de régression :
   - Snapshot testing : on enregistre les résultats et on vérifie
     qu'ils ne changent pas entre les versions du moteur

4. Tests aux limites :
   - ISO minimum et maximum
   - Ouverture min et max de chaque objectif
   - Vitesse 1/8000 et 30s
   - Focale min et max de chaque zoom
```

---

*Ce document est la référence pour l'implémentation du moteur. Les arbres de décision et les tables sont directement transcriptibles en code. Les scénarios de test de la section 13 constituent le contrat de validation du moteur.*
