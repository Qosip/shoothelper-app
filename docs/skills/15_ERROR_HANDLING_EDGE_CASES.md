# Error Handling & Edge Cases — ShootHelper

> **Skill 15/22** · Gestion d'erreur, cas limites, fallbacks, messages utilisateur
> Version 1.0 · Mars 2026
> Réf : 02_USER_FLOWS.md, 06_SETTINGS_ENGINE.md, 13_OFFLINE_FIRST_ARCHITECTURE.md

---

## 1. Philosophie

**L'app ne crash jamais.** Quelle que soit la combinaison d'inputs, l'état du réseau, ou l'état des données locales — l'utilisateur voit un message compréhensible et une action possible. Pas de stack trace, pas d'écran blanc, pas de freeze.

**3 principes :**

1. **Toujours un meilleur effort** — si le moteur ne peut pas donner le résultat optimal, il donne le meilleur compromis et explique pourquoi
2. **Toujours un fallback** — si une donnée manque, l'app utilise une valeur par défaut et signale la dégradation
3. **Toujours une action proposée** — chaque erreur affichée inclut un bouton pour résoudre le problème (réessayer, modifier, signaler)

---

## 2. Classification des erreurs

```
┌─────────────────────────────────────────────────────────────────┐
│                CATÉGORIES D'ERREUR                               │
│                                                                 │
│  CATÉGORIE A : Erreurs réseau                                    │
│  → L'utilisateur est informé, l'app continue avec les données    │
│    locales si disponibles                                        │
│                                                                 │
│  CATÉGORIE B : Erreurs de données                                │
│  → Données manquantes, corrompues, ou incohérentes               │
│  → Fallback vers des valeurs par défaut + signalement             │
│                                                                 │
│  CATÉGORIE C : Erreurs du moteur de settings                     │
│  → Combinaisons impossibles, conflits de contraintes             │
│  → Le moteur donne son meilleur effort + compromis explicites    │
│                                                                 │
│  CATÉGORIE D : Erreurs de compatibilité gear                     │
│  → Objectif incompatible, feature absente du boîtier             │
│  → Signalement avant le calcul (Scene Input) ou dans le résultat│
│                                                                 │
│  CATÉGORIE E : Erreurs système                                   │
│  → Filesystem plein, permission refusée, crash inattendu         │
│  → Catch-all avec message générique et option de signalement     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Structure de gestion d'erreur dans le code

### 3.1. Hiérarchie d'exceptions

```dart
// core/errors/exceptions.dart

/// Base de toutes les exceptions ShootHelper
sealed class ShootHelperException implements Exception {
  final String message;
  final String? debugInfo;
  const ShootHelperException(this.message, {this.debugInfo});
}

// ─── Catégorie A : Réseau ───
class NoNetworkException extends ShootHelperException {
  const NoNetworkException() : super('Pas de connexion internet');
}

class NetworkTimeoutException extends ShootHelperException {
  final String url;
  const NetworkTimeoutException(this.url)
      : super('La connexion a expiré');
}

class ServerException extends ShootHelperException {
  final int statusCode;
  const ServerException(this.statusCode)
      : super('Le serveur est temporairement indisponible');
}

// ─── Catégorie B : Données ───
class DataPackNotFoundException extends ShootHelperException {
  final String bodyId;
  const DataPackNotFoundException(this.bodyId)
      : super('Données du boîtier introuvables');
}

class DataPackCorruptedException extends ShootHelperException {
  final String bodyId;
  const DataPackCorruptedException(this.bodyId)
      : super('Les données téléchargées sont corrompues');
}

class DataPackIncompleteException extends ShootHelperException {
  final String bodyId;
  final List<String> missingFiles;
  const DataPackIncompleteException(this.bodyId, this.missingFiles)
      : super('Données incomplètes');
}

class MenuItemNotFoundException extends ShootHelperException {
  final String settingId;
  final String bodyId;
  const MenuItemNotFoundException(this.settingId, this.bodyId)
      : super('Chemin de menu introuvable');
}

class LabelNotFoundException extends ShootHelperException {
  final String itemId;
  final String language;
  const LabelNotFoundException(this.itemId, this.language)
      : super('Traduction manquante');
}

class LensNotFoundException extends ShootHelperException {
  final String lensId;
  const LensNotFoundException(this.lensId)
      : super('Données de l\'objectif introuvables');
}

// ─── Catégorie C : Moteur ───
class ExposureImpossibleException extends ShootHelperException {
  final String reason;
  const ExposureImpossibleException(this.reason)
      : super('Exposition impossible avec ces contraintes');
}

// ─── Catégorie D : Compatibilité ───
class IncompatibleLensException extends ShootHelperException {
  final String lensId;
  final String bodyId;
  const IncompatibleLensException(this.lensId, this.bodyId)
      : super('Objectif incompatible avec ce boîtier');
}

class FeatureNotSupportedException extends ShootHelperException {
  final String featureId;
  final String bodyId;
  const FeatureNotSupportedException(this.featureId, this.bodyId)
      : super('Fonctionnalité non supportée par ce boîtier');
}

// ─── Catégorie E : Système ───
class StorageFullException extends ShootHelperException {
  const StorageFullException()
      : super('Pas assez d\'espace de stockage');
}

class FilePermissionException extends ShootHelperException {
  const FilePermissionException()
      : super('Impossible d\'accéder au stockage');
}

class UnexpectedException extends ShootHelperException {
  final Object originalError;
  const UnexpectedException(this.originalError)
      : super('Une erreur inattendue est survenue');
}
```

### 3.2. Conversion en Failure (pour la couche Domain)

Les exceptions sont des détails d'implémentation (couche Data). La couche Domain utilise des `Failure` sémantiques qui ne dépendent pas de l'origine de l'erreur.

```dart
// core/errors/failures.dart

sealed class Failure {
  final String userMessage;    // Message pour l'UI
  final String? actionLabel;   // Label du bouton d'action (null = pas de bouton)
  final FailureAction? action; // L'action à effectuer
  const Failure(this.userMessage, {this.actionLabel, this.action});
}

enum FailureAction { retry, goToSettings, goToStore, reportBug, dismiss }

class NetworkFailure extends Failure {
  const NetworkFailure()
      : super(
          'Pas de connexion internet. Connecte-toi pour télécharger les données.',
          actionLabel: 'Réessayer',
          action: FailureAction.retry,
        );
}

class DataNotReadyFailure extends Failure {
  const DataNotReadyFailure()
      : super(
          'Les données de ton boîtier ne sont pas encore téléchargées.',
          actionLabel: 'Télécharger',
          action: FailureAction.goToSettings,
        );
}

class CorruptedDataFailure extends Failure {
  const CorruptedDataFailure()
      : super(
          'Les données sont corrompues. On va les re-télécharger.',
          actionLabel: 'Re-télécharger',
          action: FailureAction.retry,
        );
}

class GearMissingFailure extends Failure {
  const GearMissingFailure()
      : super(
          'Configure ton matériel pour commencer.',
          actionLabel: 'Configurer',
          action: FailureAction.goToSettings,
        );
}

class AppUpdateRequiredFailure extends Failure {
  const AppUpdateRequiredFailure()
      : super(
          'Une mise à jour de l\'app est nécessaire pour utiliser les dernières données.',
          actionLabel: 'Mettre à jour',
          action: FailureAction.goToStore,
        );
}

class UnknownFailure extends Failure {
  const UnknownFailure()
      : super(
          'Une erreur inattendue est survenue. Si le problème persiste, signale-le.',
          actionLabel: 'Signaler',
          action: FailureAction.reportBug,
        );
}
```

### 3.3. Widget d'erreur réutilisable

```dart
// shared/presentation/widgets/error_display.dart

class ErrorDisplay extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onAction;

  const ErrorDisplay({required this.failure, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(failure), size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              failure.userMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (failure.actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(failure.actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(Failure failure) => switch (failure) {
    NetworkFailure() => Icons.wifi_off_rounded,
    DataNotReadyFailure() => Icons.download_rounded,
    CorruptedDataFailure() => Icons.warning_rounded,
    GearMissingFailure() => Icons.camera_alt_outlined,
    AppUpdateRequiredFailure() => Icons.system_update_rounded,
    UnknownFailure() => Icons.error_outline_rounded,
  };
}
```

---

## 4. Catégorie A : Erreurs réseau — Tous les scénarios

### A1 : Premier lancement sans réseau

| Situation | L'utilisateur ouvre l'app pour la première fois sans connexion internet |
|-----------|----------------------------------------------------------------------|
| **Écran** | Welcome → Sélection Boîtier → Récap → Tap "Télécharger" |
| **Détection** | `ConnectivityService.hasInternetAccess() == false` |
| **Affichage** | Écran bloquant : "Tu as besoin d'une connexion internet pour le premier setup. Après ça, l'app fonctionne 100% hors ligne." |
| **Action** | Bouton "Réessayer" — re-check la connectivité |
| **Fallback** | Aucun. L'app ne peut pas fonctionner sans données. |

### A2 : Perte de réseau pendant le download

| Situation | Le réseau coupe au milieu du téléchargement du data pack |
|-----------|--------------------------------------------------------|
| **Détection** | Exception `DioException.connectionError` ou `DioException.receiveTimeout` |
| **Affichage** | Écran download avec message : "La connexion a été interrompue. Les fichiers déjà téléchargés sont sauvegardés." |
| **Action** | Bouton "Réessayer" — reprend là où ça s'est arrêté (file-level resume via download_state.json) |
| **Fallback** | Les fichiers déjà écrits dans `_temp/` restent. Seuls les fichiers manquants sont re-téléchargés. |

### A3 : Serveur CDN indisponible

| Situation | Le CDN retourne une erreur 5xx ou ne répond pas |
|-----------|------------------------------------------------|
| **Détection** | `ServerException(statusCode: 502)` ou timeout |
| **Affichage** | "Le serveur est temporairement indisponible. Réessaie dans quelques minutes." |
| **Action** | Bouton "Réessayer" avec retry exponentiel (1s, 2s, 4s — 3 tentatives automatiques avant d'afficher l'erreur) |
| **Fallback** | Si un data pack local existe déjà → l'app continue de fonctionner avec. |

### A4 : Fichier 404 sur le CDN

| Situation | Un fichier spécifique n'existe pas (ex: lens non encore ajouté côté serveur) |
|-----------|----------------------------------------------------------------------------|
| **Détection** | HTTP 404 |
| **Affichage** | "Les données de cet objectif ne sont pas encore disponibles. On l'ajoutera bientôt." |
| **Action** | Bouton "Signaler" (stocke le feedback localement) + "Continuer sans" |
| **Fallback** | L'objectif est marqué comme manquant dans download_state.json. L'app fonctionne avec les autres objectifs. |

### A5 : Wi-Fi captif (portail d'hôtel)

| Situation | `connectivity_plus` dit "Wi-Fi connecté" mais pas d'internet réel |
|-----------|----------------------------------------------------------------|
| **Détection** | `ConnectivityService.hasInternetAccess()` fait un ping → échec |
| **Affichage** | Identique à A1 ou A3 selon le contexte |
| **Fallback** | L'app considère qu'elle est offline. |

---

## 5. Catégorie B : Erreurs de données — Tous les scénarios

### B1 : Data pack corrompu (checksum invalide)

| Situation | Le checksum SHA-256 calculé ne correspond pas au manifest |
|-----------|----------------------------------------------------------|
| **Détection** | Après download : `validateChecksum() == false` |
| **Affichage** | "Le téléchargement a été corrompu. On va réessayer." |
| **Action** | Supprime le `_temp/`, re-télécharge automatiquement (1 retry). Si échec au retry → "Le problème persiste. Vérifie ta connexion et réessaie." |
| **Fallback** | L'ancien data pack (s'il existe) reste intact grâce à l'atomic swap. |

### B2 : Fichier JSON malformé (parse error)

| Situation | Un fichier JSON local est invalide (ex: corrompu par un crash iOS) |
|-----------|-------------------------------------------------------------------|
| **Détection** | `FormatException` au `jsonDecode()` |
| **Affichage** | "Les données de ton boîtier semblent corrompues. On va les re-télécharger." |
| **Action** | Supprime le data pack local → re-télécharge si online. Si offline → "Connecte-toi pour re-télécharger." |
| **Fallback** | Aucun — les données corrompues ne sont pas exploitables. |

### B3 : Label de menu manquant dans la langue demandée

| Situation | Un `labels[firmware_lang]` est absent pour un item de menu |
|-----------|-----------------------------------------------------------|
| **Détection** | `resolveLabel()` ne trouve pas la clé de langue |
| **Comportement** | Fallback chain (skill 07) : `labels[lang]` → `labels["en"]` → `labels[first_key]` → `item_id` |
| **Affichage** | Le label anglais est affiché avec un petit indicateur `(EN)` à côté pour signaler que la traduction manque |
| **Action** | Rien de bloquant. Log l'erreur pour correction dans le prochain data pack. |
| **Sévérité** | Basse — l'app fonctionne, juste un label pas dans la bonne langue. |

### B4 : NavPath manquant pour un réglage

| Situation | Le SettingNavPath pour `(body_id, setting_id)` n'existe pas dans nav_paths.json |
|-----------|-------------------------------------------------------------------------------|
| **Détection** | `findNavPath()` retourne `null` |
| **Comportement** | Le réglage est affiché dans les résultats mais sans bouton "Où régler sur mon appareil" |
| **Affichage** | Dans le détail du réglage : "Le chemin dans les menus n'est pas encore documenté pour ton boîtier." |
| **Action** | Lien "Signaler" |
| **Sévérité** | Moyenne — le réglage est recommandé mais l'utilisateur doit chercher lui-même dans ses menus. |

### B5 : Setting_id inconnu dans le menu_tree

| Situation | Un `menu_item_id` dans nav_paths ne correspond à aucun item dans menu_tree |
|-----------|--------------------------------------------------------------------------|
| **Détection** | `findMenuItem()` retourne `null` |
| **Comportement** | Identique à B4 — pas de navigation menu pour ce réglage |
| **Log** | Log d'erreur avec `bodyId`, `settingId`, `menuItemId` pour correction |

### B6 : Données d'objectif manquantes

| Situation | L'objectif actif n'a pas de fichier JSON dans le data pack |
|-----------|-----------------------------------------------------------|
| **Détection** | `FileManager.readJson()` → `FileSystemException` |
| **Comportement** | L'app propose de re-télécharger l'objectif si online, ou de switcher vers un autre objectif |
| **Affichage** | "Les données de ton {lens_name} sont manquantes." |
| **Action** | "Télécharger" (si online) / "Changer d'objectif" (si offline ou si le téléchargement échoue) |

### B7 : Filesystem plein

| Situation | Pas assez d'espace pour écrire les fichiers téléchargés |
|-----------|--------------------------------------------------------|
| **Détection** | `FileSystemException` avec code `ENOSPC` |
| **Affichage** | "Pas assez d'espace de stockage sur ton téléphone. Libère environ {needed_mb} MB et réessaie." |
| **Action** | Bouton "Réessayer" |
| **Calcul** | Espace nécessaire ≈ taille du data pack × 2 (temporaire + final) |

---

## 6. Catégorie C : Erreurs du moteur — Compromis et impossibilités

Le moteur ne "plante" jamais. Il retourne toujours un résultat. Mais certains résultats sont accompagnés de compromis ou d'avertissements.

### C1 : ISO dépassant la limite de bruit acceptable

| Situation | Le calcul donne un ISO > `iso_usable_max` |
|-----------|------------------------------------------|
| **Type** | `Compromise(type: noise, severity: warning)` |
| **Message** | "ISO {value} — bruit visible. Ton {body_name} produit du bruit notable au-delà de ISO {iso_usable_max}. Shooter en RAW te permettra de réduire le bruit en post-traitement." |
| **Alternative** | "ISO {lower} → vitesse {slower} (moins de bruit, risque de flou)" |

### C2 : ISO dépassant la plage physique du boîtier

| Situation | Le calcul nécessiterait un ISO > `iso_range.max` |
|-----------|------------------------------------------------|
| **Type** | `Compromise(type: noise, severity: critical)` |
| **Message** | "Pas assez de lumière pour ces contraintes. Même à ISO {max} ({body_name}), l'image sera sous-exposée." |
| **Suggestions** | "Utilise un trépied pour baisser la vitesse" / "Utilise un objectif plus lumineux" / "Ajoute une source de lumière (flash)" |

### C3 : Astro sans trépied

| Situation | `subject == astro` ET `support != tripod` |
|-----------|------------------------------------------|
| **Type** | `Compromise(type: impossible, severity: critical)` |
| **Message** | "L'astrophotographie nécessite un trépied. Les temps de pose de 10+ secondes sont impossibles à main levée, même avec stabilisation." |
| **Comportement** | Le moteur calcule quand même (meilleur effort) : ouverture max, ISO max, vitesse la plus lente possible handheld. Mais le résultat sera médiocre et le message le dit. |

### C4 : Filé de mouvement en plein soleil

| Situation | `intention == motion_blur` ET `EV_cible >= 13` (plein soleil) |
|-----------|--------------------------------------------------------------|
| **Type** | `Compromise(type: exposure, severity: warning)` |
| **Message** | "Même avec l'ouverture la plus fermée (f/{min_aperture}) et l'ISO le plus bas ({iso_min}), l'image sera surexposée à cette vitesse lente. Tu as besoin d'un filtre ND." |
| **Suggestion** | "Un filtre ND 6 stops (ND64) te permettrait d'utiliser 1/{speed}s en plein soleil." |

### C5 : Contrainte utilisateur impossible

| Situation | L'utilisateur a mis `constraint_iso_max: 400` + `constraint_shutter_min: 1/1000` en intérieur sombre |
|-----------|------------------------------------------------------------------------------------------------------|
| **Type** | `Compromise(type: impossible, severity: critical)` |
| **Message** | "Tes contraintes (ISO max {iso_max}, vitesse min {shutter_min}) ne sont pas compatibles avec ces conditions de lumière. Il faudrait {needed_ev} stops de lumière en plus." |
| **Action** | "Modifier les contraintes" → retour à Scene Input avec les contraintes pré-remplies |
| **Comportement** | Le moteur donne le meilleur résultat possible en ignorant partiellement les contraintes, et indique lesquelles n'ont pas pu être respectées. |

### C6 : Macro avec objectif non-macro

| Situation | `subject == macro` ET `subject_distance == very_close` ET `lens.min_focus_distance > distance_demandée` |
|-----------|--------------------------------------------------------------------------------------------------------|
| **Type** | `Compromise(type: gear_limit, severity: warning)` |
| **Message** | "Ton {lens_name} a une distance minimale de mise au point de {min_distance}m (à {focal}mm). Pour de la macro plus proche, il te faudrait un objectif macro ou des tubes allonge." |
| **Comportement** | Le moteur ajuste la focale pour minimiser la distance de MAP (sur un zoom). |

### C7 : Eye-AF non disponible

| Situation | `af_area_override == eye_af` mais le boîtier n'a pas cette feature (ou seulement dans certains modes) |
|-----------|------------------------------------------------------------------------------------------------------|
| **Type** | `Compromise(type: gear_limit, severity: info)` |
| **Message** | "Eye-AF disponible uniquement en AF-C sur ton {body_name}. Le moteur a automatiquement basculé en AF-C." ou "Eye-AF non disponible sur ton {body_name}. Zone AF large recommandée à la place." |
| **Comportement** | Auto-switch vers le mode compatible le plus proche. |

### C8 : Focale incompatible avec le sujet

| Situation | `subject == landscape` mais l'objectif est un 85mm prime |
|-----------|----------------------------------------------------------|
| **Type** | `Compromise(type: gear_limit, severity: info)` |
| **Message** | "Ton {lens_name} ({focal}mm) est un téléobjectif. C'est inhabituel pour le paysage mais ça peut donner des résultats intéressants (compression de plans). Pour un cadrage large classique, un objectif grand angle (< 35mm eq.) serait idéal." |
| **Comportement** | Le moteur calcule normalement. C'est un info, pas un blocage — le photographe peut très bien faire du paysage au 85mm. |

---

## 7. Catégorie D : Compatibilité gear — Avant le calcul

Ces erreurs sont détectées **dans le Scene Input ou le sélecteur de gear**, avant que le moteur ne soit appelé.

### D1 : Feature non supportée → Chip grisé

```dart
// features/scene_input/presentation/widgets/af_area_selector.dart

class AfAreaSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = ref.watch(currentBodyProvider);

    return Wrap(
      spacing: 8,
      children: AfAreaOverride.values.map((area) {
        final supported = _isSupported(area, body);
        return ShootChip(
          label: area.label(context),
          selected: ref.watch(sceneInputDraftProvider).afAreaOverride == area,
          enabled: supported,
          tooltip: supported ? null : 'Non disponible sur ton ${body?.displayName}',
          onTap: supported
              ? () => ref.read(sceneInputDraftProvider.notifier).setAfAreaOverride(area)
              : null,
        );
      }).toList(),
    );
  }

  bool _isSupported(AfAreaOverride area, Body? body) {
    if (body == null) return true; // Pas de body → tout activé par défaut
    return switch (area) {
      AfAreaOverride.eyeAf => body.spec.autofocus.hasEyeAf,
      AfAreaOverride.tracking => body.spec.autofocus.areas.contains('tracking'),
      _ => true,
    };
  }
}
```

### D2 : Objectif incompatible avec le boîtier

Normalement impossible grâce au filtre de compatibilité dans le sélecteur d'objectifs (skill 04 §5). Mais en cas de corruption de données :

```dart
// domain/use_cases/calculate_settings.dart (dans execute())

// Vérification de sécurité
if (body.mountId != lens.mountId) {
  throw IncompatibleLensException(lens.id, body.id);
}
```

Côté UI, cette exception est catchée et affiche : "Ton {lens_name} n'est pas compatible avec ton {body_name}. Vérifie ta configuration dans les réglages."

### D3 : Subject detection non supportée

| Feature | Sony | Canon | Nikon | Fuji |
|---------|------|-------|-------|------|
| Human eye | Tous MVP | Tous MVP | Tous MVP | Tous MVP |
| Animal eye | A6700, A7IV, A7CII | R7, R6II | Zf, Z6III | X-T5, X-S20 |
| Bird | A6700, A7IV, A7CII | R7, R6II | Zf, Z6III | X-T5 |
| Vehicle | A6700, A7IV, A7CII | — | Zf, Z6III | X-T5 |

Si le moteur recommande "Animal Eye AF" mais que le boîtier ne le supporte pas → fallback vers le mode de zone AF le plus approprié + info dans le résultat.

---

## 8. Catégorie E : Erreurs système — Catch-all

### E1 : Crash inattendu

```dart
// main.dart

void main() {
  // Catch-all pour les erreurs Flutter non gérées
  FlutterError.onError = (details) {
    // Log localement (pour le debug)
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
    // En V2 : envoyer à Crashlytics/Sentry
  };

  // Catch-all pour les erreurs Dart asynchrones non gérées
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error');
    debugPrint('Stack: $stack');
    return true; // Marquer comme handled
  };

  runApp(const ProviderScope(child: App()));
}
```

### E2 : Gestion dans les providers

```dart
// Pattern : chaque provider async gère ses erreurs

@riverpod
Future<Body?> currentBody(Ref ref) async {
  try {
    ref.watch(loadCameraDataProvider);
    final cache = ref.read(cameraDataCacheProvider);
    return cache.isLoaded ? cache.body : null;
  } on ShootHelperException catch (e) {
    // Erreur connue → la remonter proprement
    throw e;
  } catch (e) {
    // Erreur inconnue → wrapper
    throw UnexpectedException(e);
  }
}
```

### E3 : Affichage en cas d'erreur non gérée

```dart
// Écran par défaut quand un provider est en erreur
// Affiché par le .when(error: ...) de AsyncValue

Widget _buildErrorState(Object error, StackTrace stack) {
  final failure = _mapToFailure(error);
  return ErrorDisplay(
    failure: failure,
    onAction: () => _handleAction(failure),
  );
}

Failure _mapToFailure(Object error) => switch (error) {
  NoNetworkException() => const NetworkFailure(),
  DataPackNotFoundException() => const DataNotReadyFailure(),
  DataPackCorruptedException() => const CorruptedDataFailure(),
  IncompatibleLensException() => const GearMissingFailure(),
  ShootHelperException(message: final msg) => Failure(msg),
  _ => const UnknownFailure(),
};
```

---

## 9. Fallback par données manquantes

Tableau exhaustif de ce qui se passe quand chaque type de donnée est absent.

| Donnée manquante | Impact | Fallback | Sévérité |
|-----------------|--------|----------|----------|
| `body.json` entier | App inutilisable | Bloquer → "Re-télécharge les données" | Critique |
| `menu_tree.json` | Pas de navigation menu | Résultats affichés sans bouton "Où régler" | Haute |
| `nav_paths.json` | Pas de navigation menu | Idem — résultats sans chemin menu | Haute |
| Un `lenses/{id}.json` | Objectif inutilisable | Proposer un autre objectif ou re-télécharger | Moyenne |
| `setting_defs.json` | Moteur ne peut pas mapper les réglages | Utiliser une copie embarquée dans l'app (fallback hardcodé) | Moyenne |
| `brands.json` | Pas de logo/nom de marque | Afficher le brand_id brut ("sony") | Basse |
| `mounts.json` | Pas de filtre de compatibilité | Afficher tous les objectifs sans filtre | Basse |
| Un `labels[lang]` spécifique | Un label pas dans la bonne langue | Fallback chain : EN → first available → ID | Basse |
| `BodySpec.iso_usable_max` | Pas d'avertissement de bruit | Ne pas afficher l'avertissement (dégradation silencieuse) | Basse |
| `Controls.dials` | Pas de "méthode rapide" | Afficher uniquement "Via le menu" | Basse |
| `SettingNavPath.tips` | Pas d'astuces | Ne pas afficher la section tips | Nulle |
| `SettingNavPath.quick_access` | Pas d'accès rapide Fn | Afficher uniquement "Via le menu" | Basse |
| `SettingNavPath.dial_access` | Pas d'accès molette | Afficher uniquement Fn + menu | Basse |

**Principe** : plus la donnée est haute dans le tableau, plus l'erreur est critique. Les données basses peuvent manquer silencieusement — l'app fonctionne avec un peu moins de richesse.

### 9.1. setting_defs.json — Fallback embarqué

`setting_defs.json` est le seul fichier pour lequel l'app embarque un fallback hardcodé. Les 15 SettingDefs du MVP sont des constantes stables (les concepts "ouverture", "ISO", "mode AF" ne changent pas). Si le fichier téléchargé est corrompu ou manquant, l'app utilise sa copie interne.

```dart
// core/constants/default_setting_defs.dart

const List<Map<String, dynamic>> defaultSettingDefs = [
  {
    "id": "aperture",
    "category": "exposure",
    "data_type": "continuous",
    // ... version hardcodée minimale
  },
  {
    "id": "shutter_speed",
    "category": "exposure",
    "data_type": "continuous",
  },
  // ... les 15 SettingDefs
];
```

---

## 10. Messages utilisateur — Guide de rédaction

### 10.1. Principes

| Principe | Exemple ✅ | Contre-exemple ❌ |
|----------|-----------|-------------------|
| **Pas de jargon technique** | "Pas de connexion internet" | "NetworkException: EHOSTUNREACH" |
| **Dire ce qui se passe, pas ce qui a cassé** | "Les données sont corrompues" | "SHA-256 checksum mismatch on body.json" |
| **Toujours une action** | "Réessaie dans quelques minutes" | "Une erreur est survenue" |
| **Tutoiement, ton direct** | "Ton appareil n'est pas encore supporté" | "L'appareil sélectionné ne figure pas dans notre base" |
| **Positif quand possible** | "On va les re-télécharger" | "Le téléchargement a échoué" |
| **Court** | Max 2 phrases | Pas de paragraphe |

### 10.2. Templates de messages

```dart
// l10n/app_fr.arb (extraits)

{
  "error_no_network": "Pas de connexion internet. Connecte-toi pour télécharger les données.",
  "error_no_network_first_setup": "Tu as besoin d'une connexion internet pour le premier setup. Après ça, l'app fonctionne 100% hors ligne.",
  "error_timeout": "La connexion est trop lente. Vérifie ton réseau et réessaie.",
  "error_server_down": "Le serveur est temporairement indisponible. Réessaie dans quelques minutes.",
  "error_corrupted": "Les données semblent corrompues. On va les re-télécharger.",
  "error_storage_full": "Pas assez d'espace de stockage. Libère environ {neededMb} MB et réessaie.",
  "error_lens_missing": "Les données de ton {lensName} sont manquantes.",
  "error_body_not_supported": "Ton boîtier n'est pas encore supporté. On l'ajoutera bientôt !",
  "error_feature_not_supported": "{featureName} n'est pas disponible sur ton {bodyName}.",
  "error_update_required": "Une mise à jour de l'app est nécessaire pour les dernières données.",
  "error_unknown": "Une erreur inattendue est survenue. Si le problème persiste, signale-le.",

  "compromise_noise_warning": "ISO {value} — bruit visible. Shooter en RAW pour réduire le bruit en post.",
  "compromise_noise_critical": "Pas assez de lumière pour ces contraintes, même à ISO {maxIso}.",
  "compromise_astro_no_tripod": "L'astrophoto nécessite un trépied. Les poses longues sont impossibles à main levée.",
  "compromise_overexposure_nd": "Tu as besoin d'un filtre ND pour cette vitesse lente en plein soleil.",
  "compromise_constraints_impossible": "Tes contraintes (ISO max {isoMax}, vitesse min {shutterMin}) ne sont pas compatibles avec ces conditions.",
  "compromise_macro_distance": "Ton {lensName} a une distance min de MAP de {distance}m. Pour de la macro plus proche, un objectif macro est recommandé.",
  "compromise_focal_unusual": "Ton {lensName} ({focal}mm) est inhabituel pour le {subject}, mais peut donner des résultats intéressants."
}
```

---

## 11. Logging

### 11.1. Niveaux de log

| Niveau | Quand | Stocké | Exemple |
|--------|-------|--------|---------|
| `debug` | Développement uniquement | Non | "Parsing body.json: 12ms" |
| `info` | Événements normaux utiles au diagnostic | En mémoire (derniers 100) | "Data pack sony_a6700 v1.1 chargé" |
| `warning` | Situation dégradée mais l'app continue | En mémoire + fichier local | "Label 'fr' manquant pour focus_mode, fallback 'en'" |
| `error` | Erreur affichée à l'utilisateur | Fichier local | "DataPackCorruptedException: sony_a6700" |
| `fatal` | Crash inattendu | Fichier local + Crashlytics (V2) | "UnhandledException in CameraDataCache.load()" |

### 11.2. Log local (MVP)

```dart
// core/utils/app_logger.dart

class AppLogger {
  static final List<LogEntry> _buffer = [];
  static const _maxBuffer = 200;

  static void info(String message, {String? tag}) {
    _add(LogLevel.info, message, tag: tag);
  }

  static void warning(String message, {String? tag, Object? error}) {
    _add(LogLevel.warning, message, tag: tag, error: error);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stack}) {
    _add(LogLevel.error, message, tag: tag, error: error, stack: stack);
  }

  /// Exporte les logs récents pour le formulaire "Signaler un problème"
  static String exportForReport() {
    return _buffer
        .where((e) => e.level.index >= LogLevel.warning.index)
        .map((e) => '[${e.level.name}] ${e.timestamp} ${e.tag ?? ''}: ${e.message}')
        .join('\n');
  }

  static void _add(LogLevel level, String message, {String? tag, Object? error, StackTrace? stack}) {
    if (kDebugMode) debugPrint('[$tag] $message');
    _buffer.add(LogEntry(level: level, message: message, tag: tag, timestamp: DateTime.now()));
    if (_buffer.length > _maxBuffer) _buffer.removeAt(0);
  }
}
```

### 11.3. "Signaler un problème"

L'écran Settings a un bouton "Signaler un problème" qui génère un rapport pré-rempli :

```
--- Rapport ShootHelper ---
App version: 1.0.0
Boîtier: Sony A6700
Pack version: 1.1.0
Firmware language: fr
OS: Android 14 / iOS 17.4
Date: 2026-03-19T14:30:00

--- Logs récents (warnings/errors) ---
[warning] 2026-03-19 14:28:12 i18n: Label 'fr' manquant pour creative_look
[error] 2026-03-19 14:29:45 download: NetworkTimeoutException on /sony_a6700/lenses/...

--- Description du problème (à remplir) ---

```

MVP : copié dans le presse-papier, l'utilisateur l'envoie par email. V2 : formulaire intégré qui envoie à un endpoint.

---

## 12. Tests d'erreur

### 12.1. Scénarios de test par catégorie

| # | Catégorie | Scénario | Input | Résultat attendu |
|---|-----------|----------|-------|-----------------|
| E1 | Réseau | Download sans réseau | Mock ConnectivityService → offline | Écran "Connexion requise" |
| E2 | Réseau | Download interrompu | Mock Dio → timeout après 3 fichiers | Resume reprend au fichier 4 |
| E3 | Réseau | CDN 500 | Mock Dio → 500 | Retry × 3 puis message serveur indisponible |
| E4 | Données | JSON corrompu | body.json = "not json" | Message corruption + re-download |
| E5 | Données | Checksum invalide | Modifier 1 byte dans body.json | Détecté, re-download |
| E6 | Données | Label manquant | Supprimer labels.fr d'un item | Fallback EN affiché |
| E7 | Données | NavPath manquant | Supprimer une entrée de nav_paths | Résultat sans bouton menu nav |
| E8 | Données | Objectif manquant | Supprimer un fichier lens | Message + option re-download |
| E9 | Moteur | ISO impossible | Indoor dark + ISO max 200 + 1/1000s | Compromis critical + suggestion |
| E10 | Moteur | Astro handheld | Astro + handheld | Compromis critical + suggestion trépied |
| E11 | Moteur | Surexposition filé | Motion blur + direct sun | Warning filtre ND |
| E12 | Compat | Eye-AF absent | Boîtier sans Eye-AF + override Eye-AF | Auto-switch + info |
| E13 | Compat | Macro impossible | Very close + objectif non-macro | Warning distance MAP |
| E14 | Système | Stockage plein | Mock filesystem → ENOSPC | Message espace insuffisant |
| E15 | Système | Crash inattendu | Throw dans un provider | Catch-all → ErrorDisplay |

### 12.2. Comment tester les erreurs réseau

```dart
// test/features/data_pack/download_test.dart

void main() {
  group('Download avec erreurs réseau', () {
    test('affiche erreur réseau quand offline', () async {
      final container = ProviderContainer(overrides: [
        connectivityServiceProvider.overrideWithValue(
          MockConnectivityService(alwaysOffline: true),
        ),
      ]);

      expect(
        () => container.read(downloadDataPackProvider).execute(
          bodyId: 'sony_a6700',
          lensIds: ['sigma_18-50'],
          onProgress: (_) {},
        ),
        throwsA(isA<NoNetworkException>()),
      );
    });

    test('resume après interruption', () async {
      final mockDio = MockDio();
      // Premier appel : body.json OK
      // Deuxième appel : menu_tree.json → timeout
      when(() => mockDio.get('/sony_a6700/body.json')).thenAnswer(/* ... */);
      when(() => mockDio.get('/sony_a6700/menu_tree.json'))
          .thenThrow(DioException.connectionTimeout(/* ... */));

      // Vérifier que download_state marque body=true, menu_tree=false
      // Relancer → ne re-télécharge pas body.json
    });
  });
}
```

---

## 13. Récapitulatif — L'app ne crash jamais

```
╔══════════════════════════════════════════════════════════════════╗
║  GARANTIE : pour toute combinaison d'inputs et d'état,          ║
║  l'utilisateur voit :                                           ║
║                                                                  ║
║  1. Un résultat (même dégradé) + des compromis explicites        ║
║  OU                                                              ║
║  2. Un message d'erreur compréhensible + un bouton d'action      ║
║                                                                  ║
║  JAMAIS :                                                        ║
║  ❌ Un écran blanc                                               ║
║  ❌ Un crash                                                     ║
║  ❌ Un spinner infini                                            ║
║  ❌ Un message technique incompréhensible                        ║
║  ❌ Un état sans action possible                                 ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

*Ce document est la référence pour l'implémentation de tous les cas d'erreur. Chaque exception, chaque fallback, chaque message est documenté ici. Le skill 20 (Testing Strategy) utilisera les 15 scénarios de test de la section 12 comme base.*
