import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rumahpoint/features/prediction/data/services/location_service.dart';
import 'package:rumahpoint/features/prediction/data/services/wilayah_service.dart';
import 'package:rumahpoint/features/prediction/presentation/providers/prediction_providers.dart';
import 'package:rumahpoint/features/user/presentation/providers/user_providers.dart';
import 'package:rumahpoint/features/user/presentation/screens/region_preference_screen.dart';
import 'package:rumahpoint/features/user/presentation/screens/settings_screen.dart';

/// GPS palsu: titik pusat Kota Malang — secara poligon jelas "Malang",
/// bukan kabupaten induknya (kasus yang dulu salah karena centroid dobel).
class _LokasiPalsu extends LocationService {
  @override
  Future<({double lat, double lng})?> currentPosition() async =>
      (lat: -7.9666, lng: 112.6326);
}

/// `batas.json` (±2 MB) tidak pernah selesai dimuat di dalam zona
/// fake-async `testWidgets`, jadi dibaca lewat `runAsync` lalu disuntik
/// ke provider; logika poligonnya tetap yang asli.
Future<List<Override>> _siapkanWilayah(WidgetTester tester,
    {required bool gps}) async {
  final batas = await tester.runAsync(WilayahService.loadBatas);
  return [
    gpsPriorityProvider.overrideWith((ref) => gps),
    locationServiceProvider.overrideWithValue(_LokasiPalsu()),
    batasWilayahProvider.overrideWith((ref) => Future.value(batas)),
  ];
}

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
      'GPS aktif → wilayah terisi hasil poligon GPS dan pilihan manual dikunci',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: await _siapkanWilayah(tester, gps: true),
        child: const MaterialApp(home: RegionPreferenceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Malang, Jawa Timur'), findsWidgets);
    // Saat terkunci, panah dropdown dan tombol GPS tidak dirender.
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    expect(find.text('Gunakan Lokasi Saat Ini'), findsNothing);
  });

  testWidgets(
      'GPS nonaktif → placeholder tampil dan bottom sheet provinsi→kab/kota bisa dipakai',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gpsPriorityProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: RegionPreferenceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih wilayah'), findsOneWidget);

    await tester.tap(find.text('Pilih wilayah'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Provinsi'), findsOneWidget);

    // Langkah 2: provinsi → kab/kota (sama seperti form di Beranda).
    await tester.tap(find.text('Jawa Timur').first);
    await tester.pumpAndSettle();
    expect(find.text('Kabupaten Malang'), findsOneWidget);

    await tester.tap(find.text('Kabupaten Malang'));
    await tester.pumpAndSettle();
    expect(find.text('Kabupaten Malang, Jawa Timur'), findsOneWidget);
  });

  testWidgets(
      'RegionPreferenceScreen bereaksi saat gpsPriorityProvider berubah secara dinamis',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: await _siapkanWilayah(tester, gps: false),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RegionPreferenceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih wilayah'), findsOneWidget);

    container.read(gpsPriorityProvider.notifier).state = true;
    await tester.pumpAndSettle();
    expect(find.text('Malang, Jawa Timur'), findsWidgets);

    container.read(gpsPriorityProvider.notifier).state = false;
    await tester.pumpAndSettle();
    expect(find.text('Pilih wilayah'), findsOneWidget);
  });
}
