/// Entity bisnis murni untuk satu hasil prediksi/valuasi properti.
///
/// Hidup di domain layer: TANPA import Flutter, Dio, atau mapping
/// (fromJson/toMap). Representasi data luar (JSON API / cache lokal)
/// ada di `data/models/prediction_model.dart`.
class Prediction {
  const Prediction({
    required this.luasM2,
    required this.luasBangunan,
    required this.jumlahKamar,
    required this.jumlahKamarMandi,
    required this.usiaBangunan,
    required this.kondisi,
    required this.lokasi,
    required this.provinsi,
    required this.lokasiDidukung,
    required this.estimasiHarga,
    required this.estimasiString,
    required this.rentangBawah,
    required this.rentangAtas,
    required this.kategori,
    required this.confidence,
    required this.createdAt,
  });

  final double luasM2;
  final double luasBangunan;
  final int jumlahKamar;
  final int jumlahKamarMandi;
  final int usiaBangunan;

  /// 'Baru' | 'Bekas' — label UI untuk usiaBangunan.
  final String kondisi;
  final String lokasi;
  final String provinsi;

  /// false bila cakupan data latih lokasi belum cukup → UI tampilkan peringatan.
  final bool lokasiDidukung;
  final int estimasiHarga;
  final String estimasiString;
  final String rentangBawah;
  final String rentangAtas;
  final String kategori;
  final double confidence;
  final DateTime createdAt;
}
