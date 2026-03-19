# i18n & Menu Localization — ShootHelper

> **Skill 07/22** · Système de traduction des menus et mapping multi-langue
> Version 1.0 · Mars 2026
> Réf : 04_CAMERA_DATA_ARCHITECTURE.md, 05_DATA_SOURCING_STRATEGY.md

---

## 1. Le problème de la double traduction

ShootHelper a un problème d'i18n **unique** que la plupart des apps n'ont pas : il y a **deux couches de langue** complètement indépendantes.

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  COUCHE 1 : Langue de l'app (UI)                          │
│  → Les boutons, les titres, les explications               │
│  → Contrôlée par la langue du téléphone                    │
│  → Classique, comme toute app                              │
│                                                            │
│  COUCHE 2 : Langue du firmware (menus caméra)              │
│  → Les noms des menus tels qu'affichés sur l'appareil      │
│  → Contrôlée par le choix de l'utilisateur dans l'app      │
│  → INDÉPENDANTE de la langue du téléphone                  │
│  → Spécifique à chaque modèle de boîtier                   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

**Exemple concret** : Un utilisateur francophone avec un Sony A6700 configuré en allemand.

- L'app affiche ses boutons et explications **en français** (Couche 1)
- Les chemins de menu affichent les noms **en allemand** (Couche 2)
- Le résultat dans l'écran Menu Navigation :

```
📍 Mode AF → AF-C                          ← Couche 1 (français)

VIA LE MENU
❶ Menu > AF/MF                             ← Couche 2 (allemand — identique)
❷ → AF/MF-Einst.                           ← Couche 2 (allemand)
❸ → Fokusmodus > Nachführ-AF (AF-C)        ← Couche 2 (allemand)

L'AF continu suit ton sujet tant que          ← Couche 1 (français)
tu maintiens le déclencheur enfoncé.
```

**Règle fondamentale : ces deux couches ne se mélangent JAMAIS.** Le texte de l'UI est toujours dans la langue de l'app. Les noms de menus sont toujours dans la langue firmware. Même si les deux sont français — on utilise des sources de données différentes.

---

## 2. Couche 1 : Langue de l'app (UI i18n classique)

### 2.1. Portée

Tout le texte produit par l'app elle-même :

- Écrans d'onboarding ("Quel est ton boîtier ?")
- Labels des paramètres de scène ("Environnement", "Sujet", "Intention")
- Explications des réglages ("Ouverture grande ouverte pour maximiser le flou…")
- Messages d'erreur et de compromis
- Boutons, titres, navigation
- Tips et astuces

### 2.2. Langues supportées (MVP)

| Langue | Code | Priorité |
|--------|------|----------|
| Français | `fr` | P0 — langue de dev |
| English | `en` | P0 — langue de référence |

**MVP = bilingue FR/EN uniquement.** L'architecture supporte l'ajout de langues, mais le contenu sera rédigé en FR et EN pour le lancement. Autres langues en V2.

### 2.3. Implémentation

Standard i18n classique : fichiers de traduction clé-valeur, un par langue.

```
locales/
├── en.json
└── fr.json
```

```json
// en.json
{
  "home.new_shoot": "New shoot",
  "home.gear_label": "Your gear",
  "scene.title": "Describe your scene",
  "scene.environment": "Environment",
  "scene.environment.outdoor_day": "Outdoor – Day",
  "scene.environment.outdoor_night": "Outdoor – Night",
  "scene.subject": "Subject",
  "scene.subject.portrait": "Portrait",
  "scene.intention": "Intention",
  "scene.intention.bokeh": "Background blur",
  "result.title": "Your settings",
  "result.compromise_banner": "{{count}} compromise(s) made",
  "explain.aperture.bokeh": "Wide open at {{value}} to maximize background blur with your {{lens}}.",
  "explain.iso.low_noise": "ISO {{value}} — virtually no noise.",
  "explain.iso.visible_noise": "ISO {{value}} — visible noise, shoot in RAW recommended.",
  "nav.quick_method": "Quick method",
  "nav.via_menu": "Via the menu",
  "nav.step": "Step {{current}}/{{total}}",
  "nav.tip": "Tip"
}
```

```json
// fr.json
{
  "home.new_shoot": "Nouveau shoot",
  "home.gear_label": "Ton matériel",
  "scene.title": "Décris ta scène",
  "scene.environment": "Environnement",
  "scene.environment.outdoor_day": "Extérieur – Jour",
  "scene.environment.outdoor_night": "Extérieur – Nuit",
  "scene.subject": "Sujet",
  "scene.subject.portrait": "Portrait",
  "scene.intention": "Intention",
  "scene.intention.bokeh": "Flou d'arrière-plan",
  "result.title": "Tes réglages",
  "result.compromise_banner": "{{count}} compromis effectué(s)",
  "explain.aperture.bokeh": "Ouverture grande ouverte à {{value}} pour maximiser le flou d'arrière-plan avec ton {{lens}}.",
  "explain.iso.low_noise": "ISO {{value}} — bruit quasi inexistant.",
  "explain.iso.visible_noise": "ISO {{value}} — bruit visible, shooter en RAW recommandé.",
  "nav.quick_method": "Méthode rapide",
  "nav.via_menu": "Via le menu",
  "nav.step": "Étape {{current}}/{{total}}",
  "nav.tip": "Astuce"
}
```

**Convention de nommage des clés :** `écran.section.élément` en snake_case. Les variables dynamiques utilisent `{{variable}}`.

### 2.4. Détection de langue

```
1. Lire la langue du système (téléphone)
2. Si supportée par l'app → utiliser
3. Sinon → fallback EN
4. L'utilisateur peut forcer la langue dans les settings (V2)
```

---

## 3. Couche 2 : Langue firmware (menus caméra)

### 3.1. Portée

Tout texte qui **reproduit un élément affiché sur l'écran du boîtier** :

- Noms des onglets de menu
- Noms des sous-menus
- Noms des réglages
- Noms des valeurs de réglages
- Noms des boutons physiques (quand ils sont sérigraphiés dans une langue)
- Labels du menu Fn / Q Menu

### 3.2. Source de vérité

La source de vérité est le `labels` object dans le `MenuTree` et les `Controls` (skill 04). Ces labels sont extraits des Help Guides officiels dans chaque langue (skill 05).

```json
// Extrait de menu_tree.json — Sony A6700
{
  "id": "focus_mode",
  "labels": {
    "en": "Focus Mode",
    "fr": "Mode mise au point",
    "de": "Fokusmodus",
    "es": "Modo de enfoque",
    "it": "Modo messa a fuoco",
    "ja": "フォーカスモード",
    "ko": "초점 모드",
    "zh-cn": "对焦模式"
  },
  "values": [
    {
      "id": "af-s",
      "labels": { "en": "Single-shot AF", "fr": "AF ponctuel", "de": "Einzelbild-AF", "ja": "シングルAF" },
      "short_labels": { "en": "AF-S", "fr": "AF-S", "de": "AF-S", "ja": "AF-S" }
    }
  ]
}
```

**Règle absolue** : le texte dans `labels` doit être le **copié-collé exact** de ce qui s'affiche sur l'écran du boîtier. Pas de reformulation, pas de correction grammaticale, pas de standardisation. Si Sony écrit "Mode mise au point" avec un "m" minuscule, on écrit "Mode mise au point" avec un "m" minuscule.

### 3.3. Labels vs Short Labels

Beaucoup de réglages ont deux formes d'affichage sur l'appareil :

| Contexte | Quel label | Exemple |
|----------|-----------|---------|
| Dans le menu (texte complet) | `labels` | "AF continu" |
| Dans le viseur/écran de prise de vue (abrégé) | `short_labels` | "AF-C" |
| Sur les boutons physiques (sérigraphie) | `short_labels` ou spécifique | "AF-ON" |

```json
{
  "id": "af-c",
  "labels": {
    "en": "Continuous AF",
    "fr": "AF continu",
    "de": "Nachführ-AF"
  },
  "short_labels": {
    "en": "AF-C",
    "fr": "AF-C",
    "de": "AF-C"
  }
}
```

Note : les `short_labels` sont souvent identiques entre les langues (abréviations universelles comme AF-C, ISO, WB). Mais pas toujours — il faut vérifier pour chaque boîtier.

**Usage dans l'UI :**

- Écran Résultats (vue liste) → `short_labels` ("AF-C")
- Écran Détail Réglage → `labels` ("AF continu")
- Écran Menu Navigation → `labels` dans le breadcrumb ("Mode mise au point > AF continu")

---

## 4. Le glossaire cross-brand

### 4.1. Le problème

Le Settings Engine raisonne en **concepts universels** (setting_id). Mais chaque marque utilise des noms différents pour le même concept, et ces noms changent selon la langue.

```
Concept universel : "Autofocus continu"
  → Sony (EN) :   "Continuous AF"
  → Sony (FR) :   "AF continu"
  → Sony (DE) :   "Nachführ-AF"
  → Canon (EN) :  "Servo AF"       ← Nom complètement différent !
  → Canon (FR) :  "Autofocus Servo"
  → Nikon (EN) :  "Continuous-servo AF"
  → Nikon (FR) :  "AF continu (AF-C)"
  → Fuji (EN) :   "AF-C"
  → Fuji (FR) :   "AF-C"
```

L'app doit faire le pont entre le concept universel et la terminologie exacte du boîtier de l'utilisateur.

### 4.2. Architecture de résolution

```
Settings Engine
  │
  │ Output : { setting_id: "af_mode", value: "af-c" }
  │          (concept universel, indépendant de la marque)
  │
  ▼
Localization Layer
  │
  │ 1. Résoudre setting_id → MenuItem dans le MenuTree du boîtier
  │ 2. Résoudre value → MenuValue dans le MenuItem
  │ 3. Extraire labels[firmware_lang] pour le nom du menu
  │ 4. Extraire labels[firmware_lang] pour la valeur
  │ 5. Extraire labels[app_lang] pour l'explication
  │
  ▼
UI Display
  │
  │ "Mode AF → AF-C"                   (concept → short_label firmware)
  │ "Menu > AF/MF > Mode mise au point  (breadcrumb en firmware_lang)
  │        > AF continu (AF-C)"
  │ "L'AF continu suit ton sujet..."    (explication en app_lang)
```

Le pont entre le concept universel (`setting_id + value`) et la terminologie du boîtier est assuré par le `SettingNavPath` (skill 04) qui lie `setting_id` → `menu_item_id` dans le `MenuTree`.

### 4.3. Table de correspondance cross-brand (référence)

Cette table est **informative** — elle n'est pas stockée dans l'app. C'est une référence pour le data entry. La correspondance réelle est faite via les `SettingNavPath` par boîtier.

#### Modes Autofocus

| setting_id:value | Concept | Sony | Canon | Nikon | Fuji |
|-----------------|---------|------|-------|-------|------|
| `af_mode:af-s` | AF ponctuel | Single-shot AF (AF-S) | One-Shot AF | Single-servo AF (AF-S) | AF-S |
| `af_mode:af-c` | AF continu | Continuous AF (AF-C) | Servo AF | Continuous-servo AF (AF-C) | AF-C |
| `af_mode:af-a` | AF auto | — (pas sur tous) | — (supprimé sur RF) | Auto-servo AF (AF-A) | AF-A |
| `af_mode:dmf` | MF direct | DMF | — | — | — |
| `af_mode:mf` | Manuel | Manual Focus (MF) | Manual Focus (MF) | Manual focus | MF |

#### Zones AF

| setting_id:value | Concept | Sony | Canon | Nikon | Fuji |
|-----------------|---------|------|-------|-------|------|
| `af_area:wide` | Large/auto | Wide | Whole area | Auto-area AF | All |
| `af_area:zone` | Zone | Zone | Zone AF | Wide-area AF (L) | Zone |
| `af_area:center` | Centre | Center | 1-point AF | Single-point AF | Single Point |
| `af_area:spot` | Spot | Flexible Spot | Spot AF | Pinpoint AF | — |
| `af_area:tracking` | Suivi | Tracking | — | Subject-tracking | Tracking |
| `af_area:eye_af` | Détection œil | Eye AF | Eye Detection | Eye-Detection AF | Face/Eye Detection |

#### Modes de mesure

| setting_id:value | Concept | Sony | Canon | Nikon | Fuji |
|-----------------|---------|------|-------|-------|------|
| `metering:multi` | Matricielle | Multi | Evaluative | Matrix | Multi |
| `metering:center` | Centre pondéré | Center | Center-weighted | Center-weighted | Average |
| `metering:spot` | Spot | Spot | Spot | Spot | Spot |
| `metering:highlight` | Hautes lumières | Highlight | — | Highlight-weighted | — |

#### Modes d'exposition

| setting_id:value | Concept | Sony | Canon | Nikon | Fuji |
|-----------------|---------|------|-------|-------|------|
| `exposure_mode:P` | Programme | P | P | P | P |
| `exposure_mode:A` | Priorité ouverture | A | Av | A | A |
| `exposure_mode:S` | Priorité vitesse | S | Tv | S | S |
| `exposure_mode:M` | Manuel | M | M | M | M |

Note : Canon utilise "Av" (Aperture value) et "Tv" (Time value) au lieu de "A" et "S". C'est la divergence la plus connue.

#### Balance des blancs

| setting_id:value | Concept | Sony (FR) | Canon (FR) | Nikon (FR) | Fuji (FR) |
|-----------------|---------|-----------|-----------|-----------|----------|
| `wb:auto` | Auto | Bal. blancs auto | Balance des blancs auto | Automatique | Auto |
| `wb:daylight` | Jour | Lumière du jour | Lumière du jour | Ensoleillé | Beau temps |
| `wb:shade` | Ombre | Ombre | Ombre | Ombre | Ombre |
| `wb:cloudy` | Nuageux | Nuageux | Nuageux | Temps couvert | Nuageux |
| `wb:tungsten` | Tungstène | Incandescent | Tungstène | Incandescent | Incandescent |
| `wb:fluorescent` | Fluorescent | Fluor. : blanc froid | Fluorescent | Fluorescent | Fluorescent 1 |

Note : même en français, chaque marque a des noms légèrement différents. "Lumière du jour" vs "Ensoleillé" vs "Beau temps" pour le même concept. C'est exactement pour ça que les labels doivent être extraits per-boîtier et non partagés.

---

## 5. Résolution runtime

### 5.1. Algorithme de résolution du label affiché

```typescript
function resolveSettingDisplay(
  setting_id: string,
  value: string,
  body: Body,
  firmware_lang: string,
  app_lang: string
): SettingDisplay {

  // 1. Trouver le NavPath pour ce réglage sur ce boîtier
  const navPath = findNavPath(body.id, setting_id);

  // 2. Trouver le MenuItem dans le MenuTree
  const menuItem = navPath.menu_item_id
    ? findMenuItem(body.menu_tree, navPath.menu_item_id)
    : null;

  // 3. Résoudre le label du réglage en langue firmware
  const setting_label_firmware = menuItem
    ? resolveLabel(menuItem.labels, firmware_lang)
    : setting_id; // fallback

  // 4. Résoudre le label de la valeur en langue firmware
  const menuValue = menuItem?.values?.find(v => v.id === value);
  const value_label_firmware = menuValue
    ? resolveLabel(menuValue.labels, firmware_lang)
    : value;
  const value_short_firmware = menuValue?.short_labels
    ? resolveLabel(menuValue.short_labels, firmware_lang)
    : value_label_firmware;

  // 5. Construire le breadcrumb du chemin menu en langue firmware
  const breadcrumb = navPath.menu_path
    ? navPath.menu_path.map(id => {
        const node = findMenuItem(body.menu_tree, id);
        return resolveLabel(node.labels, firmware_lang);
      })
    : null;

  // 6. Résoudre les explications en langue app
  const explanation = buildExplanation(setting_id, value, body, app_lang);

  return {
    setting_label_firmware,   // "Mode mise au point" (firmware lang)
    value_label_firmware,     // "AF continu" (firmware lang)
    value_short_firmware,     // "AF-C" (firmware lang)
    breadcrumb,               // ["AF/MF", "Régl. AF/MF", "Mode mise au point"]
    explanation               // Texte libre en langue app
  };
}

function resolveLabel(labels: Record<string, string>, lang: string): string {
  return labels[lang]
    ?? labels["en"]
    ?? labels[Object.keys(labels)[0]]
    ?? "???";
}
```

### 5.2. Assemblage de l'affichage Menu Navigation

```typescript
function buildMenuNavDisplay(
  setting_id: string,
  value: string,
  body: Body,
  firmware_lang: string,
  app_lang: string
): MenuNavDisplay {

  const navPath = findNavPath(body.id, setting_id);
  const display = resolveSettingDisplay(setting_id, value, body, firmware_lang, app_lang);

  const sections: NavSection[] = [];

  // Méthode rapide (molette)
  if (navPath.dial_access) {
    sections.push({
      type: "quick",
      title: t("nav.quick_method", app_lang),      // "Méthode rapide"
      instruction: resolveLabel(
        navPath.dial_access.labels, app_lang         // Texte explicatif en langue app
      ),
      dial_label: resolveLabel(
        body.controls.dials.find(d => d.id === navPath.dial_access.dial_id).label,
        firmware_lang                                 // Nom de la molette en langue firmware
      )
    });
  }

  // Méthode rapide (Fn)
  if (navPath.quick_access) {
    sections.push({
      type: "quick",
      title: t("nav.quick_method", app_lang),
      steps: navPath.quick_access.steps.map((step, i) => ({
        number: i + 1,
        action_label: resolveLabel(step.labels, app_lang),  // Instruction en langue app
        target_label: step.target === "fn_button"
          ? resolveLabel(
              body.controls.buttons.find(b => b.id === "fn_button").label,
              firmware_lang                                   // "Fn" en langue firmware
            )
          : resolveLabel(
              findMenuItem(body.menu_tree, step.target).labels,
              firmware_lang                                   // Nom du menu en firmware lang
            )
      }))
    });
  }

  // Via le menu
  if (navPath.menu_path && display.breadcrumb) {
    const menuSteps = display.breadcrumb.map((label, i) => ({
      number: i + 1,
      total: display.breadcrumb.length + 1,           // +1 pour la sélection de valeur
      label: label                                     // En langue firmware
    }));

    // Dernière étape : sélection de la valeur
    menuSteps.push({
      number: display.breadcrumb.length + 1,
      total: display.breadcrumb.length + 1,
      label: `${display.setting_label_firmware} > ${display.value_label_firmware}`
    });

    sections.push({
      type: "menu",
      title: t("nav.via_menu", app_lang),              // "Via le menu"
      steps: menuSteps
    });
  }

  // Tips
  const tips = navPath.tips?.map(tip => ({
    text: resolveLabel(tip.labels, app_lang)            // Tips en langue app
  })) ?? [];

  return {
    header: `${display.setting_label_firmware} → ${display.value_short_firmware}`,
    body_name: body.display_name,
    firmware_lang_label: firmware_lang,
    sections,
    tips
  };
}
```

### 5.3. Quelle langue pour quoi — Récapitulatif

| Élément affiché | Langue utilisée | Pourquoi |
|-----------------|-----------------|----------|
| Titre d'écran ("Tes réglages") | App lang | C'est l'UI de l'app |
| Nom du réglage dans la liste résultats | App lang (concept) | L'utilisateur lit dans sa langue |
| Valeur du réglage dans la liste résultats | Firmware lang (short_label) | C'est ce qu'il verra sur son appareil |
| Explication courte | App lang | C'est du contenu éducatif |
| Explication détaillée | App lang | C'est du contenu éducatif |
| Breadcrumb menu (Menu > AF/MF > …) | **Firmware lang** | C'est le chemin sur son appareil |
| Nom du réglage dans le menu | **Firmware lang** | C'est le texte sur l'écran de l'appareil |
| Valeur dans le menu | **Firmware lang** | C'est le texte sur l'écran de l'appareil |
| Nom des boutons physiques | **Firmware lang** (souvent EN) | Sérigraphie physique |
| Instruction de navigation ("Tourne la molette…") | App lang | C'est une instruction de l'app |
| Tips et astuces | App lang | C'est du contenu éducatif |
| Messages de compromis | App lang | C'est du contenu de l'app |

---

## 6. Cas limites et problèmes connus

### 6.1. Labels tronqués sur l'écran du boîtier

Certains boîtiers tronquent les labels longs dans l'affichage menu à cause de la taille de l'écran.

Exemple Sony A6700 en français :
- Menu complet : "Plage de tempér. couleur : Pers."
- Affiché sur le boîtier : "Plge tmp. coul. : Pers."

**Règle** : dans les `labels`, on stocke le **texte complet** tel qu'il apparaît dans le Help Guide (pas la version tronquée de l'écran). C'est plus lisible dans l'app et ça correspond à ce que l'utilisateur cherchera dans le Help Guide s'il veut en savoir plus.

**Exception** : si le Help Guide lui-même utilise la forme abrégée, on utilise cette forme.

### 6.2. Labels identiques entre langues

Beaucoup de labels techniques sont identiques dans toutes les langues :

- "AF-S", "AF-C", "MF" → identique partout
- "ISO" → identique partout
- "RAW", "JPEG" → identique partout
- "P", "A", "S", "M" → identique partout (sauf Canon : "Av", "Tv")
- "AF-ON" → identique (sérigraphie anglaise sur tous les boîtiers)
- "MENU" → identique
- "Fn" → identique

On les stocke quand même dans chaque langue du `labels` object, même si la valeur est la même. Ça évite d'introduire une logique de "label par défaut" et ça garantit que si un constructeur décide un jour de localiser un de ces termes, on est prêt.

### 6.3. Noms de boutons sérigraphiés

Les boutons physiques sont sérigraphiés en anglais sur la quasi-totalité des boîtiers, quelle que soit la région de vente. "AF-ON", "MENU", "Fn", "C1", "C2" sont les mêmes sur un Sony vendu en France et au Japon.

**Exception notable** : certains boîtiers Nikon ont un bouton "i" (minuscule) dont le label n'est pas anglais mais universel. Les molettes n'ont généralement pas de texte, juste des icônes.

**Règle** : dans `Controls.buttons[].label`, le label firmware est souvent le même dans toutes les langues. On le stocke quand même par langue pour uniformité.

### 6.4. Canon Av/Tv vs A/S

Canon utilise "Av" (Aperture value) et "Tv" (Time value) au lieu de "A" et "S" que tout le monde utilise. C'est la divergence cross-brand la plus visible pour un débutant.

Le Settings Engine produit `exposure_mode: "A"` (concept universel). Le mapping est :

```
Canon bodies :
  "A" → affiché "Av" (via short_labels du MenuItem)
  "S" → affiché "Tv"

Tous les autres :
  "A" → affiché "A"
  "S" → affiché "S"
```

Ce mapping est déjà géré par l'architecture `MenuItem.values[].short_labels` — pas besoin de logique spéciale.

### 6.5. Fujifilm Film Simulations

Fuji a un concept unique qui n'existe pas chez les autres : les Film Simulations (Provia, Velvia, Astia, Classic Chrome, etc.).

**Pour le MVP** : on ne recommande pas de Film Simulation. C'est un choix esthétique qui n'affecte pas l'exposition ni la mise au point. Si on l'ajoute en V2, c'est une extension du Settings Engine avec un nouveau `setting_id: "film_simulation"` et des valeurs spécifiques Fuji.

### 6.6. Menu structure différente entre modes photo/vidéo

Sur beaucoup de boîtiers (surtout Sony), la structure du menu change selon qu'on est en mode Photo ou Vidéo. Certains items apparaissent ou disparaissent.

**Gestion** : le `MenuItem` a déjà un champ `note` qui peut contenir "Disponible uniquement en mode Photo" ou similaire. Le `SettingNavPath` peut avoir plusieurs `menu_path` selon le contexte. Pour le MVP, on simplifie :

```json
{
  "setting_id": "shutter_speed",
  "context_photo": {
    "menu_path": ["shooting", "exposure", "shutter_speed"],
    "dial_access": { "exposure_mode": "M", "dial_id": "rear_dial" }
  },
  "context_video": {
    "menu_path": ["shooting", "exposure", "shutter_speed"],
    "dial_access": { "exposure_mode": "M", "dial_id": "rear_dial" },
    "note": "En vidéo, la vitesse est liée au framerate (règle du double)."
  }
}
```

Si les chemins diffèrent entre photo et vidéo, on utilise le contexte fourni par le `shoot_type` du SceneInput.

---

## 7. Validation i18n

### 7.1. Checks automatisés

| Check | Description | Bloquant |
|-------|-------------|----------|
| **Complétude labels** | Chaque `labels` object doit contenir au moins `en` + toutes les langues de `Body.supported_languages` | Oui |
| **Complétude short_labels** | Si `labels` existe pour une langue, `short_labels` doit aussi exister (ou être absent pour tous) | Oui |
| **Pas de labels vides** | Aucune valeur `""` ou whitespace-only | Oui |
| **Cohérence casse** | Warning si la casse d'un label diffère entre langues de façon suspecte (ex: "AF-c" vs "AF-C") | Warning |
| **Caractères spéciaux** | Vérifier que les caractères japonais/chinois/coréens sont bien encodés en UTF-8 | Oui |
| **Longueur** | Warning si un label dépasse 60 caractères (risque de troncature UI) | Warning |

### 7.2. Checks manuels (spot check)

Pour chaque boîtier, lors de la phase de validation (skill 05, Étape 6) :

```
☐ Vérifier 5 labels FR en ouvrant le Help Guide FR et l'écran du boîtier
☐ Vérifier 5 labels EN en ouvrant le Help Guide EN
☐ Vérifier que les short_labels correspondent à ce qui s'affiche dans le viseur
☐ Vérifier que les noms de boutons correspondent à la sérigraphie physique
☐ Tester le flow Menu Navigation complet pour 3 réglages en FR
```

### 7.3. Erreurs les plus courantes à anticiper

| Erreur | Exemple | Prévention |
|--------|---------|------------|
| Espace insécable | Le Help Guide FR utilise des espaces insécables avant ":" et ";" | Normaliser en espaces classiques |
| Guillemets typographiques | "Mode AF" vs "Mode AF" | Normaliser en guillemets droits dans les labels |
| Tirets | "AF-C" vs "AF‑C" (tiret insécable) | Normaliser en tiret standard |
| Retours chariot | Certains labels HTML ont des `\n` parasites | Strip lors du scraping |
| Majuscules/minuscules | Sony FR : "Mode mise au point" (minuscule) vs "Mode Mise Au Point" | Prendre le texte exact du Help Guide, ne pas standardiser |

---

## 8. Couche UI de l'app — Termes photographiques

### 8.1. Glossaire FR/EN des termes de l'app

Les explications et l'UI de l'app utilisent des termes photographiques standardisés. Voici la convention :

| Concept | Terme EN (app) | Terme FR (app) | Note |
|---------|---------------|----------------|------|
| Aperture | Aperture | Ouverture | Jamais "diaphragme" dans l'UI |
| Shutter speed | Shutter speed | Vitesse d'obturation | Jamais "temps de pose" (trop technique) |
| ISO | ISO | ISO | Invariable, pas d'article |
| Depth of field | Depth of field | Profondeur de champ | Abrégé "PDC" dans les explications détaillées |
| Bokeh | Background blur | Flou d'arrière-plan | "Bokeh" acceptable entre parenthèses |
| Exposure | Exposure | Exposition | |
| White balance | White balance | Balance des blancs | |
| Autofocus | Autofocus (AF) | Autofocus (AF) | Même en français, "autofocus" pas "mise au point automatique" |
| Metering | Metering | Mesure | "Mode de mesure" en contexte complet |
| Stabilization | Stabilization | Stabilisation | |
| Noise | Noise | Bruit | "Bruit numérique" si ambiguïté |
| Dynamic range | Dynamic range | Plage dynamique | |
| Exposure compensation | Exposure compensation | Compensation d'exposition | Abrégé "comp. expo" dans les listes |
| Burst / Drive | Drive mode | Mode d'entraînement | "Rafale" pour le mode continu |
| Crop factor | Crop factor | Facteur de recadrage | "Crop factor" acceptable en FR aussi |
| Full-frame | Full-frame | Plein format | |
| APS-C | APS-C | APS-C | Invariable |
| Exposure value (EV) | EV | EV (IL) | "IL" = Indice de Lumination, équivalent FR |
| Stop | Stop | Stop | "Cran" comme alternative FR |

### 8.2. Ton et registre

Les explications de l'app utilisent le tutoiement en français ("Ton objectif", "Tu peux", "Ajuste l'ouverture"). C'est cohérent avec la cible débutant et le ton direct défini dans le PRD.

En anglais, le ton est direct et deuxième personne ("Your lens", "You can", "Adjust the aperture").

---

## 9. Architecture fichier complète

```
src/
├── i18n/
│   ├── locales/
│   │   ├── en.json              # UI strings EN
│   │   └── fr.json              # UI strings FR
│   │
│   ├── i18n_service.ts          # Chargement, détection langue, fonction t()
│   │
│   └── firmware_label_resolver.ts
│       # resolveLabel(labels, lang)
│       # resolveSettingDisplay(setting_id, value, body, firmware_lang, app_lang)
│       # buildMenuNavDisplay(...)
│
├── data/                         # Data packs téléchargés (skill 04)
│   └── ...                       # menu_tree.json contient les labels firmware
│
└── engine/
    └── explanation_builder.ts    # Génère les textes d'explication en app_lang
        # Utilise les templates de locales/{lang}.json
        # Injecte les valeurs firmware_lang quand nécessaire
```

**Séparation claire** : `i18n_service.ts` gère la Couche 1 (app UI). `firmware_label_resolver.ts` gère la Couche 2 (firmware labels). Ils ne se mélangent que dans `explanation_builder.ts` qui peut injecter un label firmware dans un template app (ex: "Tourne la **{dial_label}** pour régler l'ouverture" — {dial_label} vient de la Couche 2).

---

*Ce document est la référence pour les skills UI/UX Design System (03), Menu Navigation Mapper (19), et l'implémentation de toute l'internationalisation de l'app. La distinction Couche 1 / Couche 2 est la décision architecturale la plus importante de ce skill.*
