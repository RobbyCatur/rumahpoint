import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumahpoint/api/client.dart';
import 'package:rumahpoint/models/prediction.dart';
import 'package:rumahpoint/screens/history_screen.dart';
import 'package:rumahpoint/screens/result_screen.dart';
import 'package:rumahpoint/state/prediction_controller.dart';

final _fake = Prediction(
  luasM2: 120,
  luasBangunan: 98,
  jumlahKamar: 3,
  jumlahKamarMandi: 2,
  usiaBangunan: 10,
  lokasi: 'Jakarta Selatan',
  estimasiHarga: 1520000000,
  estimasiString: 'Rp 1,52 Miliar',
  rentangBawah: 'Rp 1,14 Miliar',
  rentangAtas: 'Rp 1,90 Miliar',
  kategori: 'Mahal',
  confidence: 0.952,
  createdAt: DateTime(2025, 9, 12),
);

class _FakeController extends PredictionController {
  _FakeController(super.api, PredictionState seed) {
    state = seed;
  }
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      predictionControllerProvider.overrideWith(
        (ref) => _FakeController(
          ApiClient(),
          PredictionState(current: _fake, history: [_fake]),
        ),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('ResultScreen menampilkan harga, rentang, dan keyakinan',
      (tester) async {
    await tester.pumpWidget(_wrap(const ResultScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Rp 1.520.000.000'), findsOneWidget);
    expect(find.textContaining('Rentang:'), findsOneWidget);
    expect(find.text('95,2%'), findsOneWidget);
    expect(find.text('Jakarta Selatan'), findsWidgets);
  });

  testWidgets('HistoryScreen menampilkan kartu riwayat dan filter',
      (tester) async {
    await tester.pumpWidget(_wrap(const HistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Jakarta Selatan'), findsOneWidget);
    expect(find.text('Rp 1,52 Miliar'), findsOneWidget);
    expect(find.text('Semua (1)'), findsOneWidget);
    expect(find.text('12 Sep 2025'), findsOneWidget);
    // Badge kategori & header bulan.
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    expect(find.text('September 2025'), findsOneWidget);
  });

  testWidgets('HistoryScreen mengelompokkan per bulan dan filter bulan',
      (tester) async {
    final murahLama = Prediction(
      luasM2: 60,
      luasBangunan: 45,
      jumlahKamar: 2,
      jumlahKamarMandi: 1,
      usiaBangunan: 15,
      lokasi: 'Bekasi',
      estimasiHarga: 350000000,
      estimasiString: 'Rp 350 Juta',
      rentangBawah: '',
      rentangAtas: '',
      kategori: 'Murah',
      confidence: 0.9,
      createdAt: DateTime(2025, 8, 3),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          predictionControllerProvider.overrideWith(
            (ref) => _FakeController(
              ApiClient(),
              PredictionState(current: _fake, history: [murahLama, _fake]),
            ),
          ),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Dua grup bulan + chip filter bulan tampil.
    expect(find.text('September 2025'), findsOneWidget);
    expect(find.text('Agustus 2025'), findsOneWidget);
    expect(find.text('Semua bulan'), findsOneWidget);
    expect(find.text('Sep 2025'), findsOneWidget);
    // Badge Murah pakai ikon turun.
    expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);

    // Filter ke Agustus 2025: hanya item Bekasi yang tampil.
    await tester.tap(find.text('Agu 2025'));
    await tester.pumpAndSettle();
    expect(find.text('Bekasi'), findsOneWidget);
    expect(find.text('Jakarta Selatan'), findsNothing);
    expect(find.text('September 2025'), findsNothing);
    expect(find.text('Agustus 2025'), findsOneWidget);
  });
}
