/// Wilayah administratif Indonesia (provinsi → kabupaten/kota).
///
/// Sumber data: `assets/data/wilayah.json` (audit cakupan dataset project
/// + koordinat OSM). `didukung` = true bila lokasi tercakup data latih
/// model (prediksi akurat); false = model mengeneralisasi (peringatan UI).
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
