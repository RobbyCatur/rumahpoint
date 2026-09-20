import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/client.dart';
import '../models/prediction.dart';

final apiClientProvider = Provider((ref) => ApiClient());

/// Controller prediksi: memanggil cloud ML langsung, menyimpan riwayat lokal (SharedPreferences).
class PredictionController extends StateNotifier<PredictionState> {
  PredictionController(this._api) : super(const PredictionState());

  final ApiClient _api;

  static const _keyHistory = 'rp_history';

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyHistory) ?? [];
    state = state.copyWith(history: raw.map((e) {
      return Prediction.fromMap(Map<String, dynamic>.from(jsonDecode(e)));
    }).toList());
  }

  Future<void> predict({
    required double luasM2,
    required int jumlahKamar,
    required int jumlahKamarMandi,
    required int usiaBangunan,
    required String lokasi,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = await _api.predict(
        luasM2: luasM2,
        jumlahKamar: jumlahKamar,
        jumlahKamarMandi: jumlahKamarMandi,
        usiaBangunan: usiaBangunan,
        lokasi: lokasi,
      );
      final input = Map<String, dynamic>.from(data['input'] as Map);
      final result = Prediction.fromJson(data, input);
      final history = [...state.history, result];
      await _saveHistory(history);
      state = state.copyWith(
        loading: false,
        current: result,
        history: history,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> _saveHistory(List<Prediction> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyHistory,
      history.map((p) => jsonEncode(p.toMap())).toList(),
    );
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
    state = state.copyWith(history: const []);
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

final predictionControllerProvider =
    StateNotifierProvider<PredictionController, PredictionState>(
  (ref) => PredictionController(ref.watch(apiClientProvider)),
);
