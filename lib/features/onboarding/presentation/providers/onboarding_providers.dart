import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/entities/catalog.dart';

/// Selected body ID during onboarding.
final selectedBodyIdProvider = StateProvider<String?>((ref) => null);

/// Selected lens IDs during onboarding (can select multiple).
final selectedLensIdsProvider = StateProvider<List<String>>((ref) => []);

/// Selected firmware language during onboarding.
final selectedLanguageProvider = StateProvider<String?>((ref) => null);

/// Catalog data loaded from the CDN.
final catalogProvider = StateProvider<Catalog?>((ref) => null);

/// Download progress: (current, total).
final downloadProgressProvider =
    StateProvider<({int current, int total})>((ref) => (current: 0, total: 0));

/// Download status.
enum DownloadStatus { idle, downloading, complete, error }

final downloadStatusProvider =
    StateProvider<DownloadStatus>((ref) => DownloadStatus.idle);

/// Download error message.
final downloadErrorProvider = StateProvider<String?>((ref) => null);
