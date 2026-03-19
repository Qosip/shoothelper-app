# Menu Navigation Mapper — ShootHelper

> **Skill 19/22** · Le killer feature. Chemin exact dans les menus, dans ta langue.
> Version 1.0 · Mars 2026
> Réf : 04_CAMERA_DATA_ARCHITECTURE.md, 07_I18N_MENU_LOCALIZATION.md, 18_SETTINGS_OUTPUT_EXPLANATIONS.md

---

## 1. Pourquoi c'est LE différenciateur

Aucune app photo existante ne fait ça. PhotoPills te dit "utilise f/2.8" mais ne te dit pas **où trouver** ce réglage dans les menus de ton appareil. Les tutos YouTube sont pour un boîtier précis dans une langue précise. Les manuels PDF font 500 pages.

ShootHelper prend un réglage recommandé (`af_mode: af-c`) et affiche :

```
📍 Mode AF → AF-C (AF continu)
Sony A6700 · Menus en Français

MÉTHODE RAPIDE
🎛️ Appuie sur Fn > Sélectionne « Mode mise au point » > AF continu

VIA LE MENU
❶ Appuie sur MENU
❷ → AF/MF
❸ → Régl. AF/MF
❹ → Mode mise au point > AF continu (AF-C)

💡 Tu peux assigner le mode de mise au point au bouton C1
   pour un accès plus rapide.
   Menu > Réglage > Opération perso. > Régl. Touche perso. > Touche C1
```

Chaque mot entre guillemets est le **texte exact** affiché sur l'écran du boîtier, dans la langue du firmware. Si l'appareil est en allemand, tout est en allemand. Si c'est en japonais, tout est en japonais.

---

## 2. Pipeline de résolution complet

```
┌─────────────────────────────────────────────────────────────────┐
│                  PIPELINE MENU NAVIGATION                       │
│                                                                 │
│  INPUT                                                          │
│  ┌──────────────────────────────────────────────┐              │
│  │ setting_id : "af_mode"                       │              │
│  │ value      : "af-c"                          │              │
│  │ body_id    : "sony_a6700"                    │              │
│  │ fw_lang    : "fr"                            │              │
│  │ app_lang   : "fr"                            │              │
│  └──────────────────────┬───────────────────────┘              │
│                         │                                       │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────┐              │
│  │ ÉTAPE 1 : Lookup NavPath                     │              │
│  │ nav_paths.json → find(body_id, setting_id)   │              │
│  │ → SettingNavPath                             │              │
│  └──────────────────────┬───────────────────────┘              │
│                         │                                       │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────┐              │
│  │ ÉTAPE 2 : Résoudre les accès rapides          │              │
│  │ dial_access → labels[app_lang] + dial label   │              │
│  │ quick_access → steps avec labels              │              │
│  └──────────────────────┬───────────────────────┘              │
│                         │                                       │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────┐              │
│  │ ÉTAPE 3 : Construire le chemin menu           │              │
│  │ menu_path IDs → MenuTree traversal            │              │
│  │ → labels[fw_lang] à chaque nœud              │              │
│  │ → breadcrumb localisé                        │              │
│  └──────────────────────┬───────────────────────┘              │
│                         │                                       │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────┐              │
│  │ ÉTAPE 4 : Résoudre la valeur cible            │              │
│  │ value "af-c" → MenuItem.values → find(id)    │              │
│  │ → labels[fw_lang] = "AF continu"             │              │
│  │ → short_labels[fw_lang] = "AF-C"             │              │
│  └──────────────────────┬───────────────────────┘              │
│                         │                                       │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────┐              │
│  │ ÉTAPE 5 : Résoudre les tips                   │              │
│  │ tips[].labels[app_lang]                      │              │
│  │ tips[].related_menu_path → breadcrumb fw_lang│              │
│  └──────────────────────┬───────────────────────┘              │
│                         │                                       │
│                         ▼                                       │
│  OUTPUT                                                         │
│  ┌──────────────────────────────────────────────┐              │
│  │ MenuNavDisplay                               │              │
│  │ → header, sections[], tips[]                 │              │
│  └──────────────────────────────────────────────┘              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Structure de sortie (MenuNavDisplay)

```dart
// features/menu_nav/domain/entities/menu_nav_display.dart

@freezed
class MenuNavDisplay with _$MenuNavDisplay {
  const factory MenuNavDisplay({
    /// "Mode AF → AF-C (AF continu)"
    required String header,

    /// "Sony A6700 · Menus en Français"
    required String subheader,

    /// Sections d'accès (dial, Fn, menu) — dans l'ordre de priorité
    required List<NavSection> sections,

    /// Astuces contextuelles
    required List<NavTip> tips,

    /// true si aucun chemin n'a été trouvé (fallback)
    required bool isIncomplete,
  }) = _MenuNavDisplay;
}

@freezed
class NavSection with _$NavSection {
  /// Accès rapide (molette ou Fn)
  const factory NavSection.quick({
    required String title,          // "Méthode rapide"
    required String instruction,    // "En mode M, tourne la molette avant..."
    String? dialName,               // "Molette avant" (firmware lang)
    String? conditionLabel,         // "En mode M" (app lang)
  }) = NavSectionQuick;

  /// Accès Fn / Q Menu (multi-étapes)
  const factory NavSection.fnMenu({
    required String title,          // "Via le menu Fn"
    required List<NavStep> steps,
  }) = NavSectionFnMenu;

  /// Accès via le menu complet
  const factory NavSection.fullMenu({
    required String title,          // "Via le menu"
    required String pressMenuLabel, // "Appuie sur MENU"
    required List<NavStep> steps,   // Étapes dans l'arbre
    required NavStep finalStep,     // Sélection de la valeur
  }) = NavSectionFullMenu;
}

@freezed
class NavStep with _$NavStep {
  const factory NavStep({
    required int stepNumber,
    required int totalSteps,
    required String label,          // Nom du menu (firmware lang)
    String? actionHint,             // "Navigue avec les flèches ◀▶" (app lang)
    NavStepPosition? position,      // Indicateur de position dans le menu
  }) = _NavStep;
}

@freezed
class NavStepPosition with _$NavStepPosition {
  const factory NavStepPosition({
    required int tabIndex,          // Onglet (1-based pour l'affichage)
    int? pageIndex,                 // Page dans l'onglet
    int? itemIndex,                 // Position dans la page
  }) = _NavStepPosition;
}

@freezed
class NavTip with _$NavTip {
  const factory NavTip({
    required String text,           // Le tip (app lang)
    String? relatedPath,            // Chemin menu lié (firmware lang), optionnel
  }) = _NavTip;
}
```

---

## 4. Use Case : ResolveMenuPath

```dart
// features/menu_nav/domain/use_cases/resolve_menu_path.dart

class ResolveMenuPath {
  final GearRepository _gearRepo;

  ResolveMenuPath({required GearRepository gearRepo}) : _gearRepo = gearRepo;

  Future<MenuNavDisplay> execute({
    required String bodyId,
    required String settingId,
    required dynamic value,
    required String firmwareLanguage,
    required String appLanguage,
    required AppLocalizations l10n,
  }) async {
    final body = await _gearRepo.getBody(bodyId);
    final navPath = await _gearRepo.getNavPath(bodyId, settingId);

    // ─── Cas : NavPath introuvable ───
    if (navPath == null) {
      return MenuNavDisplay(
        header: _buildHeader(settingId, value, null, null, firmwareLanguage),
        subheader: _buildSubheader(body, firmwareLanguage, l10n),
        sections: [],
        tips: [],
        isIncomplete: true,
      );
    }

    final menuTree = body.menuTree;
    final sections = <NavSection>[];

    // ─── ÉTAPE 2 : Accès molette ───
    if (navPath.dialAccess != null) {
      final dial = navPath.dialAccess!;
      final dialControl = body.controls.dials
          .firstWhereOrNull((d) => d.id == dial.dialId);

      final dialName = dialControl != null
          ? _resolveLabel(dialControl.label, firmwareLanguage)
          : dial.dialId;

      final conditionLabel = dial.exposureMode != null
          ? l10n.navInMode(mode: dial.exposureMode!)
          : null;

      sections.add(NavSection.quick(
        title: l10n.navQuickMethod,
        instruction: _resolveLabel(dial.labels, appLanguage),
        dialName: dialName,
        conditionLabel: conditionLabel,
      ));
    }

    // ─── ÉTAPE 2b : Accès Fn / Q Menu ───
    if (navPath.quickAccess != null) {
      final qa = navPath.quickAccess!;
      final steps = qa.steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;

        String targetLabel;
        if (step.target == 'fn_button' || step.target == 'q_button') {
          final button = body.controls.buttons
              .firstWhereOrNull((b) => b.id == step.target);
          targetLabel = button != null
              ? _resolveLabel(button.label, firmwareLanguage)
              : step.target.toUpperCase();
        } else {
          final menuItem = _findMenuItem(menuTree, step.target);
          targetLabel = menuItem != null
              ? _resolveLabel(menuItem.labels, firmwareLanguage)
              : step.target;
        }

        return NavStep(
          stepNumber: i + 1,
          totalSteps: qa.steps.length,
          label: targetLabel,
          actionHint: _resolveLabel(step.labels, appLanguage),
        );
      }).toList();

      sections.add(NavSection.fnMenu(
        title: l10n.navViaFnMenu,
        steps: steps,
      ));
    }

    // ─── ÉTAPE 3 : Chemin menu complet ───
    if (navPath.menuPath != null && navPath.menuPath!.isNotEmpty) {
      final menuSteps = <NavStep>[];
      final pathIds = navPath.menuPath!;

      for (var i = 0; i < pathIds.length; i++) {
        final nodeId = pathIds[i];
        final menuItem = _findMenuItem(menuTree, nodeId);

        if (menuItem == null) {
          // Nœud introuvable — fallback avec l'ID brut
          AppLogger.warning('MenuItem not found: $nodeId', tag: 'MenuNav');
          menuSteps.add(NavStep(
            stepNumber: i + 1,
            totalSteps: pathIds.length + 1,
            label: nodeId,
          ));
          continue;
        }

        final label = _resolveLabel(menuItem.labels, firmwareLanguage);

        menuSteps.add(NavStep(
          stepNumber: i + 1,
          totalSteps: pathIds.length + 1,
          label: label,
          position: NavStepPosition(
            tabIndex: menuItem.tabIndex + 1,  // 1-based pour l'affichage
            pageIndex: menuItem.pageIndex,
            itemIndex: menuItem.itemIndex,
          ),
        ));
      }

      // Étape finale : sélection de la valeur
      final targetMenuItem = navPath.menuItemId != null
          ? _findMenuItem(menuTree, navPath.menuItemId!)
          : null;

      final settingLabel = targetMenuItem != null
          ? _resolveLabel(targetMenuItem.labels, firmwareLanguage)
          : settingId;

      final valueLabel = _resolveValueLabel(
        targetMenuItem, value.toString(), firmwareLanguage,
      );

      final valueShort = _resolveValueShortLabel(
        targetMenuItem, value.toString(), firmwareLanguage,
      );

      final finalLabel = valueShort != valueLabel
          ? '$settingLabel > $valueLabel ($valueShort)'
          : '$settingLabel > $valueLabel';

      final finalStep = NavStep(
        stepNumber: pathIds.length + 1,
        totalSteps: pathIds.length + 1,
        label: finalLabel,
        actionHint: _buildFinalActionHint(settingId, l10n),
      );

      sections.add(NavSection.fullMenu(
        title: l10n.navViaMenu,
        pressMenuLabel: l10n.navPressMenu,
        steps: menuSteps,
        finalStep: finalStep,
      ));
    }

    // ─── ÉTAPE 5 : Tips ───
    final tips = navPath.tips?.map((tip) {
      final text = _resolveLabel(tip.labels, appLanguage);

      String? relatedPath;
      if (tip.relatedMenuPath != null) {
        relatedPath = tip.relatedMenuPath!.map((id) {
          final item = _findMenuItem(menuTree, id);
          return item != null
              ? _resolveLabel(item.labels, firmwareLanguage)
              : id;
        }).join(' > ');
      }

      return NavTip(text: text, relatedPath: relatedPath);
    }).toList() ?? [];

    // ─── Assemblage ───
    return MenuNavDisplay(
      header: _buildHeader(settingId, value, targetMenuItem, navPath, firmwareLanguage),
      subheader: _buildSubheader(body, firmwareLanguage, l10n),
      sections: sections,
      tips: tips,
      isIncomplete: sections.isEmpty,
    );
  }

  // ─── Helpers ───

  String _buildHeader(
    String settingId,
    dynamic value,
    MenuItem? menuItem,
    SettingNavPath? navPath,
    String fwLang,
  ) {
    final settingLabel = menuItem != null
        ? _resolveLabel(menuItem.labels, fwLang)
        : settingId;

    final valueShort = menuItem != null
        ? _resolveValueShortLabel(menuItem, value.toString(), fwLang)
        : value.toString();

    final valueFull = menuItem != null
        ? _resolveValueLabel(menuItem, value.toString(), fwLang)
        : value.toString();

    if (valueShort != valueFull) {
      return '$settingLabel → $valueShort ($valueFull)';
    }
    return '$settingLabel → $valueShort';
  }

  String _buildSubheader(Body body, String fwLang, AppLocalizations l10n) {
    final langName = _languageDisplayName(fwLang);
    return '${body.displayName} · ${l10n.navMenusIn(language: langName)}';
  }

  String _resolveLabel(Map<String, String> labels, String lang) {
    return labels[lang] ?? labels['en'] ?? labels.values.first;
  }

  String _resolveValueLabel(MenuItem? item, String valueId, String fwLang) {
    if (item == null || item.values == null) return valueId;
    final v = item.values!.firstWhereOrNull((v) => v.id == valueId);
    if (v == null) return valueId;
    return _resolveLabel(v.labels, fwLang);
  }

  String _resolveValueShortLabel(MenuItem? item, String valueId, String fwLang) {
    if (item == null || item.values == null) return valueId;
    final v = item.values!.firstWhereOrNull((v) => v.id == valueId);
    if (v == null) return valueId;
    if (v.shortLabels != null) return _resolveLabel(v.shortLabels!, fwLang);
    return _resolveLabel(v.labels, fwLang);
  }

  MenuItem? _findMenuItem(MenuTree tree, String itemId) {
    return _findInChildren(tree.root, itemId);
  }

  MenuItem? _findInChildren(List<MenuItem> items, String targetId) {
    for (final item in items) {
      if (item.id == targetId) return item;
      if (item.children != null) {
        final found = _findInChildren(item.children!, targetId);
        if (found != null) return found;
      }
    }
    return null;
  }

  String _buildFinalActionHint(String settingId, AppLocalizations l10n) {
    return switch (settingId) {
      'aperture' || 'shutter_speed' || 'iso' =>
        l10n.navUseDialOrArrows,
      'af_mode' || 'af_area' || 'metering_mode' || 'white_balance_mode' ||
      'file_format' || 'drive_mode' =>
        l10n.navSelectWithOk,
      'stabilization_body' =>
        l10n.navToggleOnOff,
      'exposure_compensation' =>
        l10n.navUseDialToAdjust,
      _ => l10n.navSelectWithOk,
    };
  }

  String _languageDisplayName(String code) => switch (code) {
    'fr' => 'Français',
    'en' => 'English',
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

---

## 5. Exemples de résolution réels

### 5.1. Sony A6700 — Mode AF → AF-C (FR)

**Données d'entrée :**
```
setting_id: "af_mode"
value: "af-c"
body_id: "sony_a6700"
fw_lang: "fr"
```

**NavPath :**
```json
{
  "menu_path": ["af_mf", "af_mf_settings", "focus_mode"],
  "menu_item_id": "focus_mode",
  "quick_access": {
    "method": "fn_menu",
    "steps": [
      { "action": "press", "target": "fn_button", "labels": { "fr": "Appuie sur Fn" } },
      { "action": "navigate", "target": "focus_mode", "labels": { "fr": "Sélectionne Mode mise au point" } }
    ]
  },
  "dial_access": null,
  "tips": [{ "labels": { "fr": "Tu peux assigner le mode de mise au point au bouton C1." }, "related_menu_path": ["setup", "operation_custom", "custom_key", "c1"] }]
}
```

**Résolution MenuTree (FR) :**
```
"af_mf"          → labels.fr = "AF/MF"
"af_mf_settings" → labels.fr = "Régl. AF/MF"
"focus_mode"     → labels.fr = "Mode mise au point"
  value "af-c"   → labels.fr = "AF continu"
                    short_labels.fr = "AF-C"
```

**Résultat affiché :**
```
📍 Mode mise au point → AF-C (AF continu)
Sony A6700 · Menus en Français

VIA LE MENU FN
❶ Appuie sur Fn
❷ Sélectionne « Mode mise au point » > AF continu (AF-C)

VIA LE MENU
❶ Appuie sur MENU
❷ → AF/MF
❸ → Régl. AF/MF
❹ → Mode mise au point > AF continu (AF-C)
     Sélectionne avec OK

💡 Tu peux assigner le mode de mise au point au bouton C1.
   Menu > Réglage > Opération perso. > Régl. Touche perso. > Touche C1
```

### 5.2. Sony A6700 — Ouverture → f/2.8 (FR)

**NavPath :**
```json
{
  "menu_path": null,
  "menu_item_id": null,
  "quick_access": null,
  "dial_access": {
    "exposure_mode": "M",
    "dial_id": "front_dial",
    "labels": { "fr": "En mode M, tourne la molette avant pour régler l'ouverture." }
  },
  "tips": [{ "labels": { "fr": "En mode A, la molette avant contrôle aussi l'ouverture." } }]
}
```

**Résultat affiché :**
```
📍 Ouverture → f/2.8
Sony A6700 · Menus en Français

MÉTHODE RAPIDE
🎛️ En mode M, tourne la molette avant pour régler l'ouverture.
   Molette avant (devant la poignée)

💡 En mode A, la molette avant contrôle aussi l'ouverture.
```

Pas de section "Via le menu" — l'ouverture n'est pas accessible via le menu sur un Sony.

### 5.3. Canon R50 — Mode AF → Servo AF (DE)

**Même concept (`af_mode:af-c`) mais boîtier et langue différents.**

**Résolution MenuTree (DE) :**
```
"af"             → labels.de = "AF"
"af_operation"   → labels.de = "AF-Betrieb"
"af_mode"        → labels.de = "AF-Betrieb"
  value "af-c"   → labels.de = "Servo AF"
                    short_labels.de = "SERVO"
```

**Résultat affiché :**
```
📍 AF-Betrieb → SERVO (Servo AF)
Canon R50 · Menüs auf Deutsch

VIA DAS MENÜ
❶ Drücke MENU
❷ → AF (Onglet 1)
❸ → AF-Betrieb > Servo AF
     Mit SET bestätigen

💡 Im AI Focus-Modus wechselt die Kamera automatisch
   zwischen One-Shot und Servo.
```

Le même concept universel, résolu différemment pour chaque boîtier et chaque langue. C'est la puissance du système.

### 5.4. Nikon Zf — Balance blancs → Nuageux (JA)

**Résolution MenuTree (JA) :**
```
"photo_shooting"    → labels.ja = "静止画撮影"
"white_balance"     → labels.ja = "ホワイトバランス"
  value "cloudy"    → labels.ja = "くもり"
                       short_labels.ja = "☁"
```

**Résultat affiché :**
```
📍 ホワイトバランス → ☁ (くもり)
Nikon Zf · メニュー言語：日本語

ショートカット
🎛️ iボタン > ホワイトバランス > くもり

メニューから
❶ MENUボタンを押す
❷ → 静止画撮影
❸ → ホワイトバランス > くもり
     OKボタンで決定
```

---

## 6. Ordre de priorité des sections

L'écran affiche les sections d'accès dans un ordre précis — du plus rapide au plus long. L'utilisateur voit d'abord la méthode la plus efficace.

```
PRIORITÉ D'AFFICHAGE :

1. Accès molette (dial_access)
   → Le plus rapide : un geste physique, pas de menu
   → "En mode M, tourne la molette avant"

2. Accès Fn / Q Menu (quick_access)
   → Rapide : 2-3 taps
   → "Fn > Mode mise au point > AF continu"

3. Accès menu complet (menu_path)
   → Le plus long : navigation dans l'arbre
   → "MENU > AF/MF > Régl. AF/MF > Mode mise au point"

Si les 3 existent → afficher les 3, dans cet ordre
Si seulement molette → afficher uniquement la molette
Si seulement menu → afficher uniquement le menu
Si aucun → afficher "Chemin non documenté" (fallback, skill 15 B4)
```

---

## 7. Widgets

### 7.1. MenuNavigationScreen

```dart
// features/menu_nav/presentation/screens/menu_navigation_screen.dart

class MenuNavigationScreen extends ConsumerWidget {
  final String settingId;

  const MenuNavigationScreen({required this.settingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(settingsResultProvider).valueOrNull;
    final body = ref.watch(currentBodyProvider);
    final fwLang = ref.watch(firmwareLanguageProvider).valueOrNull ?? 'en';
    final setting = result?.settings.firstWhereOrNull((s) => s.settingId == settingId);

    if (setting == null || body == null) {
      return const Scaffold(body: ErrorDisplay(failure: UnknownFailure()));
    }

    final menuNavAsync = ref.watch(menuNavDisplayProvider(
      MenuNavParams(
        bodyId: body.id,
        settingId: settingId,
        value: setting.value,
        firmwareLanguage: fwLang,
      ),
    ));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navTitle)),
      body: menuNavAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => ErrorDisplay(failure: _mapFailure(e)),
        data: (display) => _MenuNavContent(display: display),
      ),
    );
  }
}

class _MenuNavContent extends StatelessWidget {
  final MenuNavDisplay display;

  const _MenuNavContent({required this.display});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _NavHeader(
            header: display.header,
            subheader: display.subheader,
          ),
          const SizedBox(height: 24),

          // Sections
          if (display.isIncomplete)
            _IncompleteNotice()
          else
            ...display.sections.map((section) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildSection(section, context),
            )),

          // Tips
          if (display.tips.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            ...display.tips.map((tip) => _TipCard(tip: tip)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(NavSection section, BuildContext context) {
    return switch (section) {
      NavSectionQuick(:final title, :final instruction, :final dialName, :final conditionLabel) =>
        _QuickMethodCard(
          title: title,
          instruction: instruction,
          dialName: dialName,
          conditionLabel: conditionLabel,
        ),
      NavSectionFnMenu(:final title, :final steps) =>
        _FnMenuCard(title: title, steps: steps),
      NavSectionFullMenu(:final title, :final pressMenuLabel, :final steps, :final finalStep) =>
        _FullMenuCard(
          title: title,
          pressMenuLabel: pressMenuLabel,
          steps: steps,
          finalStep: finalStep,
        ),
    };
  }
}
```

### 7.2. NavHeader

```dart
class _NavHeader extends StatelessWidget {
  final String header;
  final String subheader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Séparer le header en "setting → value"
    final parts = header.split(' → ');
    final settingPart = parts.isNotEmpty ? parts[0] : header;
    final valuePart = parts.length > 1 ? parts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RÉGLER',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: theme.textTheme.headlineSmall,
            children: [
              TextSpan(text: settingPart),
              if (valuePart.isNotEmpty) ...[
                TextSpan(
                  text: ' → ',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                TextSpan(
                  text: valuePart,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subheader,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
```

### 7.3. QuickMethodCard (molette)

```dart
class _QuickMethodCard extends StatelessWidget {
  final String title;
  final String instruction;
  final String? dialName;
  final String? conditionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title: title, icon: Icons.flash_on_rounded),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (conditionLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        conditionLabel!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎛️ ', style: theme.textTheme.titleMedium),
                    Expanded(
                      child: Text(instruction, style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
                if (dialName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    dialName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

### 7.4. FullMenuCard (navigation menu)

```dart
class _FullMenuCard extends StatelessWidget {
  final String title;
  final String pressMenuLabel;
  final List<NavStep> steps;
  final NavStep finalStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSteps = [...steps, finalStep];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title: title, icon: Icons.menu_rounded),
        const SizedBox(height: 8),

        // "Appuie sur MENU"
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Text('📱 ', style: theme.textTheme.bodyLarge),
              Text(pressMenuLabel, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),

        // Étapes
        ...allSteps.map((step) => _NavStepCard(step: step, isLast: step == finalStep)),
      ],
    );
  }
}

class _NavStepCard extends StatelessWidget {
  final NavStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéro d'étape dans un cercle
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: isLast
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isLast
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Contenu
          Expanded(
            child: Card(
              elevation: 0,
              color: isLast
                  ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              margin: const EdgeInsets.only(bottom: 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!isLast)
                          Text('→ ', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        Expanded(
                          child: Text(
                            step.label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (step.position != null && !isLast)
                          Text(
                            'Onglet ${step.position!.tabIndex}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    if (step.actionHint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.actionHint!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 7.5. TipCard

```dart
class _TipCard extends StatelessWidget {
  final NavTip tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 ', style: theme.textTheme.bodyMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.text, style: theme.textTheme.bodyMedium),
                if (tip.relatedPath != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    tip.relatedPath!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 7.6. IncompleteNotice (fallback)

Quand le NavPath n'existe pas ou est incomplet (skill 15 B4).

```dart
class _IncompleteNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.construction_rounded, size: 32, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              'Le chemin dans les menus n\'est pas encore documenté pour ton boîtier.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {/* trigger feedback form */},
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: const Text('Signaler'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. Cas spéciaux par constructeur

### 8.1. Canon — Modes Av/Tv

Canon utilise "Av" et "Tv" au lieu de "A" et "S" sur la molette de mode. Le tip doit refléter ça.

```json
// nav_paths.json pour Canon R50, setting_id: "exposure_mode"
{
  "dial_access": {
    "dial_id": "mode_dial",
    "labels": {
      "en": "Turn the mode dial on top of the camera to the desired mode.",
      "fr": "Tourne la molette de mode sur le dessus de l'appareil."
    }
  },
  "tips": [{
    "labels": {
      "en": "Canon uses 'Av' for Aperture Priority and 'Tv' for Shutter Priority, unlike other brands that use 'A' and 'S'.",
      "fr": "Canon utilise « Av » pour la priorité ouverture et « Tv » pour la priorité vitesse, contrairement aux autres marques qui utilisent « A » et « S »."
    }
  }]
}
```

### 8.2. Nikon — Double accès i Menu + G Menu

Nikon a deux systèmes de menu : le bouton **i** (accès rapide, comme le Fn de Sony) et le bouton **G** (MENU, accès complet). Les deux sont documentés dans le NavPath.

```json
{
  "quick_access": {
    "method": "i_menu",
    "steps": [
      { "action": "press", "target": "i_button", "labels": { "en": "Press i button", "fr": "Appuie sur le bouton i" } },
      { "action": "navigate", "target": "focus_mode", "labels": { "en": "Select Focus mode", "fr": "Sélectionne Mode de mise au point" } }
    ]
  },
  "menu_path": ["photo_shooting", "af", "focus_mode"]
}
```

### 8.3. Fujifilm — Q Menu riche

Le Q Menu Fuji est très riche (16 items personnalisables). La plupart des réglages sont accessibles via le Q Menu, ce qui rend la section "Via le menu" souvent secondaire.

```json
{
  "quick_access": {
    "method": "q_menu",
    "steps": [
      { "action": "press", "target": "q_button", "labels": { "fr": "Appuie sur Q" } },
      { "action": "navigate", "target": "focus_mode", "labels": { "fr": "Sélectionne Mode AF" } }
    ]
  }
}
```

### 8.4. Réglages via molette uniquement

Certains réglages ne sont accessibles que par contrôle physique, pas par le menu. Exemples : ouverture (molette en mode M/A), vitesse (molette en mode M/S), compensation d'exposition (molette dédiée sur certains boîtiers).

Pour ces réglages, `menu_path` est `null` et seul `dial_access` est renseigné. L'écran n'affiche pas de section "Via le menu".

### 8.5. Réglages via menu uniquement

Certains réglages ne sont accessibles que par le menu. Exemple : format fichier (RAW/JPEG). Pas de molette, pas de Fn par défaut.

Pour ces réglages, `dial_access` et `quick_access` sont `null`. Seul `menu_path` est renseigné. L'écran affiche uniquement "Via le menu" + une suggestion de l'assigner à un bouton custom dans les tips.

---

## 9. Performance

Le Menu Navigation Mapper est exécuté **une seule fois** par tap sur un réglage (pas à chaque frame). La résolution implique :

1. Lookup du NavPath dans une liste de 15 éléments → O(1)
2. Traversal du MenuTree pour 3-4 nœuds → O(log n), n ≈ 200 items
3. Résolution de 5-10 labels dans des Map<String, String> → O(1) chaque
4. Construction de l'objet MenuNavDisplay → O(1)

**Temps total : < 1ms.** Imperceptible. Le CameraDataCache ayant déjà tout en RAM, il n'y a aucune lecture filesystem.

---

## 10. Tests

### 10.1. Tests unitaires du ResolveMenuPath

| # | Input | Vérification |
|---|-------|-------------|
| T1 | sony_a6700, af_mode, af-c, fr | Header contient "Mode mise au point → AF-C". Breadcrumb = "AF/MF > Régl. AF/MF > Mode mise au point". |
| T2 | sony_a6700, aperture, 2.8, fr | Pas de section fullMenu (menu_path null). Section quick avec "molette avant". |
| T3 | sony_a6700, af_mode, af-c, de | Header contient "Fokusmodus → AF-C". Breadcrumb en allemand. |
| T4 | canon_r50, af_mode, af-c, fr | Valeur label = "Autofocus Servo" (pas "AF continu" — terminologie Canon). |
| T5 | canon_r50, af_mode, af-c, en | Valeur label = "Servo AF". |
| T6 | sony_a6700, af_mode, af-c, zh-cn | Tout en chinois simplifié. |
| T7 | sony_a6700, unknown_setting, x, fr | isIncomplete = true, sections vides. |
| T8 | sony_a6700, af_mode, af-c, xx (langue absente) | Fallback labels anglais. |
| T9 | NavPath avec 3 méthodes (dial + Fn + menu) | 3 sections dans l'ordre dial → Fn → menu. |
| T10 | NavPath avec tip + related_menu_path | Tip affiché avec chemin en firmware lang. |

### 10.2. Tests widget

| # | Scénario | Vérification |
|---|----------|-------------|
| T11 | Résultat complet avec 3 sections | Les 3 cards affichées dans l'ordre |
| T12 | Résultat avec molette uniquement | Une seule card "Méthode rapide", pas de "Via le menu" |
| T13 | Résultat incomplet (isIncomplete) | Notice "Chemin non documenté" + bouton Signaler |
| T14 | Étape finale highlight | La dernière étape a un fond coloré différent |
| T15 | Tip avec chemin lié | Le chemin est affiché en monospace sous le tip |

### 10.3. Test d'intégration cross-brand

Le test ultime : le même concept (`af_mode:af-c`) résolu pour les 4 marques × 2 langues = 8 combinaisons, et vérifier que chaque résultat utilise la terminologie exacte du constructeur.

```dart
void main() {
  group('Cross-brand AF-C resolution', () {
    for (final (bodyId, fwLang, expectedLabel) in [
      ('sony_a6700', 'fr', 'AF continu'),
      ('sony_a6700', 'en', 'Continuous AF'),
      ('canon_r50', 'fr', 'Autofocus Servo'),
      ('canon_r50', 'en', 'Servo AF'),
      ('nikon_z50ii', 'fr', 'AF continu (AF-C)'),
      ('nikon_z50ii', 'en', 'Continuous-servo AF'),
      ('fuji_xt5', 'fr', 'AF-C'),
      ('fuji_xt5', 'en', 'AF-C'),
    ]) {
      test('$bodyId/$fwLang → $expectedLabel', () async {
        final result = await resolveMenuPath.execute(
          bodyId: bodyId,
          settingId: 'af_mode',
          value: 'af-c',
          firmwareLanguage: fwLang,
          appLanguage: 'en',
          l10n: mockL10n,
        );

        expect(result.header, contains(expectedLabel));
      });
    }
  });
}
```

---

## 11. Résumé

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║  LE MENU NAVIGATION MAPPER, C'EST :                              ║
║                                                                  ║
║  1. Un setting_id universel ("af_mode")                          ║
║     ↓                                                            ║
║  2. Un SettingNavPath par boîtier (chemin + accès rapides)       ║
║     ↓                                                            ║
║  3. Un MenuTree traversal (IDs → labels localisés)               ║
║     ↓                                                            ║
║  4. Un écran qui dit EXACTEMENT :                                ║
║     "Sur TON Sony A6700, en FRANÇAIS, appuie sur Fn,            ║
║      sélectionne « Mode mise au point », choisis « AF continu »" ║
║                                                                  ║
║  Aucune autre app ne fait ça.                                    ║
║  C'est ce qui justifie l'existence de ShootHelper.               ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

*Ce document est la référence pour l'implémentation du killer feature. Combiné avec le skill 04 (Camera Data Architecture) pour le format des données, le skill 07 (i18n) pour la résolution des labels, et le skill 18 (Settings Output) qui déclenche la navigation vers cet écran, il ferme la boucle du flow principal.*
