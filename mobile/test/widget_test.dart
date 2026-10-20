import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rumahpoint/main.dart';
import 'package:rumahpoint/router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Surface tinggi agar seluruh konten ListView beranda ter-build.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('Onboarding menjelaskan RumahPoint dan menuju login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang di\nRumahPoint'), findsOneWidget);
    expect(find.text('Prediksi harga properti'), findsOneWidget);
    expect(find.text('Mulai Sekarang'), findsOneWidget);

    await tester.tap(find.text('Mulai Sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
  });

  testWidgets('Beranda renders sapaan, banner, form, and bottom nav',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    useTallSurface(tester);
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    // App kini mendarat di LoginScreen ('/') — navigasi dulu ke beranda.
    router.go('/beranda');
    await tester.pumpAndSettle();

    expect(find.text('Berapa harga wajar rumah impianmu?'), findsOneWidget);
    expect(find.text('Mulai Hitung Valuasi'), findsOneWidget);
    expect(find.text('Kalkulasi Nilai Pasar Properti'), findsOneWidget);
    expect(find.text('Hitung Valuasi Sekarang'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });

  testWidgets('CTA sapaan menggulir ke fitur utama',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    router.go('/beranda');
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.text('Kalkulasi Nilai Pasar Properti'));

    await tester.tap(find.text('Mulai Hitung Valuasi'));
    await tester.pumpAndSettle();

    // Banner bergeser ke atas dan tombol prediksi kini terlihat.
    final after = tester.getTopLeft(find.text('Kalkulasi Nilai Pasar Properti'));
    expect(after.dy, lessThan(before.dy));
    expect(find.text('Hitung Valuasi Sekarang'), findsOneWidget);
  });

  testWidgets('Draft tersimpan otomatis dan dimuat kembali saat restart',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    useTallSurface(tester);
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    router.go('/beranda');
    await tester.pumpAndSettle();

    // Ubah input: ketik luas float (koma) & stepper manual.
    await tester.enterText(
        find.widgetWithText(TextField, '120'), '120,5');
    await tester.enterText(find.widgetWithText(TextField, '3'), '4');
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final draft =
        Map<String, dynamic>.from(jsonDecode(prefs.getString('rp_draft')!));
    expect(draft['lt'], 120.5);
    expect(draft['kamar'], 4);

    // Simulasi restart app: widget tree dibangun ulang dari draft tersimpan.
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '120,5'), findsOneWidget);
    expect(find.widgetWithText(TextField, '4'), findsOneWidget);
  });

  testWidgets('Input manual di-clamp ke rentang yang valid',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    useTallSurface(tester);
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    router.go('/beranda');
    await tester.pumpAndSettle();

    // Luas di atas maksimum → clamp 500. Stepper di atas maksimum → clamp 10.
    await tester.enterText(find.widgetWithText(TextField, '120'), '9999');
    await tester.enterText(find.widgetWithText(TextField, '3'), '99');
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final draft =
        Map<String, dynamic>.from(jsonDecode(prefs.getString('rp_draft')!));
    expect(draft['lt'], 500.0);
    expect(draft['kamar'], 10);
  });

  testWidgets('Picker wilayah: provinsi tampil tanpa overflow, navigasi ke kab/kota',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    useTallSurface(tester);
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    router.go('/beranda');
    await tester.pumpAndSettle();

    // Buka bottom sheet pemilih wilayah.
    await tester.tap(find.text('Pilih kabupaten/kota'));
    await tester.pumpAndSettle();

    // Langkah 1: daftar provinsi (subtitle "N kab/kota" tidak overflow).
    expect(find.text('Pilih Provinsi'), findsOneWidget);
    expect(find.text('Aceh'), findsOneWidget);
    expect(find.text('Jawa Barat'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Langkah 2: masuk ke kab/kota Jawa Barat.
    await tester.tap(find.text('Jawa Barat').first);
    await tester.pumpAndSettle();
    expect(find.text('Bekasi'), findsOneWidget);

    // Pilih Bekasi → sheet tertutup, label form terisi.
    await tester.tap(find.text('Bekasi'));
    await tester.pumpAndSettle();
    expect(find.text('Bekasi, Jawa Barat'), findsOneWidget);

    // Draft ikut menyimpan wilayah terpilih.
    final prefs = await SharedPreferences.getInstance();
    final draft =
        Map<String, dynamic>.from(jsonDecode(prefs.getString('rp_draft')!));
    expect(draft['kabKota'], 'Bekasi');
    expect(draft['provinsi'], 'Jawa Barat');
  });
}
