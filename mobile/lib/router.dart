import 'package:go_router/go_router.dart';

import 'features/tutorial/domain/tutorial_page.dart';
import 'features/tutorial/presentation/tutorial_gate.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'features/user/presentation/screens/profile_screen.dart';
import 'screens/result_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/beranda',
              builder: (_, _) => const TutorialGate(
                page: TutorialPage.beranda,
                child: HomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/riwayat',
              builder: (_, _) => const TutorialGate(
                page: TutorialPage.riwayat,
                child: HistoryScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profil',
              builder: (_, _) => const TutorialGate(
                page: TutorialPage.profil,
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/hasil', builder: (_, _) => const ResultScreen()),
  ],
);
