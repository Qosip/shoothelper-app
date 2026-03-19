# User Flows — ShootHelper

> **Skill 02/22** · Parcours utilisateur
> Version 1.0 · Mars 2026
> Réf : 01_PRD.md

---

## Sommaire des flows

| # | Flow | Déclencheur | Fréquence |
|---|------|-------------|-----------|
| F1 | Premier lancement & Onboarding | Installation de l'app | Une seule fois |
| F2 | Téléchargement Data Pack | Après sélection gear ou ajout gear | Rare |
| F3 | Flow principal : Scène → Réglages | Depuis l'écran d'accueil | À chaque shoot (usage core) |
| F4 | Exploration d'un réglage | Depuis l'écran résultats | Fréquent |
| F5 | Navigation menu appareil | Depuis un réglage | Fréquent (killer feature) |
| F6 | Gestion du gear | Depuis les settings de l'app | Occasionnel |
| F7 | Changement de langue firmware | Depuis les settings de l'app | Très rare |
| F8 | Mise à jour Data Pack | Notification ou settings | Rare |

---

## Conventions de notation

```
[Écran]           → Un écran / une vue de l'app
{Action}          → Une action utilisateur (tap, swipe, saisie)
→                 → Transition vers l'écran suivant
⟳                 → Retour / boucle
⚡                → Traitement automatique (pas d'interaction)
⚠️                → Cas d'erreur / edge case
💾                → Écriture en base locale
🌐                → Nécessite une connexion réseau
```

---

## F1 · Premier lancement & Onboarding

**Objectif** : En 4 écrans max, l'utilisateur a un profil gear complet et les données téléchargées. Il peut commencer à utiliser l'app.

**Principe UX** : Pas de compte, pas d'email, pas de tuto de 10 slides. On va droit au but — l'onboarding *est* utile parce qu'il configure le gear.

```
[Splash Screen]
  ⚡ Check : premier lancement ? (pas de profil gear en local)
  │
  ├─ OUI → [Écran Welcome]
  │         Titre : "Configure ton matériel"
  │         Sous-titre : "2 minutes pour que l'app connaisse ton appareil"
  │         CTA : "C'est parti"
  │         {Tap CTA}
  │         → [Écran Sélection Boîtier] (voir ci-dessous)
  │
  └─ NON → [Home] (F3)
```

### Écran Sélection Boîtier

```
[Sélection Boîtier]
  ┌──────────────────────────────────────┐
  │ Quel est ton boîtier ?               │
  │                                      │
  │ 🔍 [Recherche par nom...]            │
  │                                      │
  │ ── Sony ──────────────────────       │
  │   A6700  ·  A6400  ·  A7 IV          │
  │   A7C II                             │
  │ ── Canon ─────────────────────       │
  │   R50  ·  R10  ·  R7                 │
  │   R6 Mark II                         │
  │ ── Nikon ─────────────────────       │
  │   Z50 II  ·  Z30  ·  Zf             │
  │   Z6 III                             │
  │ ── Fujifilm ──────────────────       │
  │   X-T5  ·  X-S20                     │
  │                                      │
  │ Mon boîtier n'est pas listé →        │
  └──────────────────────────────────────┘

  {Tap sur un boîtier}
  → 💾 Sauvegarde boîtier sélectionné
  → [Écran Sélection Objectif]

  {Tap "Mon boîtier n'est pas listé"}
  → [Écran Boîtier Non Supporté]
    Message : "On ajoute régulièrement de nouveaux boîtiers.
              Dis-nous lequel tu utilises pour qu'on le priorise."
    [Champ texte : marque + modèle]
    CTA : "Envoyer" (stocke localement, envoi au backend quand online)
    CTA secondaire : "Continuer sans boîtier" → ❌ Bloqué.
    L'app ne fonctionne pas sans boîtier. Afficher :
    "L'app a besoin de connaître ton boîtier pour te guider
     dans ses menus. On te notifiera quand il sera supporté."
    CTA : "OK, compris"
    → Retour [Sélection Boîtier]
```

### Écran Sélection Objectif

```
[Sélection Objectif]
  ┌──────────────────────────────────────┐
  │ Quel(s) objectif(s) utilises-tu ?    │
  │ Boîtier : Sony A6700 ✓              │
  │                                      │
  │ 🔍 [Recherche...]                    │
  │                                      │
  │ Monture E (APS-C & Full Frame)       │
  │                                      │
  │ ☐ Sony E 16-50mm f/3.5-5.6 OSS      │
  │ ☐ Sony E 55-210mm f/4.5-6.3 OSS     │
  │ ☐ Sony E 35mm f/1.8 OSS             │
  │ ☐ Sony FE 50mm f/1.8                │
  │ ☐ Sony E 18-135mm f/3.5-5.6 OSS     │
  │ ☐ Sony E 10-18mm f/4 OSS            │
  │ ...                                  │
  │                                      │
  │ Mon objectif n'est pas listé →       │
  │                                      │
  │ [Continuer avec X objectif(s)] ──→   │
  └──────────────────────────────────────┘

  Comportement :
  - Multi-sélection (checkbox)
  - Filtrés par monture compatible avec le boîtier
  - Minimum 1 objectif requis
  - L'ordre d'affichage priorise les kits les plus vendus avec ce boîtier

  {Sélection ≥ 1 objectif + tap "Continuer"}
  → 💾 Sauvegarde objectif(s) sélectionné(s)
  → [Écran Langue Firmware]

  {Tap "Mon objectif n'est pas listé"}
  → Même pattern que boîtier non supporté
  → Mais l'utilisateur PEUT continuer sans cet objectif
    s'il en a sélectionné au moins 1 autre
```

### Écran Langue Firmware

```
[Langue Firmware]
  ┌──────────────────────────────────────┐
  │ Dans quelle langue sont les menus    │
  │ de ton appareil ?                    │
  │                                      │
  │ C'est la langue affichée quand tu    │
  │ navigues dans les menus de ton       │
  │ Sony A6700.                          │
  │                                      │
  │ ○ Français                           │
  │ ○ English                            │
  │ ○ Deutsch                            │
  │ ○ Español                            │
  │ ○ Italiano                           │
  │ ○ 日本語                              │
  │ ...                                  │
  │ (liste = langues supportées par le   │
  │  firmware de CE boîtier spécifique)  │
  │                                      │
  │ [Continuer] ──→                      │
  └──────────────────────────────────────┘

  Important : la liste est dynamique. Chaque boîtier supporte
  un set différent de langues. On n'affiche que celles du modèle
  sélectionné.

  {Sélection langue + tap "Continuer"}
  → 💾 Sauvegarde langue firmware
  → [Écran Récap & Téléchargement]
```

### Écran Récap & Téléchargement

```
[Récap & Téléchargement]
  ┌──────────────────────────────────────┐
  │ Ton setup                            │
  │                                      │
  │ 📷 Sony A6700                        │
  │ 🔭 Sigma 18-50mm f/2.8              │
  │ 🌐 Menus en Français                 │
  │                                      │
  │ ✏️ Modifier                           │
  │                                      │
  │ On va télécharger les données de     │
  │ ton matériel (~2.3 MB). Après ça,    │
  │ l'app fonctionne 100% hors ligne.    │
  │                                      │
  │ [Télécharger et commencer] ──→  🌐   │
  └──────────────────────────────────────┘

  {Tap "Modifier"}
  → ⟳ Retour [Sélection Boîtier] avec valeurs pré-remplies

  {Tap "Télécharger et commencer"}
  → Flow F2 (Téléchargement Data Pack)
  → Après succès → [Home]
```

---

## F2 · Téléchargement Data Pack

**Objectif** : Télécharger toutes les données nécessaires pour que le flow principal fonctionne offline.

```
[Download en cours]
  ┌──────────────────────────────────────┐
  │                                      │
  │ Téléchargement en cours...           │
  │                                      │
  │ ████████████░░░░░░░  67%             │
  │                                      │
  │ ✅ Specs Sony A6700                   │
  │ ✅ Arbre menus (Français)             │
  │ ⏳ Données Sigma 18-50mm f/2.8       │
  │ ○ Moteur de réglages                 │
  │                                      │
  └──────────────────────────────────────┘

  Composants téléchargés :
  1. Specs boîtier (ISO range, modes, capteur, etc.)
  2. Arbre de menus complet dans la langue sélectionnée
  3. Raccourcis physiques (boutons, molettes)
  4. Specs objectif(s) (ouverture, focale, stabilisation, etc.)
  5. Règles du moteur de settings (si pas déjà embarquées)

  ⚡ Succès
  → 💾 Stockage local complet
  → [Home]

  ⚠️ Échec réseau
  → [Écran Erreur Download]
    Message : "Pas de connexion. Le téléchargement reprendra
              automatiquement quand tu seras en ligne."
    CTA : "Réessayer"
    CTA secondaire : "Continuer" → ❌ Bloqué si c'est le premier setup.
    L'app ne peut pas fonctionner sans data pack.
    → Si c'est un ajout de gear (pas premier setup),
      "Continuer" ramène au [Home] avec le gear existant.

  ⚠️ Échec partiel (1 objectif sur 3 échoue)
  → Téléchargement partiel sauvegardé
  → Notification : "Données du [objectif] manquantes.
     Tu peux l'utiliser mais sans guidage menu."
  → CTA "Réessayer" pour le composant manquant
```

---

## F3 · Flow principal : Scène → Réglages

**C'est LE flow. 80% du temps passé dans l'app est ici.**

**Objectif** : L'utilisateur décrit sa scène, reçoit ses réglages en < 3 secondes (calcul local), les applique sur son appareil.

### Écran Home

```
[Home]
  ┌──────────────────────────────────────┐
  │ ShootHelper                    ⚙️    │
  │                                      │
  │ 📷 Sony A6700                        │
  │ 🔭 Sigma 18-50mm f/2.8        [✏️]  │
  │                                      │
  │                                      │
  │       ┌─────────────────────┐        │
  │       │                     │        │
  │       │   Nouveau shoot     │        │
  │       │                     │        │
  │       └─────────────────────┘        │
  │                                      │
  │                                      │
  │ Si multi-objectifs :                 │
  │ Objectif actif : [Sigma 18-50 ▼]    │
  │ (dropdown pour switcher)             │
  │                                      │
  └──────────────────────────────────────┘

  {Tap ⚙️}       → [Settings App] (F6, F7)
  {Tap ✏️ gear}   → [Gestion Gear] (F6)
  {Tap objectif ▼} → Dropdown : liste des objectifs configurés
                     {Sélection} → 💾 Switch objectif actif
  {Tap "Nouveau shoot"} → [Scene Input — Niveau 1]
```

### Scene Input — Niveau 1 (Obligatoire)

```
[Scene Input — Niveau 1]
  ┌──────────────────────────────────────┐
  │ ← Retour                            │
  │                                      │
  │ Décris ta scène                      │
  │                                      │
  │ TYPE DE SHOOT                        │
  │ ┌────────┐  ┌────────┐              │
  │ │ 📷     │  │ 🎥     │              │
  │ │ Photo  │  │ Vidéo  │              │
  │ └────────┘  └────────┘              │
  │                                      │
  │ ENVIRONNEMENT                        │
  │ ┌──────────┐ ┌──────────┐           │
  │ │ Ext Jour │ │ Ext Nuit │           │
  │ └──────────┘ └──────────┘           │
  │ ┌──────────┐ ┌──────────┐           │
  │ │ Int Clair│ │Int Sombre│           │
  │ └──────────┘ └──────────┘           │
  │ ┌──────────┐                        │
  │ │  Studio  │                        │
  │ └──────────┘                        │
  │                                      │
  │ SUJET                                │
  │ (chips horizontaux scrollables)      │
  │ [Paysage] [Portrait] [Street]       │
  │ [Architecture] [Macro] [Astro]      │
  │ [Sport/Action] [Animalier] [Produit]│
  │                                      │
  │ INTENTION                            │
  │ (chips, sélection unique)            │
  │ [Netteté max] [Flou arrière-plan]   │
  │ [Figer mouvement] [Filé mouvement]  │
  │ [Low-light perf]                    │
  │                                      │
  │ ┌──────────────────────────────┐     │
  │ │  Calculer mes réglages  →    │     │
  │ └──────────────────────────────┘     │
  │                                      │
  │ ▼ Affiner davantage (optionnel)      │
  │                                      │
  └──────────────────────────────────────┘

  Validation :
  - Les 4 paramètres sont OBLIGATOIRES
  - Sélection unique par catégorie (sauf Sujet : unique aussi)
  - Le CTA "Calculer" est disabled tant que les 4 ne sont pas remplis
  - Feedback visuel immédiat (chip sélectionné = couleur active)

  {Tap "Calculer mes réglages"}
  → ⚡ Moteur de calcul (local, < 500ms)
  → [Écran Résultats] (voir plus bas)

  {Tap "Affiner davantage"}
  → Expand/révèle [Scene Input — Niveau 2]
  → Scroll vers le bas, le Niveau 1 reste visible au-dessus
```

### Scene Input — Niveau 2 (Optionnel)

```
[Scene Input — Niveau 2] (section expandable sous Niveau 1)
  ┌──────────────────────────────────────┐
  │                                      │
  │ ▲ Affiner davantage                  │
  │                                      │
  │ CONDITIONS DE LUMIÈRE                │
  │ [Soleil direct] [Ombre] [Couvert]   │
  │ [Golden hour] [Blue hour]           │
  │ [Nuit étoilée] [Néon] [Tungstène]  │
  │ [LED]                               │
  │                                      │
  │ MOUVEMENT DU SUJET                   │
  │ [Immobile] [Lent] [Rapide]          │
  │ [Très rapide]                       │
  │                                      │
  │ DISTANCE DU SUJET                    │
  │ [< 50cm] [1-3m] [3-10m]            │
  │ [> 10m] [Infini]                    │
  │                                      │
  │ MOOD / RENDU SOUHAITÉ               │
  │ [Dramatique] [Doux/pastel]          │
  │ [High contrast] [Naturel]           │
  │ [Silhouette]                        │
  │                                      │
  │ SUPPORT                              │
  │ [Main levée] [Trépied]             │
  │ [Monopode] [Gimbal]                │
  │                                      │
  │ CONTRAINTES                          │
  │ ☐ ISO max : [slider 100 — 51200]    │
  │ ☐ Vitesse min : [slider 1/8000 — 30s]│
  │                                      │
  │ ▼ Paramètres avancés                 │
  │                                      │
  │ ┌──────────────────────────────┐     │
  │ │  Calculer mes réglages  →    │     │
  │ └──────────────────────────────┘     │
  │                                      │
  └──────────────────────────────────────┘

  - Tous les champs sont OPTIONNELS
  - Le CTA "Calculer" est toujours accessible (scroll sticky en bas)
  - Chaque champ non rempli = le moteur utilise la valeur optimale par défaut
  - Les sliders de contraintes ne sont actifs que si la checkbox est cochée
```

### Scene Input — Niveau 3 (Avancé)

```
[Scene Input — Niveau 3] (section expandable sous Niveau 2)
  ┌──────────────────────────────────────┐
  │                                      │
  │ ▲ Paramètres avancés                 │
  │                                      │
  │ TEMPÉRATURE COULEUR                  │
  │ ○ Auto                               │
  │ ○ Preset : [Lumière du jour]         │
  │            [Nuageux] [Ombre]         │
  │            [Tungstène] [Fluorescent] │
  │ ○ Manuel : [slider 2500K — 10000K]   │
  │                                      │
  │ PROFONDEUR DE CHAMP                  │
  │ [Shallow] [Medium] [Deep]           │
  │ ☐ Préciser en mètres :              │
  │   Début zone nette : [___] m         │
  │   Fin zone nette : [___] m           │
  │                                      │
  │ ZONE AF                              │
  │ [Centre] [Zone large] [Suivi]       │
  │ [Eye-AF]                            │
  │                                      │
  │ BRACKETING                           │
  │ [Aucun] [Exposition] [Focus]        │
  │                                      │
  │ FORMAT FICHIER                       │
  │ [RAW] [JPEG] [RAW+JPEG]            │
  │                                      │
  │ ┌──────────────────────────────┐     │
  │ │  Calculer mes réglages  →    │     │
  │ └──────────────────────────────┘     │
  │                                      │
  └──────────────────────────────────────┘

  Note : les options du Niveau 3 qui sont renseignées OVERRIDENT
  le calcul automatique du moteur. Par exemple si l'utilisateur
  force "Zone AF = Eye-AF", le moteur ne recalculera pas la zone AF
  mais vérifiera la compatibilité avec le boîtier et avertira si
  Eye-AF n'est pas dispo dans le mode choisi.
```

### Écran Résultats

```
[Résultats]
  ┌──────────────────────────────────────┐
  │ ← Modifier la scène          📋     │
  │                                      │
  │ TES RÉGLAGES                         │
  │ Sony A6700 + Sigma 18-50mm f/2.8     │
  │ Portrait · Ext Jour · Flou arrière   │
  │                                      │
  │ ┌────────────────────────────────┐   │
  │ │ MODE   OUVERT.  VITESSE  ISO  │   │
  │ │  M      f/2.8   1/250s   200  │   │
  │ └────────────────────────────────┘   │
  │                                      │
  │ ── Tous les réglages ──────────      │
  │                                      │
  │ ┌────────────────────────────────┐   │
  │ │ Mode exposition          M    │ ▶  │
  │ │ Ouverture              f/2.8  │ ▶  │
  │ │ Vitesse            1/250s     │ ▶  │
  │ │ ISO                    200    │ ▶  │
  │ │ Balance blancs    5500K       │ ▶  │
  │ │ Mode AF            AF-C       │ ▶  │
  │ │ Zone AF         Eye-AF        │ ▶  │
  │ │ Mesure       Matricielle      │ ▶  │
  │ │ Comp. expo        0.0         │ ▶  │
  │ │ Format          RAW           │ ▶  │
  │ │ Stabilisation    ON           │ ▶  │
  │ └────────────────────────────────┘   │
  │                                      │
  │ ⚠️ 1 compromis effectué              │
  │ (tap pour voir les détails)          │
  │                                      │
  └──────────────────────────────────────┘

  {Tap sur un réglage (▶)}
  → [Détail Réglage] (F4)

  {Tap 📋}
  → Copie texte de tous les réglages (presse-papier)

  {Tap "← Modifier la scène"}
  → ⟳ Retour [Scene Input] avec valeurs conservées

  {Tap bandeau compromis}
  → Scroll vers / highlight le réglage concerné
  → Ouvre directement le [Détail Réglage] avec la section
    compromis visible
```

---

## F4 · Exploration d'un réglage

**Objectif** : Comprendre *pourquoi* ce réglage, et apprendre.

```
[Détail Réglage]
  ┌──────────────────────────────────────┐
  │ ← Résultats                          │
  │                                      │
  │ OUVERTURE                            │
  │ ┌──────────────┐                     │
  │ │    f/2.8     │                     │
  │ └──────────────┘                     │
  │                                      │
  │ EXPLICATION                          │
  │ Ouverture grande ouverte (f/2.8)     │
  │ pour maximiser le flou d'arrière-    │
  │ plan sur ton portrait. C'est         │
  │ l'ouverture max de ton Sigma         │
  │ 18-50mm.                             │
  │                                      │
  │ ▼ Comprendre en détail               │
  │ ┌────────────────────────────────┐   │
  │ │ À f/2.8, la profondeur de      │   │
  │ │ champ est d'environ 30cm à     │   │
  │ │ 3m de distance (à 50mm).       │   │
  │ │                                │   │
  │ │ Si tu passes à f/4 :           │   │
  │ │ → PDC ~45cm (plus de netteté   │   │
  │ │   en profondeur)               │   │
  │ │ → Moins de flou d'arrière-plan │   │
  │ │ → Tu devras compenser :        │   │
  │ │   monter ISO à 400 OU baisser  │   │
  │ │   vitesse à 1/125s             │   │
  │ │                                │   │
  │ │ Si tu passes à f/2.0 :         │   │
  │ │ → Ton objectif ne descend pas  │   │
  │ │   en dessous de f/2.8          │   │
  │ └────────────────────────────────┘   │
  │                                      │
  │ ⚠️ COMPROMIS (si applicable)         │
  │ ┌────────────────────────────────┐   │
  │ │ ISO monté à 800 pour maintenir │   │
  │ │ 1/250s main levée.             │   │
  │ │ Alternative : passer à 1/125s  │   │
  │ │ → ISO 400 (moins de bruit)     │   │
  │ └────────────────────────────────┘   │
  │                                      │
  │ ┌──────────────────────────────┐     │
  │ │  📍 Où régler sur mon A6700   │     │
  │ └──────────────────────────────┘     │
  │                                      │
  └──────────────────────────────────────┘

  {Tap "Comprendre en détail"}
  → Expand de la section détaillée (toggle)

  {Tap "Où régler sur mon A6700"}
  → [Menu Navigation] (F5) pour CE réglage spécifique
```

---

## F5 · Navigation menu appareil (Killer Feature)

**Objectif** : Guider l'utilisateur physiquement dans les menus de son appareil pour appliquer un réglage.

```
[Menu Navigation]
  ┌──────────────────────────────────────┐
  │ ← Retour                            │
  │                                      │
  │ RÉGLER : Ouverture → f/2.8          │
  │ Sony A6700 · Menus en Français       │
  │                                      │
  │ ── MÉTHODE RAPIDE ──────────────     │
  │                                      │
  │ 🎛️ En mode M, tourne la molette     │
  │    arrière (derrière le déclencheur) │
  │    jusqu'à afficher f/2.8            │
  │                                      │
  │ ── VIA LE MENU ─────────────────     │
  │                                      │
  │ Étape 1/3                            │
  │ ┌────────────────────────────────┐   │
  │ │ 📱 Appuie sur MENU             │   │
  │ │                                │   │
  │ │ ❶ → Exposition/Couleur        │   │
  │ │                         [▶]   │   │
  │ └────────────────────────────────┘   │
  │                                      │
  │ Étape 2/3                            │
  │ ┌────────────────────────────────┐   │
  │ │ ❷ → Exposition                 │   │
  │ │                         [▶]   │   │
  │ └────────────────────────────────┘   │
  │                                      │
  │ Étape 3/3                            │
  │ ┌────────────────────────────────┐   │
  │ │ ❸ → Ouverture                  │   │
  │ │   Tourne la molette ou         │   │
  │ │   utilise les flèches ◀▶       │   │
  │ │   pour sélectionner f/2.8      │   │
  │ └────────────────────────────────┘   │
  │                                      │
  │ 💡 Astuce                            │
  │ Tu peux assigner l'ouverture à la    │
  │ touche C1 pour un accès direct.      │
  │ Menu > Réglage > Opération perso.    │
  │ > Régl. Touche perso. > Touche C1    │
  │                                      │
  └──────────────────────────────────────┘

  Structure de chaque étape :
  - Numéro d'étape + profondeur dans l'arbre
  - Nom exact du menu TEL QU'AFFICHÉ sur l'appareil
  - Dans la langue firmware sélectionnée
  - Indication de l'action physique (bouton, molette, flèche)

  Si le réglage n'est pas accessible via le menu
  (ex : vitesse d'obturation = molette uniquement en mode M) :
  → Afficher uniquement la "Méthode rapide"
  → Pas de section "Via le menu"

  Si le réglage a un raccourci physique ET un chemin menu :
  → Afficher les deux, "Méthode rapide" en premier
```

---

## F6 · Gestion du gear

**Objectif** : Modifier son setup (changer de boîtier, ajouter/supprimer un objectif).

```
[Home] → {Tap ⚙️} → [Settings App]

[Settings App]
  ┌──────────────────────────────────────┐
  │ ← Retour                            │
  │                                      │
  │ RÉGLAGES                             │
  │                                      │
  │ ── Mon matériel ────────────────     │
  │ 📷 Sony A6700                   [▶]  │
  │ 🔭 Sigma 18-50mm f/2.8         [▶]  │
  │ 🌐 Menus en Français            [▶]  │
  │                                      │
  │ [+ Ajouter un objectif]             │
  │ [Changer de boîtier]                │
  │                                      │
  │ ── Données ─────────────────────     │
  │ Espace utilisé : 2.3 MB             │
  │ Dernière MAJ : 15 mars 2026         │
  │ [Vérifier les mises à jour]    🌐   │
  │                                      │
  │ ── À propos ────────────────────     │
  │ Version 1.0.0                        │
  │ [Signaler un problème]              │
  │                                      │
  └──────────────────────────────────────┘

  {Tap "Ajouter un objectif"}
  → [Sélection Objectif] (même écran que F1, filtré par monture)
  → Après sélection → Téléchargement incrémental data pack (F2)
  → Retour [Settings]

  {Tap "Changer de boîtier"}
  → ⚠️ Confirmation : "Changer de boîtier supprimera les données
     de ton Sony A6700 et de ses objectifs incompatibles.
     Continuer ?"
  → [OUI] → [Sélection Boîtier] → full re-setup (objectifs + langue)
            → Re-téléchargement data pack complet
  → [NON] → ⟳ Retour [Settings]

  {Tap sur un objectif existant}
  → [Détail Objectif]
    Infos : nom, focale, ouverture, stabilisation
    CTA : "Supprimer cet objectif"
    → Confirmation → Supprime les données locales de cet objectif
    → Minimum 1 objectif requis (bouton disabled si c'est le dernier)
```

---

## F7 · Changement de langue firmware

```
[Settings] → {Tap 🌐 Langue firmware}

[Changement Langue]
  ┌──────────────────────────────────────┐
  │ ← Retour                            │
  │                                      │
  │ Langue des menus de ton appareil     │
  │                                      │
  │ Actuelle : Français ✓                │
  │                                      │
  │ ○ English                            │
  │ ○ Deutsch                            │
  │ ○ Español                            │
  │ ...                                  │
  │                                      │
  │ ⚠️ Changer la langue va télécharger   │
  │ un nouveau jeu de données pour les   │
  │ chemins de menus (~0.5 MB).          │
  │                                      │
  │ [Changer la langue]             🌐   │
  │                                      │
  └──────────────────────────────────────┘

  {Tap "Changer la langue"}
  → Téléchargement données menus dans la nouvelle langue
  → 💾 Remplacement des données locales
  → Les chemins de menu sont immédiatement dans la nouvelle langue
  → ⟳ Retour [Settings] avec confirmation
```

---

## F8 · Mise à jour Data Pack

**Objectif** : Quand un firmware update modifie les menus ou qu'on corrige des erreurs dans les données.

```
Deux déclencheurs possibles :

A) L'utilisateur vérifie manuellement
   [Settings] → {Tap "Vérifier les mises à jour"} → 🌐

B) Check automatique au lancement (si online)
   [Splash] → ⚡ Check version data pack → notification silencieuse

[Mise à jour disponible]
  ┌──────────────────────────────────────┐
  │                                      │
  │ 🔄 Mise à jour disponible            │
  │                                      │
  │ Sony A6700                           │
  │ v1.0 → v1.1                          │
  │                                      │
  │ Changements :                        │
  │ · Correction chemin menu AF en FR    │
  │ · Ajout firmware 3.0 (nouveaux       │
  │   menus Creative Look)               │
  │                                      │
  │ Taille : 0.8 MB                      │
  │                                      │
  │ [Mettre à jour maintenant]     🌐    │
  │ [Plus tard]                          │
  │                                      │
  └──────────────────────────────────────┘

  {Tap "Mettre à jour"}
  → Téléchargement différentiel (pas full re-download)
  → 💾 Mise à jour données locales
  → L'app continue de fonctionner avec les anciennes données
    pendant le téléchargement (pas de blocage)

  {Tap "Plus tard"}
  → Badge discret sur ⚙️ dans le [Home]
  → Reminder dans 7 jours
```

---

## Carte des écrans (Sitemap)

```
[Splash]
  ├── Premier lancement → [Welcome] → [Sélection Boîtier]
  │     → [Sélection Objectif] → [Langue Firmware]
  │     → [Récap & Téléchargement] → [Download] → [Home]
  │
  └── Lancement normal → [Home]
        │
        ├── {Nouveau shoot} → [Scene Input L1]
        │     ├── {Affiner} → [Scene Input L2]
        │     │     └── {Avancé} → [Scene Input L3]
        │     │
        │     └── {Calculer} → [Résultats]
        │           ├── {Tap réglage} → [Détail Réglage]
        │           │     └── {Où régler} → [Menu Navigation]
        │           ├── {Copier} → Presse-papier
        │           └── {Modifier scène} → ⟳ [Scene Input]
        │
        ├── {Switch objectif} → Dropdown inline
        │
        └── {⚙️ Settings} → [Settings App]
              ├── {Ajouter objectif} → [Sélection Objectif] → [Download]
              ├── {Changer boîtier} → [Sélection Boîtier] → full re-setup
              ├── {Changer langue} → [Changement Langue] → [Download]
              ├── {MAJ data pack} → [Mise à jour]
              └── {Signaler problème} → Formulaire local
```

---

## Edge Cases & Comportements spéciaux

### EC1 : Combinaison scène impossible

```
Cas : L'utilisateur demande Astro + Main levée + Netteté maximale
Le moteur ne peut pas satisfaire les 3 simultanément.

→ [Résultats] affichés avec bandeau :
  ⚠️ "Cette combinaison est très difficile. Voici le meilleur
  compromis possible, mais un trépied améliorerait beaucoup
  le résultat."
  → Les réglages sont quand même calculés (meilleur effort)
  → L'explication détaillée de chaque réglage indique
    quel paramètre souffre du compromis
```

### EC2 : Fonctionnalité non supportée par le boîtier

```
Cas : L'utilisateur sélectionne Eye-AF en Niveau 3
      mais son boîtier (ex: A6400) a un Eye-AF limité

→ Dans [Résultats], le réglage Eye-AF affiche :
  ⚠️ "Eye-AF disponible uniquement en AF-C sur ton A6400.
  Le moteur a automatiquement basculé en AF-C."

Cas extrême : la feature n'existe pas du tout sur le boîtier
→ Le chip est grisé dans [Scene Input L3] avec tooltip :
  "Non disponible sur ton [boîtier]"
```

### EC3 : Objectif incompatible avec la demande

```
Cas : L'utilisateur veut Macro (distance < 50cm)
      mais son objectif a une distance minimale de mise au point de 1.2m

→ [Résultats] avec bandeau :
  ⚠️ "Ton Sigma 18-50mm a une distance min de MAP de 12.5cm
  (à 18mm) à 30cm (à 50mm). À cette distance, utilise
  la focale 18mm pour la MAP la plus proche possible."
```

### EC4 : App lancée offline sans data pack (jamais configurée)

```
[Splash] → Pas de profil gear → [Welcome]
{Tap "C'est parti"} → [Sélection Boîtier]
L'utilisateur sélectionne un boîtier → [Sélection Objectif] → ...
→ [Récap & Téléchargement] → {Tap Télécharger}
→ ⚠️ Pas de réseau

[Écran Offline Setup]
  "Tu as besoin d'une connexion internet pour le premier
   setup. Après ça, l'app fonctionne 100% offline."
  CTA : "Réessayer"
  → L'app ne peut pas fonctionner. Pas de workaround.
```

### EC5 : Changement d'objectif en plein flow

```
[Home] → L'utilisateur a déjà rempli une scène précédemment
→ {Switch objectif via dropdown}
→ Si des résultats sont en cache :
  Notification : "Objectif changé. Les réglages précédents
  ne sont plus valables."
  CTA : "Recalculer avec [nouvel objectif]"
  → ⚡ Recalcul automatique avec les mêmes paramètres de scène
  → [Résultats] mis à jour
```

---

*Ce document est la référence pour les skills UI/UX Design System (03), Scene Input System (17), Settings Output (18), et Menu Navigation Mapper (19). Chaque écran décrit ici doit se retrouver dans le design system et dans l'implémentation.*
