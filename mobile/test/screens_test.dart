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
  });
}
