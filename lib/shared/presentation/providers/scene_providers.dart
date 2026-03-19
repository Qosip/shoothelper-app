import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scene_input.dart';
import '../../domain/entities/settings_result.dart';
import '../../../features/settings_engine/domain/engine/settings_engine.dart';
import 'gear_providers.dart';

/// Submitted scene input (set when user taps "Calculer").
final submittedSceneProvider =
    StateProvider<SceneInput?>((ref) => null);

/// Computed settings result — auto-recalculates when scene or gear changes.
final settingsResultProvider = Provider<AsyncValue<SettingsResult?>>((ref) {
  final scene = ref.watch(submittedSceneProvider);
  if (scene == null) return const AsyncValue.data(null);

  final bodyAsync = ref.watch(currentBodyProvider);
  final lensAsync = ref.watch(currentLensProvider);

  return bodyAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
    data: (body) => lensAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
      data: (lens) {
        const engine = SettingsEngine();
        final result = engine.calculate(body, lens, scene);
        return AsyncValue.data(result);
      },
    ),
  );
});
