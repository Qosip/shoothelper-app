# UI/UX Design System — ShootHelper

> **Skill 03/22** · Design System
> Version 1.0 · Mars 2026
> Réf : 01_PRD.md, 02_USER_FLOWS.md

---

## 1. Philosophie Design

### Principes fondamentaux

ShootHelper est un **outil de terrain**. L'utilisateur est dehors, téléphone dans une main, appareil photo dans l'autre. Soleil, nuit, gants, stress du moment. Le design doit répondre à ça :

1. **Lisibilité extrême** — Texte lisible en plein soleil comme en nuit totale. Contrastes forts, hiérarchie claire, jamais de gris sur gris.
2. **One-hand friendly** — Les actions principales sont dans la zone du pouce. Pas de tap en haut à gauche pour les actions critiques.
3. **Zéro friction** — Chaque tap doit avancer vers le résultat. Pas de modales inutiles, pas de confirmations superflues.
4. **Confiance** — L'app donne des recommandations techniques. Le design doit inspirer confiance : précis, net, structuré. Pas de "fun UI" avec des emojis partout.
5. **Progressive disclosure** — Montrer peu, permettre d'aller deep. Le Niveau 1 est simple, le Niveau 3 est dense — mais l'utilisateur choisit.

### Direction esthétique

**"Instrument de précision"** — Inspiré des interfaces d'instruments de mesure professionnels et des HUD de caméra. Sobre, technique, premium sans être froid.

Pas de : gradients flashy, illustrations cartoon, UI "amicale" avec des bulles et des coins ronds géants.
Oui à : netteté, typographie technique, données denses bien organisées, accents de couleur chirurgicaux.

---

## 2. Couleurs

### 2.1. Palette — Dark Mode par défaut

L'app est **dark mode par défaut**. Les photographes travaillent souvent en faible lumière et un écran blanc casse l'adaptation nocturne. Le light mode est supporté mais secondaire.

#### Dark Mode (Principal)

```
──────────────────────────────────────────────
TOKEN                   HEX        USAGE
──────────────────────────────────────────────
--bg-primary            #0D0F12    Fond principal (quasi noir, légèrement bleuté)
--bg-secondary          #161A1F    Cartes, surfaces élevées
--bg-tertiary           #1E2328    Inputs, zones interactives
--bg-elevated           #252A30    Modales, bottom sheets

--text-primary          #F0F2F4    Texte principal (pas blanc pur, réduit la fatigue)
--text-secondary        #8B929A    Labels, texte secondaire
--text-tertiary         #555D66    Placeholders, texte désactivé

--accent-primary        #3B82F6    Bleu vif — actions principales, CTA, liens
--accent-primary-hover  #2563EB    Hover / pressed
--accent-secondary      #F59E0B    Ambre — avertissements, compromis, badges
--accent-success        #10B981    Vert — confirmations, téléchargement OK
--accent-danger         #EF4444    Rouge — erreurs, suppression

--border-default        #2A3038    Bordures subtiles
--border-focus          #3B82F6    Bordure focus/active (= accent)

--chip-bg               #1E2328    Fond chip non sélectionné
--chip-bg-active        #1E3A5F    Fond chip sélectionné (bleu très sombre)
--chip-text             #8B929A    Texte chip non sélectionné
--chip-text-active      #3B82F6    Texte chip sélectionné
--chip-border-active    #3B82F6    Bordure chip sélectionné
──────────────────────────────────────────────
```

#### Light Mode (Secondaire)

```
──────────────────────────────────────────────
TOKEN                   HEX        USAGE
──────────────────────────────────────────────
--bg-primary            #FAFBFC    Fond principal
--bg-secondary          #FFFFFF    Cartes
--bg-tertiary           #F0F2F5    Inputs
--bg-elevated           #FFFFFF    Modales

--text-primary          #111318    Texte principal
--text-secondary        #5F6773    Labels
--text-tertiary         #9CA3AD    Placeholders

--accent-primary        #2563EB    Bleu (légèrement plus foncé qu'en dark)
--accent-secondary      #D97706    Ambre plus foncé pour contraste
──────────────────────────────────────────────
```

#### Règles couleur

- Le ratio de contraste texte/fond respecte **WCAG AA minimum** (4.5:1 pour le texte, 3:1 pour les éléments UI).
- L'accent bleu n'est **jamais utilisé pour du texte long** — uniquement pour des labels courts, liens, et éléments interactifs.
- L'ambre est **exclusivement** réservé aux avertissements et compromis du moteur. Pas pour de la déco.
- Pas de couleur de marque caméra (orange Sony, rouge Canon). L'app est neutre.

---

## 3. Typographie

### Choix de polices

```
──────────────────────────────────────────────
RÔLE           POLICE            FALLBACK
──────────────────────────────────────────────
Display        JetBrains Mono    monospace
(valeurs,      (les chiffres de réglages :
 données)       f/2.8, 1/250s, ISO 800)

Headings       Outfit            sans-serif
(titres,       Semi-Bold (600)
 sections)

Body           Outfit            sans-serif
(texte,        Regular (400)
 explications)

Caption        Outfit            sans-serif
(labels,       Medium (500)
 métadonnées)
──────────────────────────────────────────────
```

**Pourquoi ces choix :**

- **JetBrains Mono** pour les données : c'est une police monospace conçue pour la lisibilité des chiffres et des caractères techniques. Les valeurs f/2.8, 1/250s, ISO 3200 sont le cœur de l'app — elles méritent une police qui les rend lisibles et "techniques". Le côté monospace renforce la précision.
- **Outfit** pour tout le reste : géométrique, moderne, très lisible sur mobile, excellente en petite taille. Suffisamment neutre pour ne pas distraire mais assez caractéristique pour ne pas être générique.

### Échelle typographique

```
──────────────────────────────────────────────
TOKEN            TAILLE    POIDS    INTERLIGNE   USAGE
──────────────────────────────────────────────
--text-display   32px      600      1.1          Valeurs héros (f/2.8 dans le résumé)
--text-h1        24px      600      1.2          Titres d'écran
--text-h2        20px      600      1.3          Titres de section
--text-h3        17px      600      1.3          Sous-titres
--text-body      15px      400      1.5          Texte courant, explications
--text-body-sm   13px      400      1.5          Texte secondaire, descriptions
--text-caption   12px      500      1.4          Labels, métadonnées
--text-mono-lg   28px      500      1.1          Valeurs de réglages (résultats)
--text-mono-md   20px      500      1.2          Valeurs inline
--text-mono-sm   15px      400      1.3          Valeurs dans les listes
──────────────────────────────────────────────
```

### Règles typographiques

- Les **valeurs de réglages** (f/2.8, 1/250s, ISO 800) sont **toujours** en JetBrains Mono.
- Les **unités** (s, mm, K) restent attachées à la valeur, pas d'espace : `1/250s`, `50mm`, `5500K`.
- Les **noms de menus de l'appareil** dans le Menu Navigation sont en **Outfit Medium, avec un fond --bg-tertiary** pour les distinguer visuellement du texte explicatif.
- Pas de MAJUSCULES pour les titres longs. Majuscules réservées aux **labels de section courts** (TYPE DE SHOOT, ENVIRONNEMENT).

---

## 4. Espacement & Grille

### Échelle d'espacement

Base 4px. Tout l'espacement est un multiple de 4.

```
──────────────────────────────────────
TOKEN        VALEUR    USAGE
──────────────────────────────────────
--space-xs   4px       Micro gap (entre icône et label)
--space-sm   8px       Gap entre éléments liés
--space-md   12px      Padding interne composants
--space-lg   16px      Gap entre composants
--space-xl   24px      Gap entre sections
--space-2xl  32px      Marges écran, séparations majeures
--space-3xl  48px      Espacement entre blocs majeurs
──────────────────────────────────────
```

### Grille mobile

```
┌──────────────────────────────────────┐
│←16→┌──────────────────────┐←16→│
│    │                      │    │
│    │   Content Area       │    │
│    │   (100% - 32px)      │    │
│    │                      │    │
│    └──────────────────────┘    │
└──────────────────────────────────────┘

Marges latérales : 16px (--space-lg)
Pas de colonnes — layout en stack vertical
Max-width content : aucun (mobile only, pas de tablette au MVP)
```

### Safe zones

```
┌──────────────────────────────────────┐
│          Status bar                  │
│──────────────────────────────────────│
│                                      │
│   Zone scrollable                    │
│                                      │
│                                      │
│                                      │
│──────────────────────────────────────│
│   Zone pouce (bottom 120px)          │
│   → CTA principal ici                │
│   → Navigation ici                   │
│──────────────────────────────────────│
│   Safe area bottom (iOS/Android)     │
└──────────────────────────────────────┘

Le CTA principal (ex: "Calculer mes réglages") est TOUJOURS
dans la zone pouce, sticky en bas de l'écran.
```

---

## 5. Rayons de bordure

```
──────────────────────────────────
TOKEN              VALEUR   USAGE
──────────────────────────────────
--radius-sm        6px      Chips, badges, small inputs
--radius-md        10px     Cartes, boutons, inputs
--radius-lg        14px     Bottom sheets, modales
--radius-full      9999px   Pills, tags arrondis
──────────────────────────────────
```

Pas de coins ronds géants (20px+). On reste net et technique.

---

## 6. Ombres & Élévation

Dark mode = les ombres classiques ne marchent pas. L'élévation est communiquée par la **luminosité du fond**.

```
──────────────────────────────────────────────
NIVEAU       DARK MODE               LIGHT MODE
──────────────────────────────────────────────
Base         --bg-primary (#0D0F12)  --bg-primary (#FAFBFC)
+1 (carte)   --bg-secondary (#161A1F) shadow: 0 1px 3px rgba(0,0,0,0.08)
+2 (input)   --bg-tertiary (#1E2328)  shadow: 0 2px 6px rgba(0,0,0,0.06)
+3 (modale)  --bg-elevated (#252A30)  shadow: 0 8px 24px rgba(0,0,0,0.12)
──────────────────────────────────────────────
```

Règle : en dark mode, **plus c'est élevé, plus c'est clair**. Jamais d'ombre portée en dark mode.

---

## 7. Iconographie

### Style

- **Outline** style, stroke 1.5px
- Taille par défaut : 20x20px
- Couleur : `--text-secondary` par défaut, `--accent-primary` si interactif
- Source : **Lucide Icons** (open source, cohérent, léger)

### Icônes custom requises

Le set Lucide couvre la plupart des besoins, mais certaines icônes sont spécifiques au domaine photo :

```
──────────────────────────────────────────────
ICÔNE               USAGE                     APPROCHE
──────────────────────────────────────────────
Diaphragme          Ouverture (f/stop)        Custom SVG (hexagone de lames)
Obturateur          Vitesse d'obturation      Custom SVG (rideau/curtain)
Capteur ISO         ISO                       Custom SVG ou Lucide "gauge"
Balance blancs      White balance             Lucide "thermometer"
Mise au point       Focus/AF                  Lucide "crosshair"
Mesure lumière      Mode mesure               Lucide "scan"
Molette             Contrôle physique         Custom SVG
Boîtier             Appareil photo            Lucide "camera"
Objectif            Lens                      Custom SVG (cercle + éléments)
──────────────────────────────────────────────
```

### Règles d'usage

- Les icônes **accompagnent** toujours du texte dans les listes et les menus. Jamais d'icône seule sans label (sauf la barre de nav).
- Dans les résultats de réglage, chaque réglage a son icône à gauche pour le scan visuel rapide.
- Icônes de navigation (←, ⚙️, etc.) : 24x24px.

---

## 8. Composants

### 8.1. Chip (Sélecteur de paramètre)

Le composant le plus utilisé de l'app — c'est comme ça qu'on décrit la scène.

```
État : Default
┌─────────────────┐
│   Paysage       │  bg: --chip-bg
│                 │  text: --chip-text
└─────────────────┘  border: 1px solid --border-default
                     radius: --radius-sm
                     padding: 8px 16px
                     font: --text-body-sm (13px), Outfit Medium

État : Selected
┌─────────────────┐
│   Paysage       │  bg: --chip-bg-active
│                 │  text: --chip-text-active
└─────────────────┘  border: 1px solid --chip-border-active
                     Transition: 150ms ease-out

État : Disabled
┌─────────────────┐
│   Paysage       │  bg: --chip-bg, opacity 0.4
│                 │  text: --text-tertiary
└─────────────────┘  Non interactif, tooltip au long press :
                     "Non disponible sur ton [boîtier]"
```

**Layout chips** : Flex wrap, gap 8px. Les chips s'adaptent à la largeur du texte (pas de largeur fixe). Sur une rangée complète, ils s'enroulent naturellement.

### 8.2. Bouton CTA (Call to Action)

```
État : Primary (CTA principal)
┌──────────────────────────────┐
│   Calculer mes réglages  →   │  bg: --accent-primary
│                              │  text: white
└──────────────────────────────┘  radius: --radius-md
                                  padding: 14px 24px
                                  font: Outfit Semi-Bold 15px
                                  width: 100% (full bleed dans le container)
                                  Position: sticky bottom
                                  Hauteur: 48px min

État : Primary Disabled
                                  bg: --accent-primary, opacity 0.35
                                  Non interactif

État : Secondary
┌──────────────────────────────┐
│   Modifier                   │  bg: transparent
│                              │  text: --accent-primary
└──────────────────────────────┘  border: 1px solid --accent-primary
                                  radius: --radius-md
                                  padding: 12px 20px

État : Ghost (action tertiaire)
┌──────────────────────────────┐
│   Plus tard                  │  bg: transparent
│                              │  text: --text-secondary
└──────────────────────────────┘  border: none
                                  padding: 12px 20px
```

**Règle** : Un seul CTA Primary par écran. Toujours en bas, dans la zone pouce.

### 8.3. Carte de réglage (Settings Card)

Le composant affiché dans la liste des résultats.

```
┌────────────────────────────────────────┐
│ ⊙  Ouverture                   f/2.8 ▸│
│    Flou d'arrière-plan max             │
└────────────────────────────────────────┘

Structure :
├── Icône (20px, --text-secondary)         gauche
├── Nom du réglage (Outfit Medium 15px)    gauche, après icône
├── Valeur (JetBrains Mono 17px,           droite
│           --text-primary, bold)
├── Chevron (▸, --text-tertiary)           extrême droite
└── Description courte (Outfit 13px,       sous le nom
    --text-secondary)

bg: --bg-secondary
padding: 14px 16px
radius: --radius-md
border-bottom: 1px solid --border-default (entre les cartes dans la liste)
Tap → navigation vers [Détail Réglage]
```

**Variante avec compromis :**

```
┌────────────────────────────────────────┐
│ ⊙  ISO                          3200 ▸│
│    Monté pour compenser la vitesse     │
│  ⚠ Compromis                          │
└────────────────────────────────────────┘

Le badge "⚠ Compromis" :
bg: --accent-secondary, opacity 0.15
text: --accent-secondary
font: Outfit Medium 11px
radius: --radius-full
padding: 2px 8px
```

### 8.4. Carte récap réglages (Hero Card)

Le bandeau en haut de l'écran résultats avec les 4 valeurs clés.

```
┌────────────────────────────────────────┐
│  MODE    OUVERT.   VITESSE     ISO     │
│   M       f/2.8    1/250s      200     │
└────────────────────────────────────────┘

bg: --bg-secondary
radius: --radius-md
padding: 16px
Layout: 4 colonnes égales, centré

Ligne 1 (labels):
  Outfit Medium 11px, --text-tertiary, uppercase, letter-spacing 0.5px

Ligne 2 (valeurs):
  JetBrains Mono 22px, --text-primary, font-weight 500
```

### 8.5. Étape de navigation menu (Menu Step)

```
Étape 2/3
┌────────────────────────────────────────┐
│  ❷  →  Exposition                      │
│                                   [▶]  │
└────────────────────────────────────────┘

Structure :
├── Numéro d'étape (cercle 24px, bg --accent-primary, texte blanc, Outfit Bold 13px)
├── Flèche → (--text-tertiary)
├── Nom du menu (Outfit Medium 15px, --text-primary)
│   bg inline: --bg-tertiary, padding 4px 10px, radius 4px
│   → Ce fond distingue les "vrais noms de menu" du texte explicatif
└── Icône chevron [▶] (--text-tertiary, indique "entrer dans ce sous-menu")

bg: --bg-secondary
padding: 14px 16px
radius: --radius-md
margin-bottom: 8px

Le nom du menu est stylistiquement distinct car c'est
EXACTEMENT ce que l'utilisateur va lire sur son écran d'appareil.
```

### 8.6. Section expandable (Accordion)

Utilisé pour Niveau 2, Niveau 3 du Scene Input, et les détails de réglages.

```
État : Collapsed
┌────────────────────────────────────────┐
│ ▼  Affiner davantage (optionnel)       │
└────────────────────────────────────────┘
text: --text-secondary
font: Outfit Medium 14px
padding: 12px 0
tap zone: full width

État : Expanded
┌────────────────────────────────────────┐
│ ▲  Affiner davantage                   │
│────────────────────────────────────────│
│  (contenu révélé)                      │
└────────────────────────────────────────┘
Animation : slide down, 200ms ease-out
Le chevron tourne de 180° (▼ → ▲)
```

### 8.7. Bandeau d'avertissement (Warning Banner)

```
┌────────────────────────────────────────┐
│ ⚠️  1 compromis effectué               │
│    Tap pour voir les détails           │
└────────────────────────────────────────┘

bg: rgba(--accent-secondary, 0.10)  (#F59E0B à 10%)
border-left: 3px solid --accent-secondary
text titre: Outfit Medium 14px, --accent-secondary
text sous-titre: Outfit 13px, --text-secondary
padding: 12px 16px
radius: --radius-md (coins droits à gauche à cause de la bordure)
Tap → action contextuelle
```

### 8.8. Barre de progression (Download)

```
┌────────────────────────────────────────┐
│ ████████████░░░░░░░░  67%              │
└────────────────────────────────────────┘

Track : --bg-tertiary, height 6px, radius --radius-full
Fill : --accent-primary, radius --radius-full
Pourcentage : JetBrains Mono 13px, --text-secondary
Animation : fill width transition 300ms ease-out
```

### 8.9. Dropdown (Sélecteur d'objectif)

```
┌──────────────────────────────────┐
│ 🔭 Sigma 18-50mm f/2.8      ▾   │
└──────────────────────────────────┘
   ┌──────────────────────────────┐
   │ Sigma 18-50mm f/2.8     ✓   │
   │ Sony E 55-210mm f/4.5-6.3   │
   │ Sony E 35mm f/1.8           │
   └──────────────────────────────┘

Trigger :
  bg: --bg-tertiary
  border: 1px solid --border-default
  radius: --radius-md
  padding: 10px 14px

Options panel :
  bg: --bg-elevated
  radius: --radius-md
  shadow (light mode only): 0 8px 24px rgba(0,0,0,0.12)
  Apparition: fade + slide down 150ms
  Option active: texte --accent-primary + checkmark
  Option hover/pressed: bg --bg-tertiary
```

### 8.10. Slider de contrainte

```
☐ ISO max : ──────●────── 3200

Checkbox :
  24x24, radius 4px
  Unchecked: border --border-default, bg transparent
  Checked: bg --accent-primary, icône check blanche

Track : --bg-tertiary, height 4px
Thumb : --accent-primary, 20px cercle, border 2px white
Valeur : JetBrains Mono 15px, --text-primary
Label : Outfit 13px, --text-secondary

Le slider est DÉSACTIVÉ visuellement tant que la checkbox n'est pas cochée.
Quand désactivé : opacity 0.3 sur tout le slider.
```

---

## 9. Navigation

### Pattern de navigation

L'app MVP n'a **pas de barre de navigation bottom tab**. Il n'y a pas assez de sections pour justifier une tab bar. La navigation est **hiérarchique (stack)** :

```
[Home] → [Scene Input] → [Résultats] → [Détail Réglage] → [Menu Navigation]
  │
  └→ [Settings] → [Sélection Boîtier/Objectif/Langue]
```

**Retour** : flèche ← en haut à gauche (standard iOS/Android). Swipe back (iOS) supporté nativement.

**Accès Settings** : icône ⚙️ en haut à droite du Home.

### Header

```
┌────────────────────────────────────────┐
│  ←  Titre écran                   ⚙️   │
└────────────────────────────────────────┘

Hauteur : 56px
bg : --bg-primary (transparent, se fond avec le contenu)
← : Lucide "chevron-left", 24px, tap zone 44x44px
Titre : Outfit Semi-Bold 17px, --text-primary, centré
Action droite : icône contextuelle, tap zone 44x44px
```

Le header est **pas sticky** sur les écrans avec du scroll (Scene Input, Résultats). Il scroll avec le contenu pour maximiser l'espace vertical. Exception : le CTA bottom reste sticky.

### Transitions

```
──────────────────────────────────────────────
TRANSITION               ANIMATION
──────────────────────────────────────────────
Push (→ écran suivant)    Slide from right, 250ms ease-out
Pop (← retour)            Slide to right, 200ms ease-out
Expand (section)          Height expand, 200ms ease-out
Modal (bottom sheet)      Slide from bottom, 300ms spring
Chip selection            bg + border color, 150ms ease-out
CTA press                 Scale 0.97, 100ms, + haptic light
──────────────────────────────────────────────
```

---

## 10. Comportements spécifiques

### 10.1. CTA sticky bottom

Sur les écrans scrollables (Scene Input), le CTA reste fixe en bas :

```
┌────────────────────────────────────────┐
│                                        │
│  (contenu scrollable)                  │
│                                        │
│                                        │
│════════════════════════════════════════│ ← gradient fade (--bg-primary → transparent, 24px)
│ ┌──────────────────────────────────┐   │
│ │   Calculer mes réglages  →       │   │
│ └──────────────────────────────────┘   │
│        safe area bottom                │
└────────────────────────────────────────┘

Le gradient empêche une coupure brutale entre le contenu
scrollable et le bouton fixe.
Padding bottom du CTA container : safe-area-inset-bottom + 16px
```

### 10.2. Labels de section (Scene Input)

```
TYPE DE SHOOT
─────────────

Outfit Medium 11px
--text-tertiary
uppercase
letter-spacing: 1px
margin-bottom: 8px
margin-top: 24px (entre sections)
```

### 10.3. Zone de recherche

```
┌────────────────────────────────────────┐
│  🔍  Recherche par nom...              │
└────────────────────────────────────────┘

bg: --bg-tertiary
border: 1px solid --border-default
border-focus: --border-focus
radius: --radius-md
padding: 12px 14px (avec 36px left pour l'icône)
font: Outfit 15px
placeholder: --text-tertiary
Icône 🔍 : Lucide "search", 18px, --text-tertiary
```

### 10.4. Feedback haptique

```
──────────────────────────────────────
ACTION               HAPTIC
──────────────────────────────────────
Tap chip             Light
Tap CTA              Medium
Calcul terminé       Success (notch)
Erreur               Error
Long press           Heavy (preview)
──────────────────────────────────────
```

### 10.5. Gestion du mode clair

Le switch dark/light suit le **réglage système** du téléphone. Pas de toggle dans l'app au MVP. Raison : un toggle de moins à maintenir, et 90% des photographes sont en dark mode.

---

## 11. Maquettes textuelles des écrans clés

### 11.1. Home

```
┌──────────────────────────────────────┐
│                                 ⚙️   │  Dark bg
│                                      │
│  ShootHelper                         │  Outfit Semi-Bold 20px
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 📷 Sony A6700                │    │  Carte gear
│  │ 🔭 Sigma 18-50mm f/2.8  [▾] │    │  bg-secondary
│  │ 🌐 Menus en Français        │    │
│  └──────────────────────────────┘    │
│                                      │
│                                      │
│                                      │
│                                      │
│  ┌──────────────────────────────┐    │
│  │     Nouveau shoot   →        │    │  CTA Primary
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

### 11.2. Scene Input (Niveau 1 + début Niveau 2)

```
┌──────────────────────────────────────┐
│  ←                                   │
│                                      │
│  Décris ta scène                     │  H1
│                                      │
│  TYPE DE SHOOT                       │  Section label
│  ┌────────┐  ┌────────┐             │
│  │▓ Photo ▓│  │ Vidéo  │             │  Chips (Photo selected)
│  └────────┘  └────────┘             │
│                                      │
│  ENVIRONNEMENT                       │
│  ┌──────────┐ ┌──────────┐          │
│  │▓Ext Jour▓│ │ Ext Nuit │          │
│  └──────────┘ └──────────┘          │
│  ┌──────────┐ ┌──────────┐          │
│  │ Int Clair│ │Int Sombre│          │
│  └──────────┘ └──────────┘          │
│  ┌──────────┐                       │
│  │  Studio  │                       │
│  └──────────┘                       │
│                                      │
│  SUJET                               │
│  ┌─────────┐ ┌─────────┐ ┌───────┐ │
│  │ Paysage │ │▓Portrait▓│ │ Street│ │  Horizontal scroll
│  └─────────┘ └─────────┘ └───────┘ │
│                                      │
│  INTENTION                           │
│  ┌───────────┐ ┌────────────────┐   │
│  │ Netteté   │ │▓Flou arrière  ▓│   │
│  └───────────┘ └────────────────┘   │
│  ┌────────────────┐ ┌────────────┐  │
│  │Figer mouvement │ │   Filé     │  │
│  └────────────────┘ └────────────┘  │
│                                      │
│  ▼ Affiner davantage (optionnel)     │  Accordion trigger
│                                      │
│ ═══════════════════════════════════  │  Gradient fade
│ ┌──────────────────────────────────┐ │
│ │   Calculer mes réglages   →      │ │  CTA Sticky
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### 11.3. Résultats

```
┌──────────────────────────────────────┐
│  ← Modifier                    📋   │
│                                      │
│  Tes réglages                        │  H1
│  Sony A6700 + Sigma 18-50mm         │  Caption
│  Portrait · Ext Jour · Flou arrière │  Caption
│                                      │
│  ┌──────────────────────────────┐    │  Hero Card
│  │ MODE   OUVERT  VITESSE  ISO │    │
│  │  M     f/2.8   1/250s   200 │    │  JetBrains Mono
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ ⊙ Mode exposition       M  ▸│    │  Settings Card
│  │   Mode manuel recommandé     │    │
│  ├──────────────────────────────┤    │
│  │ ⊙ Ouverture          f/2.8 ▸│    │
│  │   Flou d'arrière-plan max   │    │
│  ├──────────────────────────────┤    │
│  │ ⊙ Vitesse          1/250s  ▸│    │
│  │   Fige le sujet, safe main   │    │
│  │   levée à 50mm               │    │
│  ├──────────────────────────────┤    │
│  │ ⊙ ISO                 200  ▸│    │
│  │   ISO natif, zéro bruit      │    │
│  ├──────────────────────────────┤    │
│  │ ⊙ Balance blancs    5500K  ▸│    │
│  │   Lumière du jour standard   │    │
│  ├──────────────────────────────┤    │
│  │ ⊙ Mode AF            AF-C  ▸│    │
│  │   Suivi continu du sujet     │    │
│  ├──────────────────────────────┤    │
│  │ ⊙ Zone AF          Eye-AF  ▸│    │
│  │   Détection visage/yeux      │    │
│  ├──────────────────────────────┤    │
│  │ ...                          │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │  Warning Banner
│  │ ⚠️ 1 compromis effectué      │    │  (si applicable)
│  │   Tap pour voir les détails  │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

---

## 12. Motion & Animation

### Principes

- Les animations sont **fonctionnelles**, pas décoratives. Elles guident l'œil et confirment les actions.
- Durées courtes : 100-300ms max. L'utilisateur est sur le terrain, pas dans un onboarding.
- Easing : `ease-out` pour les entrées, `ease-in` pour les sorties.
- **Aucune animation bloquante** — l'UI reste interactive pendant les transitions.

### Animations spécifiques

```
──────────────────────────────────────────────────────────
ÉLÉMENT                    ANIMATION
──────────────────────────────────────────────────────────
Chip selection             bg-color 150ms ease-out
                           border-color 150ms ease-out

Calcul → Résultats         1. Écran slide in (250ms)
                           2. Hero Card fade in (200ms, delay 100ms)
                           3. Settings Cards stagger in
                              (fade + translateY 12px, 200ms each,
                               30ms stagger entre chaque)

Accordion expand           height auto → mesurée, 200ms ease-out
                           opacity 0→1, 150ms ease-out
                           chevron rotate 180°, 200ms

Menu step reveal           Chaque étape apparaît séquentiellement
                           (delay 100ms entre chaque)
                           fade + translateX 8px, 200ms ease-out

Download progress          Width transition 300ms ease-out
                           Pulse subtil sur le pourcentage
                           quand un composant termine : scale 1.05
                           + color flash --accent-success, 300ms

Warning banner             Slide in from top, 300ms spring
                           Border-left wipe effect (0→3px, 200ms)

CTA press                  Scale 0.97, 80ms ease-out
                           Release: scale 1.0, 120ms spring
──────────────────────────────────────────────────────────
```

---

## 13. Accessibilité

### Cibles minimales

- **Taille de tap** : 44x44px minimum (Apple HIG). Même si le composant visuel est plus petit, la zone de tap est 44px.
- **Contraste** : WCAG AA (4.5:1 texte, 3:1 UI). Vérifié sur les combinaisons principales.
- **Taille texte** : Respecte le Dynamic Type (iOS) / font scale (Android). L'app ne casse pas si l'utilisateur est en taille XL.
- **Screen reader** : Chaque composant a un label accessible. Les valeurs de réglage sont lues : "Ouverture : f 2 point 8" (pas "f slash 2 point 8").

### Labels pour screen reader

```
Settings Card :
  accessibilityLabel: "Ouverture, f/2.8. Flou d'arrière-plan maximum. Appuyez pour plus de détails."

Chip :
  accessibilityLabel: "Portrait. Sélectionné." / "Portrait. Non sélectionné."
  accessibilityRole: "button"

Hero Card :
  accessibilityLabel: "Résumé des réglages. Mode Manuel. Ouverture f/2.8. Vitesse 1/250ème de seconde. ISO 200."

Menu Step :
  accessibilityLabel: "Étape 2 sur 3. Aller dans le menu Exposition."
```

---

## 14. Design Tokens — Récapitulatif export

Tous les tokens dans un format exploitable pour l'implémentation :

```json
{
  "color": {
    "dark": {
      "bg-primary": "#0D0F12",
      "bg-secondary": "#161A1F",
      "bg-tertiary": "#1E2328",
      "bg-elevated": "#252A30",
      "text-primary": "#F0F2F4",
      "text-secondary": "#8B929A",
      "text-tertiary": "#555D66",
      "accent-primary": "#3B82F6",
      "accent-primary-hover": "#2563EB",
      "accent-secondary": "#F59E0B",
      "accent-success": "#10B981",
      "accent-danger": "#EF4444",
      "border-default": "#2A3038",
      "border-focus": "#3B82F6",
      "chip-bg": "#1E2328",
      "chip-bg-active": "#1E3A5F",
      "chip-text": "#8B929A",
      "chip-text-active": "#3B82F6",
      "chip-border-active": "#3B82F6"
    },
    "light": {
      "bg-primary": "#FAFBFC",
      "bg-secondary": "#FFFFFF",
      "bg-tertiary": "#F0F2F5",
      "bg-elevated": "#FFFFFF",
      "text-primary": "#111318",
      "text-secondary": "#5F6773",
      "text-tertiary": "#9CA3AD",
      "accent-primary": "#2563EB",
      "accent-secondary": "#D97706"
    }
  },
  "typography": {
    "font-display": "JetBrains Mono",
    "font-heading": "Outfit",
    "font-body": "Outfit",
    "font-caption": "Outfit"
  },
  "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 12,
    "lg": 16,
    "xl": 24,
    "2xl": 32,
    "3xl": 48
  },
  "radius": {
    "sm": 6,
    "md": 10,
    "lg": 14,
    "full": 9999
  }
}
```

---

## 15. Inventaire des écrans (Checklist)

Liste de tous les écrans à designer, tracés au PRD et aux User Flows :

```
──────────────────────────────────────────────────────────
#    ÉCRAN                         FLOW   COMPOSANTS CLÉS
──────────────────────────────────────────────────────────
01   Splash                        F1     Logo, loading
02   Welcome                       F1     Texte, CTA primary
03   Sélection Boîtier             F1     Search, liste par marque, items
04   Boîtier Non Supporté          F1     Input texte, CTA
05   Sélection Objectif            F1     Search, checkboxes, CTA
06   Langue Firmware               F1     Radio list, CTA
07   Récap & Téléchargement        F1     Carte récap, CTA, taille download
08   Download en cours             F2     Progress bar, checklist états
09   Erreur Download               F2     Message, CTA retry
10   Home                          F3     Carte gear, dropdown objectif, CTA
11   Scene Input (L1+L2+L3)       F3     Chips, accordions, sliders, CTA sticky
12   Résultats                     F3     Hero card, settings cards, warning
13   Détail Réglage                F4     Valeur héro, texte, accordion, CTA
14   Menu Navigation               F5     Méthode rapide, steps, astuces
15   Settings App                  F6     Liste settings, infos data
16   Changement Langue             F7     Radio list, warning, CTA
17   Mise à jour disponible        F8     Changelog, CTA
──────────────────────────────────────────────────────────
                              Total : 17 écrans uniques
```

---

*Ce document est la source de vérité pour toute décision visuelle et d'interaction. Aucun composant ne doit être implémenté sans référence à ce design system. Il sera complété par les mockups haute fidélité lors du skill Frontend Design.*
