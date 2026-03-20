# CLAUDE.md — Contexte ShootHelper

## Le projet
ShootHelper est une app mobile Flutter qui recommande les réglages photo/vidéo
optimaux et guide l'utilisateur dans les menus de son appareil.

## Architecture
- Clean Architecture 3 couches : Domain / Data / Presentation
- Feature-first (lib/features/*)
- State management : Riverpod 2.x avec code generation
- Navigation : GoRouter
- Stockage : JSON fichiers (data packs) + SharedPreferences (profil gear)

## Conventions
- Entities : immutables via Freezed
- Value objects : FStop, ShutterSpeed, IsoValue (types forts)
- Models : suffixe Model (BodyModel), avec json_serializable
- Mappers : suffixe Mapper (BodyMapper), dans data/mappers/
- Use cases : une classe = une action (CalculateSettings, ResolveMenuPath)
- Providers : camelCase + Provider suffix
- Tests : mirrorent lib/, dans test/

## Règles strictes
- Domain n'importe JAMAIS Flutter, Data, ou packages I/O
- Aucun import cross-feature (features/X ne peut pas importer features/Y)
- Le state éphémère (toggle, search field) va dans le widget, PAS dans Riverpod
- ref.watch dans build(), ref.read dans callbacks, ref.listen pour side effects

## Skills de référence
Les 22 skills de design sont dans le dossier docs/skills/.
Chaque skill est un document de référence pour une partie du projet.
Les plus importants pour le code :
- 06_SETTINGS_ENGINE.md → Algorithmes du moteur
- 09_APP_ARCHITECTURE.md → Structure et patterns
- 10_MODULE_FEATURE_ARCHITECTURE.md → Dossiers et imports
- 11_STATE_MANAGEMENT.md → Riverpod providers
- 19_MENU_NAVIGATION_MAPPER.md → Killer feature

## Phase actuelle
V2-01 : Design System & Identité Visuelle

## Ce qui est fait — MVP (Phases 0-7)
- ☑ Phase 0 : Bootstrap
- ☑ Phase 1 : Moteur (Settings Engine, Dart pur) — 37 tests
- ☑ Phase 2 : Données (JSON data packs + parsing) — 94 tests
- ☑ Phase 3 : Flow principal UI — 119 tests
- ☑ Phase 4 : Onboarding & Download — 133 tests
- ☑ Phase 5 : Error handling & polish — 181 tests
- ☑ Phase 6 : Data entry supplémentaire — 205 tests
- ☑ Phase 7 : Tests & Release — 255 tests, 80.2% global / 95% engine

## V2 Roadmap — Post-MVP
Ref : V2_SKILLS_ROADMAP.md (à la racine shoothelper/)
Ordre : V2-01 → V2-04 → V2-02 → V2-03 → V2-05 → V2-06 → V2-07 → V2-08 → V2-09 → V2-10

### V2-01 — Design System & Identité Visuelle (P0 Fondation)
☐ app_colors.dart — palette complète (dark/light, sémantique, photo EV)
☐ app_spacing.dart — constantes spacing (xs=4, sm=8, md=12, base=16, lg=20, xl=24, 2xl=32, 3xl=48)
☐ app_typography.dart — TextStyles (Inter + JetBrains Mono, tabulaires)
☐ Ajouter google_fonts + lucide_icons dans pubspec.yaml
☐ app_theme.dart complet — ThemeData light + dark (Material 3, CardTheme, ChipTheme, etc.)
☐ ShootChip — chip custom (default, selected, suggested, disabled) avec icône optionnelle
☐ SettingCard — card réglage (icône | nom+explication | valeur | chevron) + variante compromised/overridden
☐ SummaryHeader — résumé exposition (4 valeurs Display, fond dégradé, badge confiance)
☐ NavStepCard — étape menu (numéro cercle, texte, variante dernière étape highlight)
☐ SectionDivider — séparateur avec label optionnel centré
☐ ExpandToggle — toggle expand/collapse avec badge compteur + animation rotation
☐ BottomStickyBar — barre sticky bottom avec CTA, fond blur + ombre
☐ GearBadge — badge compact "A6700 + Sigma 18-50" avec icônes, tapable
☐ ConfidenceBadge — pastille colorée (vert/orange/rouge) + texte
☐ CompromiseBanner — bandeau alerte (fond coloré, icône, texte, chevron)
☐ Storybook screen — écran debug affichant tous les composants
☐ Tests widgets pour chaque composant
☐ Commit V2-01

### V2-04 — Gear Database Import (P0 Data)
☐ opd_importer.py — importe bodies depuis OPD YAML → body.json
☐ lensfun_importer.py — importe lenses depuis Lensfun XML → lens.json
☐ Champ "support_level" ("full" | "basic") dans BodySpec + BodyModel + body.json
☐ catalog_extended.json — catalogue étendu avec bodies OPD
☐ Script mise à jour : pull OPD + Lensfun → rebuild catalog
☐ UI : badge "Full support" vs "Basic" dans le sélecteur body
☐ UI : message "Guide menu non disponible" pour bodies basic
☐ Engine fonctionne avec bodies "basic" (specs only, pas de menus)
☐ Tests import pipeline
☐ Commit V2-04

### V2-02 — Refonte UI Écrans (P0 Gros du travail)
☐ Home Screen refait avec design system (GearBadge, dernier shoot, astuce)
☐ Scene Input refait (ShootChip, fonds de section, BottomStickyBar blur)
☐ Results Screen refait (SummaryHeader dégradé, SettingCard avec icônes, CompromiseBanner sticky)
☐ Setting Detail Screen refait (typo Display, hero transition)
☐ Menu Navigation Screen refait (timeline verticale, NavStepCard, JetBrains Mono breadcrumb)
☐ Settings Screen refait (cards gear, barre stockage)
☐ Onboarding screens refaits avec design system
☐ Download screen refait (progress animé)
☐ Tests widgets mis à jour
☐ Commit V2-02

### V2-03 — Thème Clair / Sombre (P1)
☐ ThemeData light complet (tous composants, testable en plein soleil)
☐ ThemeData dark complet (pas éblouissant la nuit)
☐ Zéro couleur hardcodée — tout via Theme.of(context)
☐ ThemeModeNotifier (Riverpod, keepAlive) — Système / Clair / Sombre
☐ Persistance du choix (SharedPreferences, clé theme_mode)
☐ Toggle dans Settings (3 options)
☐ Tests
☐ Commit V2-03

### V2-05 — Multi-gear avancée (P1)
☐ GearProfile avec nom customisable
☐ Multi-profils stockés (Drift SQLite ou SharedPreferences JSON)
☐ UI Home : sélecteur de profil (swipe ou dropdown)
☐ UI Home : sélecteur objectif rapide
☐ Bottom sheet changement de boîtier
☐ Écran "Objectifs compatibles" avec filtres (type, ouverture, focale)
☐ Recalcul automatique quand switch de gear
☐ Tests
☐ Commit V2-05

### V2-06 — Filtres optiques ND/CPL (P1)
☐ Entité OpticalFilter (ND, ND variable, CPL, UV) via Freezed
☐ Stockage filtres utilisateur
☐ UI gestion filtres dans Settings
☐ UI sélection filtre actif dans Scene Input (Niveau 2)
☐ Engine : ND dans calcul exposition (EV - stops)
☐ Engine : CPL perte lumière (1.5-2 stops)
☐ Engine : recommandation proactive ND quand surexposition
☐ Engine : recommandation proactive CPL pour paysage eau/verre
☐ Explications + tips spécifiques filtres
☐ Tests
☐ Commit V2-06

### V2-07 — Scene Input étendu (P1)
☐ 14 nouveaux subjects (concert, food, real_estate, aurora, lightning, fireworks, underwater, wedding, event, drone_aerial, self_portrait, pet, night_cityscape, star_trails)
☐ 7 nouvelles conditions lumière (mixed_lighting, backlit, harsh_midday, diffused, candlelight, stage_lighting, moonlight)
☐ 6 nouvelles intentions (hdr_dynamic_range, long_exposure, panning, high_speed_sync, documentary, minimalist_noise)
☐ Tables EV pour nouvelles conditions
☐ Arbres de décision moteur étendus par nouveau sujet
☐ Explications i18n
☐ Au moins 1 scénario test par nouveau sujet
☐ Commit V2-07

### V2-08 — Animations & Micro-interactions (P2)
☐ Hero animation Results → Detail (valeur du réglage)
☐ Chip selection animation (outlined → filled, 200ms)
☐ Expand/collapse avec CurvedAnimation + rotation flèche
☐ Staggered animation pour étapes Menu Nav
☐ Haptic feedback interactions clés
☐ Toutes animations < 300ms
☐ AnimationController dispose correct (pas de memory leak)
☐ Commit V2-08

### V2-09 — Onboarding interactif (P2)
☐ Étape 4 "Essaie maintenant" — scénario guidé portrait sunset
☐ Highlights animés sur les chips pendant tutoriel
☐ Système tooltips contextuels (première fois uniquement, flags SharedPreferences)
☐ Skip possible à chaque étape
☐ Commit V2-09

### V2-10 — Historique, Favoris & Presets (P2)
☐ Migration SQLite (Drift) — schéma history + presets
☐ HistoryDao : save, getRecent, getFavorites, toggleFavorite, delete
☐ PresetDao : save, getAll, delete, update
☐ Auto-save après chaque calcul
☐ Écran Historique (liste chronologique)
☐ Écran Favoris (filtre)
☐ "Sauvegarder comme preset" flow
☐ Home : section presets rapides (horizontal scroll)
☐ Home : section historique récent (3 derniers)
☐ Nettoyage auto historique > 500 entrées
☐ Tests
☐ Commit V2-10