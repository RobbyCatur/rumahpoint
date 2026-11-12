import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rumahpoint/main.dart';
import 'package:rumahpoint/router.dart';

const _allSeen = <String, Object>{
  'rp_tutorial_v1_beranda': true,
  'rp_tutorial_v1_riwayat': true,
  'rp_tutorial_v1_profil': true,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('Panduan muncul sekali di tiap halaman dan bisa dilewati', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    useTallSurface(tester);

    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    // Beranda: tiga langkah, selesai sampai akhir.
    router.go('/beranda');
    await tester.pumpAndSettle();
    expect(find.text('Panduan Beranda'), findsOneWidget);
    expect(find.text('Isi detail properti'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Tentukan lokasi'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Hitung valuasi'), findsOneWidget);

    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Panduan Beranda'), findsNothing);

    // Riwayat: lewati, status tetap tersimpan.
    router.go('/riwayat');
    await tester.pumpAndSettle();
    expect(find.text('Panduan Riwayat'), findsOneWidget);
    expect(find.text('Riwayat tersimpan otomatis'), findsOneWidget);

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Panduan Riwayat'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('rp_tutorial_v1_beranda'), isTrue);
    expect(prefs.getBool('rp_tutorial_v1_riwayat'), isTrue);

    // Kembali ke Beranda: panduan tidak muncul lagi.
    router.go('/beranda');
    await tester.pumpAndSettle();
    expect(find.text('Panduan Beranda'), findsNothing);
  });

  testWidgets('Panduan Profil tampil dan bisa diputar ulang dari menu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_allSeen);
    useTallSurface(tester);

    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    router.go('/profil');
    await tester.pumpAndSettle();

    // Karena sudah pernah dilihat, panduan otomatis tidak muncul.
    expect(find.text('Panduan Profil'), findsNothing);

    await tester.ensureVisible(find.text('Panduan Aplikasi'));
    await tester.tap(find.text('Panduan Aplikasi'));
    await tester.pumpAndSettle();

    expect(
      find.text('Putar ulang panduan singkat untuk tiap halaman.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Panduan Riwayat'));
    await tester.pumpAndSettle();

    expect(find.text('Panduan Riwayat'), findsOneWidget);
    expect(find.text('Riwayat tersimpan otomatis'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Saring dengan satu tombol'), findsOneWidget);

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Panduan Riwayat'), findsNothing);
  });
}
