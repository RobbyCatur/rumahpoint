import 'package:flutter_test/flutter_test.dart';

import 'package:rumahpoint/core/failures.dart';
import 'package:rumahpoint/features/prediction/domain/entities/prediction.dart';
import 'package:rumahpoint/features/prediction/domain/repositories/prediction_repository.dart';
import 'package:rumahpoint/features/prediction/domain/usecases/get_prediction_history.dart';

/// Repository palsu — domain diuji murni tanpa Dio/SharedPreferences.
class FakePredictionRepository implements PredictionRepository {
  FakePredictionRepository({this.items = const [], this.fail = false});

  final List<Prediction> items;
  final bool fail;

  @override
  Future<({List<Prediction> history, Failure? failure})> getHistory() async {
    if (fail) {
      return (
        history: const <Prediction>[],
        failure: const LocalFailure('cache corrupt (simulasi)'),
      );
    }
    return (history: items, failure: null);
  }

  @override
  Future<({Prediction? prediction, Failure? failure})> predict({
    required double luasM2,
    required double luasBangunan,
    required int jumlahKamar,
    required int jumlahKamarMandi,
    required int usiaBangunan,
    required String lokasi,
  }) =>
      throw UnimplementedError();

  @override
  Future<Failure?> saveHistory(List<Prediction> history) =>
      throw UnimplementedError();

  @override
  Future<Failure?> clearHistory() => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> loadDraft() => throw UnimplementedError();

  @override
  Future<void> saveDraft(Map<String, dynamic> draft) =>
      throw UnimplementedError();
}

Prediction _sample(String lokasi) => Prediction(
      luasM2: 120,
      luasBangunan: 98,
      jumlahKamar: 3,
      jumlahKamarMandi: 2,
      usiaBangunan: 10,
      lokasi: lokasi,
      estimasiHarga: 1520000000,
      estimasiString: 'Rp 1,52 Miliar',
      rentangBawah: 'Rp 1,14 Miliar',
      rentangAtas: 'Rp 1,90 Miliar',
      kategori: 'Mahal',
      confidence: 0.952,
      createdAt: DateTime(2025, 9, 12),
    );

void main() {
  test('GetPredictionHistory meneruskan daftar dari repository', () async {
    final repo =
        FakePredictionRepository(items: [_sample('Jakarta Selatan'), _sample('Bekasi')]);
    final result = await GetPredictionHistory(repo).call();
    expect(result.failure, isNull);
    expect(result.history.length, 2);
    expect(result.history.first.lokasi, 'Jakarta Selatan');
  });

  test('GetPredictionHistory meneruskan failure tanpa melempar', () async {
    final repo = FakePredictionRepository(fail: true);
    final result = await GetPredictionHistory(repo).call();
    expect(result.failure, isA<LocalFailure>());
    expect(result.history, isEmpty);
  });
}
