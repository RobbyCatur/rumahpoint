import 'package:go_router/go_router.dart';

import 'screens/forgot_password_screen.dart';
import 'screens/form_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/result_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/home', builder: (_, _) => const FormScreen()),
    GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/result', builder: (_, _) => const ResultScreen()),
    GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
  ],
);
