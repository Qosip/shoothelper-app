import 'exceptions.dart';

enum FailureAction { retry, goToSettings, goToStore, reportBug, dismiss }

sealed class Failure {
  final String userMessage;
  final String? actionLabel;
  final FailureAction? action;
  const Failure(this.userMessage, {this.actionLabel, this.action});
}

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
          "Une mise à jour de l'app est nécessaire pour utiliser les dernières données.",
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

/// Maps any exception to the appropriate Failure for the UI layer.
Failure mapToFailure(Object error) => switch (error) {
      NoNetworkException() || NetworkTimeoutException() => const NetworkFailure(),
      ServerException() => const NetworkFailure(),
      DataPackNotFoundException() => const DataNotReadyFailure(),
      DataPackCorruptedException() || DataPackIncompleteException() => const CorruptedDataFailure(),
      LensNotFoundException() || IncompatibleLensException() => const GearMissingFailure(),
      StorageFullException() || FilePermissionException() => const UnknownFailure(),
      UnexpectedException() => const UnknownFailure(),
      ShootHelperException() => const UnknownFailure(),
      _ => const UnknownFailure(),
    };
