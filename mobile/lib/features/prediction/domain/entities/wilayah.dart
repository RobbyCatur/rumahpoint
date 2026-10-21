/// Wilayah administratif Indonesia (provinsi → kabupaten/kota).
///
/// Sumber data: `assets/data/wilayah.json` (koordinat OSM + bendera cakupan
/// yang dibangun `ml/build_wilayah.py` dari `meta.json` hasil training).
/// `didukung` = true bila wilayah punya cukup baris data latih (ambang ada di
/// skrip itu); false = model banyak mengeneralisasi → UI memberi peringatan.
class KabupatenKota {
  const KabupatenKota({
    required this.nama,
    required this.provinsi,
    required this.didukung,
    required this.lat,
    required this.lng,
  });

  final String nama;
  final String provinsi;
  final bool didukung;
  final double lat;
  final double lng;

  factory KabupatenKota.fromJson(String provinsi, Map<String, dynamic> j) =>
      KabupatenKota(
        nama: j['nama'].toString(),
        provinsi: provinsi,
        didukung: j['didukung'] == true,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}

class Provinsi {
  const Provinsi({required this.nama, required this.kabupatenKota});

  final String nama;
  final List<KabupatenKota> kabupatenKota;
}

/// Batas geografis satu kab/kota sebagai kumpulan bagian (pulau/kecamatan
/// terpisahkan); tiap bagian = cincin luar di indeks 0, sisanya lubang.
/// Cincin disimpan sebagai pasangan koordinat terpipih `[lng, lat, lng, lat…]`
/// dalam derajat (sudah disederhanakan, presisi ±111 m).
class BatasWilayah {
  const BatasWilayah({
    required this.nama,
    required this.provinsi,
    required this.bagian,
  });

  final String nama;
  final String provinsi;
  final List<List<List<double>>> bagian;

  factory BatasWilayah.fromJson(Map<String, dynamic> j) => BatasWilayah(
        nama: j['n'].toString(),
        provinsi: j['p'].toString(),
        bagian: [
          for (final b in (j['g'] as List).cast<List<dynamic>>())
            [
              for (final r in b.cast<List<dynamic>>())
                [
                  for (final p in r.cast<List<dynamic>>()) ...[
                    (p[0] as num).toDouble(),
                    (p[1] as num).toDouble(),
                  ]
                ]
            ]
        ],
      );

  bool memuat(double lat, double lng) =>
      bagian.any((b) => _dalamCincin(lng, lat, b[0]) &&
          !b.skip(1).any((lubang) => _dalamCincin(lng, lat, lubang)));

  /// Luas pendekatan (derajat²) untuk memilih poligon terkecil yang memuat.
  double get luas {
    var total = 0.0;
    for (final b in bagian) {
      total += _luasCincin(b[0]);
      for (final lubang in b.skip(1)) {
        total -= _luasCincin(lubang);
      }
    }
    return total;
  }
}

bool _dalamCincin(double lng, double lat, List<double> ring) {
  var inside = false;
  for (int i = 0, j = ring.length - 2; i < ring.length; j = i, i += 2) {
    final xi = ring[i], yi = ring[i + 1];
    final xj = ring[j], yj = ring[j + 1];
    if ((yi > lat) != (yj > lat) &&
        lng < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

double _luasCincin(List<double> ring) {
  var a = 0.0;
  for (int i = 0, j = ring.length - 2; i < ring.length; j = i, i += 2) {
    a += ring[j] * ring[i + 1] - ring[i] * ring[j + 1];
  }
  return a.abs() / 2;
}
