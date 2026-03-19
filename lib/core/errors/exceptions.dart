/// Base de toutes les exceptions ShootHelper
sealed class ShootHelperException implements Exception {
  final String message;
  final String? debugInfo;
  const ShootHelperException(this.message, {this.debugInfo});

  @override
  String toString() => '$runtimeType: $message';
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
      : super("Données de l'objectif introuvables");
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
      : super("Pas assez d'espace de stockage");
}

class FilePermissionException extends ShootHelperException {
  const FilePermissionException()
      : super("Impossible d'accéder au stockage");
}

class UnexpectedException extends ShootHelperException {
  final Object originalError;
  const UnexpectedException(this.originalError)
      : super('Une erreur inattendue est survenue');
}
