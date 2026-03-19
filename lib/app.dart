import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'shared/presentation/providers/gear_profile_provider.dart';
import 'shared/presentation/theme/app_theme.dart';

/// GoRouter instance — created once based on gear profile.
final routerProvider = Provider((ref) {
  final gearProfile = ref.watch(gearProfileProvider);
  return createRouter(gearProfile);
});

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ShootHelper',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
