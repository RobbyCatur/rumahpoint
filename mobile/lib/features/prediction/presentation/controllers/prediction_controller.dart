import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/prediction.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../../domain/usecases/get_prediction_history.dart';

/// Controller prediksi untuk UI. Bergantung pada ABSTRAKSI
/// ([PredictionRepository] + use case), bukan Dio/SharedPreferences —
/// sehingga bisa diuji dengan fake dan tidak tahu detail data layer.
class PredictionController extends StateNotifier<PredictionState> {
  PredictionController(this._repository, this._getHistory)
      : super(const PredictionState());

  final PredictionRepository _repository;
  final GetPredictionHistory _getHistory;

  Future<void> loadHistory() async {
    final result = await _getHistory();
    if (result.failure == null) {
      state = state.copyWith(history: result.history);
    }
  }

  /// Baca draft form (autosave) — null bila belum ada.
  Future<Map<String, dynamic>?> loadDraft() => _repository.loadDraft();

  /// Simpan draft form (autosave).
  Future<void> saveDraft(Map<String, dynamic> draft) =>
      _repository.saveDraft(draft);

  Future<void> predict({
    required double luasM2,
    required double luasBangunan,
    required int jumlahKamar,
    required int jumlahKamarMandi,
    required int usiaBangunan,
    required String kondisi,
    required String lokasi,
    required String provinsi,
    required bool lokasiDidukung,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    final result = await _repository.predict(
      luasM2: luasM2,
      luasBangunan: luasBangunan,
      jumlahKamar: jumlahKamar,
      jumlahKamarMandi: jumlahKamarMandi,
      usiaBangunan: usiaBangunan,
      kondisi: kondisi,
      lokasi: lokasi,
      provinsi: provinsi,
      lokasiDidukung: lokasiDidukung,
    );

    if (result.failure != null || result.prediction == null) {
      state = state.copyWith(
        loading: false,
        error: result.failure?.message ??
            'Prediksi belum berhasil. Coba lagi ya.',
      );
      return;
    }

    final prediction = result.prediction!;
    final history = [...state.history, prediction];
    await _repository.saveHistory(history);
    state = state.copyWith(
      loading: false,
      current: prediction,
      history: history,
    );
  }

  /// Pilih satu entri riwayat untuk ditampilkan ulang di halaman hasil.
  void select(Prediction p) {
    state = state.copyWith(current: p);
  }

  Future<void> clearHistory() async {
    final failure = await _repository.clearHistory();
    if (failure == null) {
      state = state.copyWith(history: const []);
    }
  }
}

class PredictionState {
  const PredictionState({
    this.loading = false,
    this.current,
    this.error,
    this.history = const [],
  });

  final bool loading;
  final Prediction? current;
  final String? error;
  final List<Prediction> history;

  PredictionState copyWith({
    bool? loading,
    Prediction? current,
    String? error,
    bool clearError = false,
    List<Prediction>? history,
  }) {
    return PredictionState(
      loading: loading ?? this.loading,
      current: current ?? this.current,
      error: clearError ? null : (error ?? this.error),
      history: history ?? this.history,
    );
  }
}
