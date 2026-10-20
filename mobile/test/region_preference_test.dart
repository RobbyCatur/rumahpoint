import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumahpoint/features/user/presentation/providers/user_providers.dart';
import 'package:rumahpoint/features/user/presentation/screens/region_preference_screen.dart';
import 'package:rumahpoint/features/user/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen dapat mengubah gpsPriorityProvider',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(gpsPriorityProvider), isFalse);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final gpsToggle =
        find.widgetWithText(SwitchListTile, 'Prioritaskan Lokasi GPS');
    expect(gpsToggle, findsOneWidget);

    await tester.tap(gpsToggle);
    await tester.pumpAndSettle();

    expect(container.read(gpsPriorityProvider), isTrue);
  });

  testWidgets(
      'RegionPreferenceScreen menampilkan Surabaya saat GPS aktif dan kunci dropdown',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gpsPriorityProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(home: RegionPreferenceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.initialValue, 'Surabaya');
    expect(dropdown.onChanged, isNull);
    expect(find.text('Surabaya'), findsWidgets);
  });

  testWidgets(
      'RegionPreferenceScreen bernilai null dan menampilkan hint saat GPS nonaktif',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gpsPriorityProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: RegionPreferenceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.initialValue, isNull);
    expect(dropdown.onChanged, isNotNull);
    expect(find.text('Pilih Wilayah'), findsOneWidget);
  });

  testWidgets(
      'RegionPreferenceScreen bereaksi saat gpsPriorityProvider berubah secara dinamis',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RegionPreferenceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih Wilayah'), findsOneWidget);

    container.read(gpsPriorityProvider.notifier).state = true;
    await tester.pumpAndSettle();

    expect(find.text('Surabaya'), findsWidgets);

    container.read(gpsPriorityProvider.notifier).state = false;
    await tester.pumpAndSettle();

    expect(find.text('Pilih Wilayah'), findsOneWidget);
  });
}
