import 'package:dio/dio.dart';

class ApiClient {
  static const baseUrl = String.fromEnvironment(
    'ML_URL',
    defaultValue: 'http://127.0.0.1:8081',
  );

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    contentType: Headers.jsonContentType,
  ));

  Future<Map<String, dynamic>> predict({
    required double luasM2,
    required double luasBangunan,
    required int jumlahKamar,
    required int jumlahKamarMandi,
    required int usiaBangunan,
    required String lokasi,
  }) async {
    final resp = await _dio.post('/predict', data: {
      'luas_m2': luasM2,
      'luas_bangunan': luasBangunan,
      'jumlah_kamar': jumlahKamar,
      'jumlah_kamar_mandi': jumlahKamarMandi,
      'usia_bangunan': usiaBangunan,
      'lokasi': lokasi,
    });
    return Map<String, dynamic>.from(resp.data as Map);
  }
}
