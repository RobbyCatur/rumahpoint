import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'state/prediction_controller.dart';

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
      title: 'Rumah Point',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFFFB817),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
