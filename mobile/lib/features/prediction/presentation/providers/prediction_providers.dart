import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/prediction_draft_datasource.dart';
import '../../data/datasources/prediction_remote_datasource.dart';
import '../../data/repositories/prediction_repository_impl.dart';
import '../../data/services/location_service.dart';
import '../../data/services/wilayah_service.dart';
import '../../domain/entities/wilayah.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../../domain/usecases/get_prediction_history.dart';
import '../controllers/prediction_controller.dart';

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

/// Akses GPS device (geolocator).
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
