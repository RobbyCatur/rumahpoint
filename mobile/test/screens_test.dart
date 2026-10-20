import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumahpoint/core/failures.dart';
import 'package:rumahpoint/features/prediction/domain/entities/prediction.dart';
import 'package:rumahpoint/features/prediction/domain/repositories/prediction_repository.dart';
import 'package:rumahpoint/features/prediction/domain/usecases/get_prediction_history.dart';
import 'package:rumahpoint/features/prediction/presentation/controllers/prediction_controller.dart';
import 'package:rumahpoint/features/prediction/presentation/providers/prediction_providers.dart';
import 'package:rumahpoint/screens/history_screen.dart';
import 'package:rumahpoint/screens/result_screen.dart';

/// Repository palsu: tidak menyentuh Dio/SharedPreferences.
class _FakeRepository implements PredictionRepository {
  @override
  Future<({Prediction? prediction, Failure? failure})> predict({
    required double luasM2,
    required double luasBangunan,
    required int jumlahKamar,
    required int jumlahKamarMandi,
    required int usiaBangunan,
    required String kondisi,
    required String lokasi,
    required String provinsi,
    required bool lokasiDidukung,
  }) async =>
      (prediction: null, failure: null);

  @override
  Future<({List<Prediction> history, Failure? failure})> getHistory() async =>
      (history: const <Prediction>[], failure: null);

  @override
  Future<Failure?> saveHistory(List<Prediction> history) async => null;

  @override
  Future<Failure?> clearHistory() async => null;

  @override
  Future<Map<String, dynamic>?> loadDraft() async => null;

  @override
  Future<void> saveDraft(Map<String, dynamic> draft) async {}
}

final _fake = Prediction(
  luasM2: 120,
  luasBangunan: 98,
  jumlahKamar: 3,
  jumlahKamarMandi: 2,
  usiaBangunan: 10,
  kondisi: 'Bekas',
  lokasi: 'Jakarta Selatan',
  provinsi: 'DKI Jakarta',
  lokasiDidukung: true,
  estimasiHarga: 1520000000,
  estimasiString: 'Rp 1,52 Miliar',
  rentangBawah: 'Rp 1,14 Miliar',
  rentangAtas: 'Rp 1,90 Miliar',
  kategori: 'Mahal',
  confidence: 0.952,
  createdAt: DateTime(2025, 9, 12),
);

class _FakeController extends PredictionController {
  _FakeController(PredictionState seed)
      : super(_FakeRepository(), GetPredictionHistory(_FakeRepository())) {
    state = seed;
  }
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      predictionControllerProvider.overrideWith(
        (ref) => _FakeController(PredictionState(current: _fake, history: [_fake])),
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

    expect(find.text('Jakarta Selatan, DKI Jakarta'), findsOneWidget);
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
      kondisi: 'Bekas',
      lokasi: 'Bekasi',
      provinsi: 'Jawa Barat',
      lokasiDidukung: true,
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
    expect(find.text('Bekasi, Jawa Barat'), findsOneWidget);
    expect(find.text('Jakarta Selatan, DKI Jakarta'), findsNothing);
    expect(find.text('September 2025'), findsNothing);
    expect(find.text('Agustus 2025'), findsOneWidget);
  });
}
