import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rumahpoint/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Beranda renders banner, form, and bottom nav',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    expect(find.text('Kalkulasi Nilai Pasar Properti'), findsOneWidget);
    expect(find.text('Hitung Valuasi Sekarang'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });

  testWidgets('Draft tersimpan otomatis dan dimuat kembali saat restart',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
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
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
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
}
