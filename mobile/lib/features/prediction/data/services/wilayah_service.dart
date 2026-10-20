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
  /// cukup untuk skala kabupaten/kota di Indonesia).
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
}
