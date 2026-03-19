import 'package:go_router/go_router.dart';
import '../../features/scene_input/presentation/screens/home_screen.dart';
import '../../features/scene_input/presentation/screens/scene_input_screen.dart';
import '../../features/results/presentation/screens/results_screen.dart';
import '../../features/results/presentation/screens/setting_detail_screen.dart';
import '../../features/menu_nav/presentation/screens/menu_navigation_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
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
  ],
);
