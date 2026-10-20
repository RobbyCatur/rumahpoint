import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/wilayah.dart';

/// Memuat data wilayah administratif (provinsi → kabupaten/kota) dari
/// asset `assets/data/wilayah.json` dan menyediakan pencarian serta
/// pencocokan lokasi GPS → kab/kota terdekat.
class WilayahService {
  WilayahService._();

  static List<Provinsi>? _cache;

  static Future<List<Provinsi>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/wilayah.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _cache = [
      for (final p in list)
        Provinsi(
          nama: p['nama'].toString(),
          kabupatenKota: [
            for (final k in (p['kabupatenKota'] as List).cast<Map<String, dynamic>>())
              KabupatenKota.fromJson(p['nama'].toString(), k),
          ],
        ),
    ];
    return _cache!;
  }

  /// Cari kab/kota berdasarkan nama (case-insensitive, substring).
  /// Hasil dibatasi [limit] agar dropdown tidak full ke bawah.
  static List<KabupatenKota> search(List<Provinsi> data, String query,
      {int limit = 5}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final hasil = <KabupatenKota>[];
    for (final p in data) {
      for (final k in p.kabupatenKota) {
        if (k.nama.toLowerCase().contains(q)) {
          hasil.add(k);
          if (hasil.length >= limit) return hasil;
        }
      }
    }
    return hasil;
  }

  /// Kab/kota terdekat dari titik GPS (jarak Euclidean sederhana —
  /// hanya dipakai sebagai cadangan bila titik tidak jatuh di dalam
  /// poligon mana pun, mis. di laut).
  static KabupatenKota nearest(List<Provinsi> data, double lat, double lng) {
    KabupatenKota? terbaik;
    var jarakTerbaik = double.infinity;
    for (final p in data) {
      for (final k in p.kabupatenKota) {
        final dLat = k.lat - lat;
        final dLng = k.lng - lng;
        final d = dLat * dLat + dLng * dLng;
        if (d < jarakTerbaik) {
          jarakTerbaik = d;
          terbaik = k;
        }
      }
    }
    return terbaik!;
  }

  static List<BatasWilayah>? _batasCache;

  /// Batas kab/kota (poligon) dari asset `assets/data/batas.json`.
  static Future<List<BatasWilayah>> loadBatas() async {
    if (_batasCache != null) return _batasCache!;
    final raw = await rootBundle.loadString('assets/data/batas.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _batasCache = [for (final j in list) BatasWilayah.fromJson(j)];
    return _batasCache!;
  }

  /// Kab/kota dengan nama tepat pada provinsi tertentu (null bila tidak ada).
  static KabupatenKota? cari(
      List<Provinsi> data, String nama, String provinsi) {
    for (final p in data) {
      if (p.nama != provinsi) continue;
      for (final k in p.kabupatenKota) {
        if (k.nama == nama) return k;
      }
    }
    return null;
  }

  /// Kab/kota tempat titik GPS berada, berdasarkan poligon batas wilayah.
  /// Bila beberapa poligon memuat (kabupaten induk + kota otonom di
  /// dalamnya), yang terkecil dipilih. Fallback ke [nearest] bila titik
  /// tidak jatuh di darat/ dalam poligon mana pun.
  static KabupatenKota? dalamBatas(
    List<Provinsi> data,
    List<BatasWilayah> batas,
    double lat,
    double lng,
  ) {
    BatasWilayah? terbaik;
    for (final b in batas) {
      if (!b.memuat(lat, lng)) continue;
      if (terbaik == null || b.luas < terbaik.luas) terbaik = b;
    }
    if (terbaik == null) return null;
    return cari(data, terbaik.nama, terbaik.provinsi);
  }

  /// Lokasi terbaik untuk sebuah titik GPS: poligon dulu, centroid sebagai
  /// cadangan. Selalu mengembalikan kab/kota (tidak null) selama [data] terisi.
  static KabupatenKota locate(
    List<Provinsi> data,
    List<BatasWilayah> batas,
    double lat,
    double lng,
  ) =>
      dalamBatas(data, batas, lat, lng) ?? nearest(data, lat, lng);
}
