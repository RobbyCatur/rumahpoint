import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/prediction_draft_datasource.dart';
import '../../data/datasources/prediction_remote_datasource.dart';
import '../../data/repositories/prediction_repository_impl.dart';
import '../../data/repositories/wilayah_preference_repository_impl.dart';
import '../../data/services/location_service.dart';
import '../../data/services/wilayah_service.dart';
import '../../domain/entities/wilayah.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../../domain/repositories/wilayah_preference_repository.dart';
import '../../domain/usecases/get_prediction_history.dart';
import '../controllers/prediction_controller.dart';
import '../controllers/wilayah_preference_controller.dart';

/// Wiring DI untuk fitur prediksi — satu-satunya tempat 'new' implementasi.

// Data layer
final predictionRemoteDatasourceProvider =
    Provider<PredictionRemoteDatasource>((ref) {
  return PredictionRemoteDatasource();
});

final predictionDraftDatasourceProvider =
    Provider<PredictionDraftDatasource>((ref) {
  return PredictionDraftDatasource();
});

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepositoryImpl(
    ref.watch(predictionRemoteDatasourceProvider),
    ref.watch(predictionDraftDatasourceProvider),
  );
});

// Domain layer (use case menerima abstraksi)
final getPredictionHistoryProvider = Provider<GetPredictionHistory>((ref) {
  return GetPredictionHistory(ref.watch(predictionRepositoryProvider));
});

// Presentation layer (state untuk UI)
final predictionControllerProvider =
    StateNotifierProvider<PredictionController, PredictionState>((ref) {
  return PredictionController(
    ref.watch(predictionRepositoryProvider),
    ref.watch(getPredictionHistoryProvider),
  );
});

/// Data wilayah administratif (provinsi → kab/kota), dimuat sekali dari asset.
final wilayahProvider = FutureProvider<List<Provinsi>>((ref) {
  return WilayahService.load();
});

/// Poligon batas kab/kota, dimuat sekali dari asset (dipakai deteksi GPS).
final batasWilayahProvider = FutureProvider<List<BatasWilayah>>((ref) {
  return WilayahService.loadBatas();
});

/// Akses GPS device (geolocator).
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Penyimpanan preferensi wilayah user (Profil → Beranda).
final wilayahPreferenceRepositoryProvider =
    Provider<WilayahPreferenceRepository>((ref) {
  return WilayahPreferenceRepositoryImpl();
});

/// Preferensi wilayah yang diatur di Profil. Nilai null berarti belum
/// pernah disimpan atau namanya tidak dikenal lagi oleh data wilayah
/// terkini.
final wilayahPreferenceProvider =
    StateNotifierProvider<WilayahPreferenceController, KabupatenKota?>((ref) {
  return WilayahPreferenceController(
    ref.watch(wilayahPreferenceRepositoryProvider),
    (nama, provinsi) async =>
        WilayahService.cari(await ref.read(wilayahProvider.future), nama, provinsi),
  );
});
