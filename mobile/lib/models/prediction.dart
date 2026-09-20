class Prediction {
  final double luasM2;
  final int jumlahKamar;
  final int jumlahKamarMandi;
  final int usiaBangunan;
  final String lokasi;
  final int estimasiHarga;
  final String estimasiString;
  final String kategori;
  final double confidence;
  final DateTime createdAt;

  Prediction({
    required this.luasM2,
    required this.jumlahKamar,
    required this.jumlahKamarMandi,
    required this.usiaBangunan,
    required this.lokasi,
    required this.estimasiHarga,
    required this.estimasiString,
    required this.kategori,
    required this.confidence,
    required this.createdAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> j, Map<String, dynamic> input) {
    return Prediction(
      luasM2: (input['luas_m2'] as num).toDouble(),
      jumlahKamar: (input['jumlah_kamar'] as num).toInt(),
      jumlahKamarMandi: (input['jumlah_kamar_mandi'] as num).toInt(),
      usiaBangunan: (input['usia_bangunan'] as num).toInt(),
      lokasi: input['lokasi'].toString(),
      estimasiHarga: (j['estimasi_harga_rupiah'] as num).toInt(),
      estimasiString: j['estimasi_harga_string'].toString(),
      kategori: j['kategori_harga'].toString(),
      confidence: (j['confidence'] as num).toDouble(),
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'luasM2': luasM2,
        'jumlahKamar': jumlahKamar,
        'jumlahKamarMandi': jumlahKamarMandi,
        'usiaBangunan': usiaBangunan,
        'lokasi': lokasi,
        'estimasiHarga': estimasiHarga,
        'estimasiString': estimasiString,
        'kategori': kategori,
        'confidence': confidence,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Prediction.fromMap(Map<String, dynamic> m) => Prediction(
        luasM2: (m['luasM2'] as num).toDouble(),
        jumlahKamar: m['jumlahKamar'] as int,
        jumlahKamarMandi: m['jumlahKamarMandi'] as int,
        usiaBangunan: m['usiaBangunan'] as int,
        lokasi: m['lokasi'].toString(),
        estimasiHarga: m['estimasiHarga'] as int,
        estimasiString: m['estimasiString'].toString(),
        kategori: m['kategori'].toString(),
        confidence: (m['confidence'] as num).toDouble(),
        createdAt: DateTime.parse(m['createdAt'].toString()),
      );
}
