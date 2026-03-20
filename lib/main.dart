import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'shared/data/data_sources/local/gear_profile_store.dart';
import 'shared/presentation/providers/gear_profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch-all for Flutter framework errors
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  // Catch-all for async Dart errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error');
    debugPrint('Stack: $stack');
    return true;
  };

  final prefs = await SharedPreferences.getInstance();

  // Migrate legacy single-profile to multi-profile store
  final store = GearProfileStore(prefs);
  await store.migrateFromLegacy();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
