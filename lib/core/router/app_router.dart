import 'package:go_router/go_router.dart';
import '../../features/scene_input/presentation/screens/home_screen.dart';
import '../../features/scene_input/presentation/screens/scene_input_screen.dart';
import '../../features/results/presentation/screens/results_screen.dart';
import '../../features/results/presentation/screens/setting_detail_screen.dart';
import '../../features/menu_nav/presentation/screens/menu_navigation_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/body_selection_screen.dart';
import '../../features/onboarding/presentation/screens/lens_selection_screen.dart';
import '../../features/onboarding/presentation/screens/language_screen.dart';
import '../../features/onboarding/presentation/screens/download_screen.dart';
import '../../shared/data/data_sources/local/gear_profile_source.dart';

GoRouter createRouter(GearProfileSource gearProfile) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isOnboarding =
          state.matchedLocation.startsWith('/onboarding');
      final isComplete = gearProfile.isOnboardingComplete;

      // Not onboarded yet → force onboarding
      if (!isComplete && !isOnboarding) {
        return '/onboarding';
      }
      // Already onboarded → skip onboarding
      if (isComplete && isOnboarding) {
        return '/';
      }
      return null;
    },
    routes: [
      // Main app routes
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/scene-input',
        builder: (context, state) => const SceneInputScreen(),
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) => const ResultsScreen(),
        routes: [
          GoRoute(
            path: 'setting/:settingId',
            builder: (context, state) => SettingDetailScreen(
              settingId: state.pathParameters['settingId']!,
            ),
            routes: [
              GoRoute(
                path: 'menu-nav',
                builder: (context, state) => MenuNavigationScreen(
                  settingId: state.pathParameters['settingId']!,
                ),
              ),
            ],
          ),
        ],
      ),

      // Onboarding routes
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'body',
            builder: (context, state) => const BodySelectionScreen(),
          ),
          GoRoute(
            path: 'lens',
            builder: (context, state) => const LensSelectionScreen(),
          ),
          GoRoute(
            path: 'language',
            builder: (context, state) => const LanguageScreen(),
          ),
          GoRoute(
            path: 'download',
            builder: (context, state) => const DownloadScreen(),
          ),
        ],
      ),
    ],
  );
}
