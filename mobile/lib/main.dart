import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/prediction/presentation/providers/prediction_providers.dart';
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
    return MaterialApp.router(
      title: 'RumahPoint',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
