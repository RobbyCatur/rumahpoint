class Prediction {
  final double luasM2;
  final double luasBangunan;
  final int jumlahKamar;
  final int jumlahKamarMandi;
  final int usiaBangunan;
  final String lokasi;
  final int estimasiHarga;
  final String estimasiString;
  final String rentangBawah;
  final String rentangAtas;
  final String kategori;
  final double confidence;
  final DateTime createdAt;

  Prediction({
    required this.luasM2,
    required this.luasBangunan,
    required this.jumlahKamar,
    required this.jumlahKamarMandi,
    required this.usiaBangunan,
    required this.lokasi,
    required this.estimasiHarga,
    required this.estimasiString,
    required this.rentangBawah,
    required this.rentangAtas,
    required this.kategori,
    required this.confidence,
    required this.createdAt,
  });

  factory Prediction.fromJson(
      Map<String, dynamic> j, Map<String, dynamic> input) {
    return Prediction(
      luasM2: (input['luas_m2'] as num).toDouble(),
      luasBangunan: (input['luas_bangunan'] as num? ?? 0).toDouble(),
      jumlahKamar: (input['jumlah_kamar'] as num).toInt(),
      jumlahKamarMandi: (input['jumlah_kamar_mandi'] as num).toInt(),
      usiaBangunan: (input['usia_bangunan'] as num).toInt(),
      lokasi: input['lokasi'].toString(),
      estimasiHarga: (j['estimasi_harga_rupiah'] as num).toInt(),
      estimasiString: j['estimasi_harga_string'].toString(),
      rentangBawah: (j['rentang_bawah'] ?? '').toString(),
      rentangAtas: (j['rentang_atas'] ?? '').toString(),
      kategori: j['kategori_harga'].toString(),
      confidence: (j['confidence'] as num).toDouble(),
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'luasM2': luasM2,
        'luasBangunan': luasBangunan,
        'jumlahKamar': jumlahKamar,
        'jumlahKamarMandi': jumlahKamarMandi,
        'usiaBangunan': usiaBangunan,
        'lokasi': lokasi,
        'estimasiHarga': estimasiHarga,
        'estimasiString': estimasiString,
        'rentangBawah': rentangBawah,
        'rentangAtas': rentangAtas,
        'kategori': kategori,
        'confidence': confidence,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Toleran terhadap cache lama yang belum punya field baru.
  factory Prediction.fromMap(Map<String, dynamic> m) => Prediction(
        luasM2: (m['luasM2'] as num).toDouble(),
        luasBangunan: (m['luasBangunan'] as num? ?? 0).toDouble(),
        jumlahKamar: (m['jumlahKamar'] as num).toInt(),
        jumlahKamarMandi: (m['jumlahKamarMandi'] as num).toInt(),
        usiaBangunan: (m['usiaBangunan'] as num).toInt(),
        lokasi: m['lokasi'].toString(),
        estimasiHarga: (m['estimasiHarga'] as num).toInt(),
        estimasiString: m['estimasiString'].toString(),
        rentangBawah: (m['rentangBawah'] ?? '').toString(),
        rentangAtas: (m['rentangAtas'] ?? '').toString(),
        kategori: m['kategori'].toString(),
        confidence: (m['confidence'] as num).toDouble(),
        createdAt: DateTime.parse(m['createdAt'].toString()),
      );
}
