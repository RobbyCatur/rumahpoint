import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/prediction/presentation/providers/prediction_providers.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: RumahPointApp()));
}

class RumahPointApp extends ConsumerStatefulWidget {
  const RumahPointApp({super.key});

  @override
  ConsumerState<RumahPointApp> createState() => _RumahPointAppState();
}

class _RumahPointAppState extends ConsumerState<RumahPointApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(predictionControllerProvider.notifier).loadHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'RumahPoint',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

