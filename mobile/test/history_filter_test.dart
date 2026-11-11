import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumahpoint/core/failures.dart';
import 'package:rumahpoint/features/prediction/domain/entities/prediction.dart';
import 'package:rumahpoint/features/prediction/domain/repositories/prediction_repository.dart';
import 'package:rumahpoint/features/prediction/domain/usecases/get_prediction_history.dart';
import 'package:rumahpoint/features/prediction/presentation/controllers/prediction_controller.dart';
import 'package:rumahpoint/features/prediction/presentation/providers/prediction_providers.dart';
import 'package:rumahpoint/features/prediction/presentation/widgets/history_filter_dialog.dart';
import 'package:rumahpoint/screens/history_screen.dart';

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
  }) async => (prediction: null, failure: null);

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

class _FakeController extends PredictionController {
  _FakeController(PredictionState seed)
    : super(_FakeRepository(), GetPredictionHistory(_FakeRepository())) {
    state = seed;
  }
}

Prediction _prediction({
  required DateTime createdAt,
  String kategori = 'Mahal',
  String lokasi = 'Jakarta Selatan',
  String provinsi = 'DKI Jakarta',
}) {
  return Prediction(
    luasM2: 120,
    luasBangunan: 98,
    jumlahKamar: 3,
    jumlahKamarMandi: 2,
    usiaBangunan: 10,
    kondisi: 'Bekas',
    lokasi: lokasi,
    provinsi: provinsi,
    lokasiDidukung: true,
    estimasiHarga: 1520000000,
    estimasiString: 'Rp 1,52 Miliar',
    rentangBawah: 'Rp 1,14 Miliar',
    rentangAtas: 'Rp 1,90 Miliar',
    kategori: kategori,
    confidence: 0.952,
    createdAt: createdAt,
  );
}

Widget _wrap(List<Prediction> history) {
  return ProviderScope(
    overrides: [
      predictionControllerProvider.overrideWith(
        (ref) => _FakeController(
          PredictionState(current: history.first, history: history),
        ),
      ),
    ],
    child: const MaterialApp(home: HistoryScreen()),
  );
}

void main() {
  group('HistoryFilter.matches', () {
    final p = _prediction(createdAt: DateTime(2025, 9, 12));

    test('menyaring kategori', () {
      expect(const HistoryFilter(kategori: 'Mahal').matches(p), isTrue);
      expect(const HistoryFilter(kategori: 'Murah').matches(p), isFalse);
    });

    test('menyaring lokasi memakai label lengkap', () {
      expect(
        const HistoryFilter(lokasi: 'Jakarta Selatan, DKI Jakarta').matches(p),
        isTrue,
      );
      expect(
        const HistoryFilter(lokasi: 'Bekasi, Jawa Barat').matches(p),
        isFalse,
      );
    });

    test('rentang tanggal inklusif di kedua ujung', () {
      final range = DateTimeRange(
        start: DateTime(2025, 9, 12),
        end: DateTime(2025, 9, 12),
      );
      expect(HistoryFilter(tanggal: range).matches(p), isTrue);

      final outside = DateTimeRange(
        start: DateTime(2025, 8, 1),
        end: DateTime(2025, 8, 31),
      );
      expect(HistoryFilter(tanggal: outside).matches(p), isFalse);
    });

    test('pencarian mencakup lokasi dan provinsi', () {
      expect(const HistoryFilter().matchesQuery(p, 'jakarta'), isTrue);
      expect(const HistoryFilter().matchesQuery(p, 'dki'), isTrue);
      expect(const HistoryFilter().matchesQuery(p, 'bandung'), isFalse);
      expect(const HistoryFilter().matchesQuery(p, '  '), isTrue);
    });
  });

  testWidgets('Filter tanpa hasil menampilkan pesan dan bisa direset', (
    tester,
  ) async {
    final mahal = _prediction(createdAt: DateTime(2025, 9, 12));
    await tester.pumpWidget(_wrap([mahal]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Murah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada hasil'), findsOneWidget);
    expect(
      find.text('Tidak ada riwayat yang cocok dengan filter atau pencarianmu.'),
      findsOneWidget,
    );
    expect(find.text('Jakarta Selatan, DKI Jakarta'), findsNothing);

    await tester.tap(find.text('Atur ulang filter'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada hasil'), findsNothing);
    expect(find.text('Jakarta Selatan, DKI Jakarta'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
  });

  testWidgets('Filter membuka pemilih rentang tanggal', (tester) async {
    final mahal = _prediction(createdAt: DateTime(2025, 9, 12));
    await tester.pumpWidget(_wrap([mahal]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Semua tanggal'), findsOneWidget);

    await tester.tap(find.text('Semua tanggal'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih rentang tanggal'), findsOneWidget);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Filter Riwayat'), findsOneWidget);
    expect(find.text('Semua tanggal'), findsOneWidget);
  });
}
