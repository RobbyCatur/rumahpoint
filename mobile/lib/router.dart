import 'package:go_router/go_router.dart';

import 'screens/form_screen.dart';
import 'screens/history_screen.dart';
import 'screens/result_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const FormScreen()),
    GoRoute(path: '/result', builder: (_, _) => const ResultScreen()),
    GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
  ],
);
