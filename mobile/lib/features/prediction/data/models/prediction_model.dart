import '../../domain/entities/prediction.dart';

/// Representasi data luar (JSON cloud ML & cache lokal) + mapping ke entity.
///
/// Semua fromJson/toMap tinggal di sini — entity tetap murni.
class PredictionModel extends Prediction {
  const PredictionModel({
    required super.luasM2,
    required super.luasBangunan,
    required super.jumlahKamar,
    required super.jumlahKamarMandi,
    required super.usiaBangunan,
    required super.kondisi,
    required super.lokasi,
    required super.provinsi,
    required super.lokasiDidukung,
    required super.estimasiHarga,
    required super.estimasiString,
    required super.rentangBawah,
    required super.rentangAtas,
    required super.kategori,
    required super.confidence,
    required super.createdAt,
  });

  /// Dari respons `POST /predict` cloud ML + echo input yang dikirim.
  /// [kondisi], [provinsi], dan [lokasiDidukung] berasal dari pilihan user
  /// di form (server cloud tidak mengenal konsep-konsep ini).
  factory PredictionModel.fromApiJson(
    Map<String, dynamic> j,
    Map<String, dynamic> input, {
    required String kondisi,
    required String provinsi,
    required bool lokasiDidukung,
  }) {
    return PredictionModel(
      luasM2: (input['luas_m2'] as num).toDouble(),
      luasBangunan: (input['luas_bangunan'] as num? ?? 0).toDouble(),
      jumlahKamar: (input['jumlah_kamar'] as num).toInt(),
      jumlahKamarMandi: (input['jumlah_kamar_mandi'] as num).toInt(),
      usiaBangunan: (input['usia_bangunan'] as num).toInt(),
      kondisi: kondisi,
      lokasi: input['lokasi'].toString(),
      provinsi: provinsi,
      lokasiDidukung: lokasiDidukung,
      estimasiHarga: (j['estimasi_harga_rupiah'] as num).toInt(),
      estimasiString: j['estimasi_harga_string'].toString(),
      rentangBawah: (j['rentang_bawah'] ?? '').toString(),
      rentangAtas: (j['rentang_atas'] ?? '').toString(),
      kategori: j['kategori_harga'].toString(),
      confidence: (j['confidence'] as num).toDouble(),
      createdAt: DateTime.now(),
    );
  }

  /// Toleran terhadap cache lama yang belum punya field baru.
  factory PredictionModel.fromMap(Map<String, dynamic> m) => PredictionModel(
        luasM2: (m['luasM2'] as num).toDouble(),
        luasBangunan: (m['luasBangunan'] as num? ?? 0).toDouble(),
        jumlahKamar: (m['jumlahKamar'] as num).toInt(),
        jumlahKamarMandi: (m['jumlahKamarMandi'] as num).toInt(),
        usiaBangunan: (m['usiaBangunan'] as num).toInt(),
        kondisi: (m['kondisi'] ??
                ((m['usiaBangunan'] as num? ?? 0) == 0 ? 'Baru' : 'Bekas'))
            .toString(),
        lokasi: m['lokasi'].toString(),
        provinsi: (m['provinsi'] ?? '').toString(),
        lokasiDidukung: m['lokasiDidukung'] == true,
        estimasiHarga: (m['estimasiHarga'] as num).toInt(),
        estimasiString: m['estimasiString'].toString(),
        rentangBawah: (m['rentangBawah'] ?? '').toString(),
        rentangAtas: (m['rentangAtas'] ?? '').toString(),
        kategori: m['kategori'].toString(),
        confidence: (m['confidence'] as num).toDouble(),
        createdAt: DateTime.parse(m['createdAt'].toString()),
      );

  Map<String, dynamic> toMap() => {
        'luasM2': luasM2,
        'luasBangunan': luasBangunan,
        'jumlahKamar': jumlahKamar,
        'jumlahKamarMandi': jumlahKamarMandi,
        'usiaBangunan': usiaBangunan,
        'kondisi': kondisi,
        'lokasi': lokasi,
        'provinsi': provinsi,
        'lokasiDidukung': lokasiDidukung,
        'estimasiHarga': estimasiHarga,
        'estimasiString': estimasiString,
        'rentangBawah': rentangBawah,
        'rentangAtas': rentangAtas,
        'kategori': kategori,
        'confidence': confidence,
        'createdAt': createdAt.toIso8601String(),
      };
}
