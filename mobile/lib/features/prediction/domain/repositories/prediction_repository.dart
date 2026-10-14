import '../../../../core/failures.dart';
import '../entities/prediction.dart';

/// Kontrak yang dibutuhkan domain untuk fitur prediksi.
///
/// Implementasi (Dio ke cloud ML + cache SharedPreferences) ada di data
/// layer. Presentation bergantung pada abstraksi ini, sehingga mudah
/// diganti fake saat testing dan mudah dipindah ke backend ber-auth nanti.
abstract class PredictionRepository {
  /// Kirim kriteria properti ke model dan kembalikan hasil prediksi.
  Future<({Prediction? prediction, Failure? failure})> predict({
    required double luasM2,
    required double luasBangunan,
    required int jumlahKamar,
    required int jumlahKamarMandi,
    required int usiaBangunan,
    required String lokasi,
  });

  /// Ambil seluruh riwayat prediksi yang tersimpan.
  Future<({List<Prediction> history, Failure? failure})> getHistory();

  /// Timpa seluruh riwayat (dipakai setelah prediksi baru).
  Future<Failure?> saveHistory(List<Prediction> history);

  /// Hapus seluruh riwayat.
  Future<Failure?> clearHistory();

  /// Baca draft form (autosave) sebagai map mentah, null bila tidak ada.
  Future<Map<String, dynamic>?> loadDraft();

  /// Simpan draft form (autosave).
  Future<void> saveDraft(Map<String, dynamic> draft);
}
