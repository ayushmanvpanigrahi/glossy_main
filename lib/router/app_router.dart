import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../library/home_screen.dart';
import '../settings/presentation/screens/account/plan_screen.dart';
import '../settings/presentation/screens/account/profile_screen.dart';
import '../settings/presentation/screens/ai_config/ai_provider_screen.dart';
import '../settings/presentation/screens/ai_config/api_keys_screen.dart';
import '../settings/presentation/screens/ai_config/custom_prompt_template_screen.dart';
import '../settings/presentation/screens/ai_config/preferred_model_screen.dart';
import '../settings/presentation/screens/ai_config/rag_book_qna_screen.dart';
import '../settings/presentation/screens/ai_config/service_health_screen.dart';
import '../settings/presentation/screens/general/help_and_about_screen.dart';
import '../settings/presentation/screens/general/language_screen.dart';
import '../settings/presentation/screens/general/notification_screen.dart';
import '../settings/presentation/screens/general/privacy_and_data_screen.dart';
import '../settings/presentation/screens/reader/appearances_screen.dart';
import '../settings/presentation/screens/reader/reading_stats_screen.dart';
import '../settings/presentation/screens/settings_screen.dart';
import 'app_routes.dart';
import 'root_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.library,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RootScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SettingsScreen()),
                routes: [
                  GoRoute(
                    path: SettingsRoutes.profile,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.plan,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PlanScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.apiKeys,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ApiKeysScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.preferredModel,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PreferredModelScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.aiProvider,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AiProviderScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.customPrompt,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const CustomPromptTemplateScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.rag,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const RagBookQnaScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.serviceHealth,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ServiceHealthScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.appearances,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AppearancesScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.readingStats,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ReadingStatsScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.notifications,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const NotificationScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.language,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const LanguageScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.privacy,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PrivacyAndDataScreen(),
                  ),
                  GoRoute(
                    path: SettingsRoutes.help,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const HelpAndAboutScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
