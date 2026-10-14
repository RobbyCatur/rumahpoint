import '../../../../core/failures.dart';
import '../entities/prediction.dart';
import '../repositories/prediction_repository.dart';

/// Use case: ambil riwayat prediksi.
///
/// Dibuat terpisah (bukan repository langsung ke notifier) karena titik
/// inilah yang nanti menampung aturan bisnis saat riwayat menjadi sinkron
/// server + cache offline (roadmap auth JWT). Untuk sekarang ia meneruskan
/// kontrak repository apa adanya.
class GetPredictionHistory {
  const GetPredictionHistory(this._repository);

  final PredictionRepository _repository;

  Future<({List<Prediction> history, Failure? failure})> call() {
    return _repository.getHistory();
  }
}
