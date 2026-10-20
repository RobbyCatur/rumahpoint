import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rumahpoint/features/prediction/data/services/location_service.dart';
import 'package:rumahpoint/features/prediction/data/services/wilayah_service.dart';
import 'package:rumahpoint/features/prediction/presentation/providers/prediction_providers.dart';
import 'package:rumahpoint/features/user/presentation/providers/user_providers.dart';
import 'package:rumahpoint/features/user/presentation/screens/region_preference_screen.dart';
import 'package:rumahpoint/screens/home_screen.dart';

/// GPS palsu: titik pusat Kota Malang.
class _GpsMalang extends LocationService {
  @override
  Future<({double lat, double lng})?> currentPosition() async =>
      (lat: -7.9666, lng: 112.6326);
}

/// Preferensi wilayah: disimpan dari Profil, dipakai sebagai nilai awal
/// form di Beranda.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Buka bottom sheet, pilih provinsi, lalu cari kab/kota (daftaranya
  /// digulir, jadi diketik saja daripada digulir manual).
  Future<void> pilihWilayah(WidgetTester tester,
      {required String provinsi, required String kabKota}) async {
    await tester.tap(find.text('Pilih wilayah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(provinsi).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), kabKota);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, kabKota));
    await tester.pumpAndSettle();
  }

  testWidgets('Simpan di Profil → tertulis ke penyimpanan dan Beranda memakainya',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    useTallSurface(tester);

    final container = ProviderContainer(
      overrides: [gpsPriorityProvider.overrideWith((ref) => false)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RegionPreferenceScreen()),
    ));
    await tester.pumpAndSettle();

    await pilihWilayah(tester, provinsi: 'Jawa Timur', kabKota: 'Malang');
    expect(find.text('Malang, Jawa Timur'), findsOneWidget);

    await tester.tap(find.text('Simpan Preferensi'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final tersimpan =
        jsonDecode(prefs.getString('rp_preferensi_wilayah')!) as Map<String, dynamic>;
    expect(tersimpan['nama'], 'Malang');
    expect(tersimpan['provinsi'], 'Jawa Timur');

    // Sesi baru (aplikasi ditutup lalu dibuka lagi): tree dan container
    // dibangun ulang, dan form Beranda memakai preferensi dari penyimpanan
    // — bukan deteksi GPS, bukan draft angka.
    await tester.pumpWidget(const SizedBox());
    final containerBaru = ProviderContainer(
      overrides: [gpsPriorityProvider.overrideWith((ref) => false)],
    );
    addTearDown(containerBaru.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: containerBaru,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Malang, Jawa Timur'), findsOneWidget);
  });

  testWidgets('Beranda mengikuti perubahan preferensi & kembali ke preferensi '
      'setelah dibuka ulang meski pernah diubah manual', (tester) async {
    SharedPreferences.setMockInitialValues({
      'rp_preferensi_wilayah':
          jsonEncode({'nama': 'Malang', 'provinsi': 'Jawa Timur'}),
    });
    useTallSurface(tester);

    final container = ProviderContainer(
      overrides: [gpsPriorityProvider.overrideWith((ref) => false)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Malang, Jawa Timur'), findsOneWidget);

    // Ganti preferensi di Profil → Beranda yang sedang terbuka langsung ikut.
    final surabaya = WilayahService.cari(
      await container.read(wilayahProvider.future),
      'Surabaya',
      'Jawa Timur',
    );
    expect(surabaya, isNotNull);
    await container.read(wilayahPreferenceProvider.notifier).simpan(surabaya!);
    await tester.pumpAndSettle();
    expect(find.text('Surabaya, Jawa Timur'), findsOneWidget);

    // Ubah manual di Beranda: hanya berlaku selama sesi ini.
    await tester.tap(find.text('Surabaya, Jawa Timur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jawa Barat').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bekasi'));
    await tester.pumpAndSettle();
    expect(find.text('Bekasi, Jawa Barat'), findsOneWidget);

    // Sesi baru → kembali ke preferensi Profil (Surabaya), bukan Bekasi.
    final containerBaru = ProviderContainer(
      overrides: [gpsPriorityProvider.overrideWith((ref) => false)],
    );
    addTearDown(containerBaru.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: containerBaru,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Surabaya, Jawa Timur'), findsOneWidget);
  });

  testWidgets('Preferensi tersimpan tapi namanya tidak dikenal lagi → '
      'Beranda tidak memaksa dan tetap memberi ruang deteksi GPS',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'rp_preferensi_wilayah':
          jsonEncode({'nama': 'Kota Unknown', 'provinsi': 'Provinsi Unknown'}),
    });
    useTallSurface(tester);

    final container = ProviderContainer(
      overrides: [gpsPriorityProvider.overrideWith((ref) => false)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();

    expect(container.read(wilayahPreferenceProvider), isNull);
    expect(find.text('Pilih kabupaten/kota'), findsOneWidget);
  });

  testWidgets('Sakelar prioritas GPS mengambil alih Beranda seketika, '
      'dan Beranda kembali ke preferensi saat sakelar dimatikan',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'rp_preferensi_wilayah':
          jsonEncode({'nama': 'Surabaya', 'provinsi': 'Jawa Timur'}),
    });
    useTallSurface(tester);

    // `batas.json` (±2 MB) tidak selesai dimuat di dalam zona fake-async,
    // jadi dibaca lewat runAsync lalu disuntik; logika poligonnya tetap asli.
    final batas = await tester.runAsync(WilayahService.loadBatas);
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(_GpsMalang()),
        batasWilayahProvider.overrideWith((ref) => Future.value(batas)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Surabaya, Jawa Timur'), findsOneWidget);

    // Nyalakan prioritas GPS di Profil → Beranda ikut posisi perangkat.
    container.read(gpsPriorityProvider.notifier).state = true;
    await tester.pumpAndSettle();
    expect(find.text('Malang, Jawa Timur'), findsOneWidget);

    // Matikan → Beranda kembali mengikuti preferensi Profil.
    container.read(gpsPriorityProvider.notifier).state = false;
    await tester.pumpAndSettle();
    expect(find.text('Surabaya, Jawa Timur'), findsOneWidget);
  });
}
