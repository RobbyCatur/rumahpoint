import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rumahpoint/core/failures.dart';
import 'package:rumahpoint/features/prediction/data/datasources/prediction_draft_datasource.dart';
import 'package:rumahpoint/features/prediction/data/datasources/prediction_remote_datasource.dart';
import 'package:rumahpoint/features/prediction/data/repositories/prediction_repository_impl.dart';
import 'package:rumahpoint/features/prediction/domain/entities/prediction.dart';
import 'package:rumahpoint/features/prediction/domain/repositories/prediction_repository.dart';
import 'package:rumahpoint/features/prediction/domain/usecases/get_prediction_history.dart';
import 'package:rumahpoint/features/prediction/presentation/controllers/prediction_controller.dart';
import 'package:rumahpoint/features/prediction/presentation/providers/prediction_providers.dart';
import 'package:rumahpoint/main.dart';
import 'package:rumahpoint/router.dart';

/// Remote palsu yang selalu gagal terhubung, seperti server cloud mati.
class _OfflineRemote extends PredictionRemoteDatasource {
  @override
  Future<Map<String, dynamic>> predict({
    required double luasM2,
    required double luasBangunan,
    required int jumlahKamar,
    required int jumlahKamarMandi,
    required int usiaBangunan,
    required String lokasi,
  }) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/predict'),
      type: DioExceptionType.connectionError,
    );
  }
}

/// Repository palsu tanpa kegagalan, dipakai untuk menguji controller.
class _EmptyRepository implements PredictionRepository {
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

class _ErrorController extends PredictionController {
  _ErrorController(PredictionState seed)
    : super(_EmptyRepository(), GetPredictionHistory(_EmptyRepository())) {
    state = seed;
  }
}

const _tutorialSeen = <String, Object>{
  'rp_tutorial_v1_beranda': true,
  'rp_tutorial_v1_riwayat': true,
  'rp_tutorial_v1_profil': true,
};

const _friendly =
    'Tidak bisa menghubungi layanan prediksi. Periksa koneksi '
    'internetmu, lalu coba lagi.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('kegagalan jaringan memakai pesan yang ramah pengguna', () async {
    final repository = PredictionRepositoryImpl(
      _OfflineRemote(),
      PredictionDraftDatasource(),
    );

    final result = await repository.predict(
      luasM2: 120,
      luasBangunan: 98,
      jumlahKamar: 3,
      jumlahKamarMandi: 2,
      usiaBangunan: 10,
      kondisi: 'Bekas',
      lokasi: 'Jakarta Selatan',
      provinsi: 'DKI Jakarta',
      lokasiDidukung: true,
    );

    expect(result.prediction, isNull);
    expect(result.failure, isA<NetworkFailure>());
    expect(result.failure!.message, _friendly);
    expect(result.failure!.message, isNot(contains('server cloud')));
  });

  test(
    'controller memakai pesan bawaan yang ramah bila failure kosong',
    () async {
      final controller = _ErrorController(const PredictionState());

      await controller.predict(
        luasM2: 120,
        luasBangunan: 98,
        jumlahKamar: 3,
        jumlahKamarMandi: 2,
        usiaBangunan: 10,
        kondisi: 'Bekas',
        lokasi: 'Jakarta Selatan',
        provinsi: 'DKI Jakarta',
        lokasiDidukung: true,
      );

      expect(controller.state.error, isNotNull);
      expect(controller.state.error, isNot(contains('Gagal memprediksi')));
    },
  );

  testWidgets('Beranda menampilkan pesan galat dari state, bukan teks teknis', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_tutorialSeen);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          predictionControllerProvider.overrideWith(
            (ref) => _ErrorController(const PredictionState(error: _friendly)),
          ),
        ],
        child: const RumahPointApp(),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/beranda');
    await tester.pumpAndSettle();

    expect(find.text(_friendly), findsOneWidget);
    expect(
      find.text('Gagal memprediksi. Pastikan server cloud aktif.'),
      findsNothing,
    );
  });
}
