import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/prediction.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../datasources/prediction_draft_datasource.dart';
import '../datasources/prediction_remote_datasource.dart';
import '../models/prediction_model.dart';

/// Implementasi [PredictionRepository]: prediksi via cloud ML (Dio) dan
/// riwayat via cache lokal (SharedPreferences). Semua akses data mentah
/// (HTTP, JSON, storage) berhenti di sini.
class PredictionRepositoryImpl implements PredictionRepository {
  PredictionRepositoryImpl(this._remote, this._draft);

  final PredictionRemoteDatasource _remote;
  final PredictionDraftDatasource _draft;

  static const _keyHistory = 'rp_history';

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
  }) async {
    try {
      final data = await _remote.predict(
        luasM2: luasM2,
        luasBangunan: luasBangunan,
        jumlahKamar: jumlahKamar,
        jumlahKamarMandi: jumlahKamarMandi,
        usiaBangunan: usiaBangunan,
        lokasi: lokasi,
      );
      final input = Map<String, dynamic>.from(data['input'] as Map);
      return (
        prediction: PredictionModel.fromApiJson(
          data,
          input,
          kondisi: kondisi,
          provinsi: provinsi,
          lokasiDidukung: lokasiDidukung,
        ),
        failure: null,
      );
    } on DioException {
      return (
        prediction: null,
        failure: const NetworkFailure(
            'Gagal memprediksi. Pastikan server cloud aktif.'),
      );
    } catch (e) {
      return (
        prediction: null,
        failure: NetworkFailure('Terjadi kesalahan tak terduga: $e'),
      );
    }
  }

  @override
  Future<({List<Prediction> history, Failure? failure})> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyHistory) ?? [];
      final history = raw
          .map((e) =>
              PredictionModel.fromMap(Map<String, dynamic>.from(jsonDecode(e))))
          .toList();
      return (history: history, failure: null);
    } catch (e) {
      return (
        history: const <Prediction>[],
        failure: LocalFailure('Gagal membaca riwayat: $e'),
      );
    }
  }

  @override
  Future<Failure?> saveHistory(List<Prediction> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final models = history
          .map((p) => p is PredictionModel ? p : _toModel(p))
          .toList();
      await prefs.setStringList(
        _keyHistory,
        models.map((m) => jsonEncode(m.toMap())).toList(),
      );
      return null;
    } catch (e) {
      return LocalFailure('Gagal menyimpan riwayat: $e');
    }
  }

  @override
  Future<Failure?> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHistory);
      return null;
    } catch (e) {
      return LocalFailure('Gagal menghapus riwayat: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> loadDraft() => _draft.loadDraft();

  @override
  Future<void> saveDraft(Map<String, dynamic> draft) => _draft.saveDraft(draft);

  PredictionModel _toModel(Prediction p) => PredictionModel(
        luasM2: p.luasM2,
        luasBangunan: p.luasBangunan,
        jumlahKamar: p.jumlahKamar,
        jumlahKamarMandi: p.jumlahKamarMandi,
        usiaBangunan: p.usiaBangunan,
        kondisi: p.kondisi,
        lokasi: p.lokasi,
        provinsi: p.provinsi,
        lokasiDidukung: p.lokasiDidukung,
        estimasiHarga: p.estimasiHarga,
        estimasiString: p.estimasiString,
        rentangBawah: p.rentangBawah,
        rentangAtas: p.rentangAtas,
        kategori: p.kategori,
        confidence: p.confidence,
        createdAt: p.createdAt,
      );
}
