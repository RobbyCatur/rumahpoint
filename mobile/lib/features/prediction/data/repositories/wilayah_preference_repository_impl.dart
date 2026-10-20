import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/wilayah_preference_repository.dart';

/// Preferensi wilayah disimpan di SharedPreferences (perangkat ini saja),
/// sehingga tetap ada setelah aplikasi ditutup.
class WilayahPreferenceRepositoryImpl implements WilayahPreferenceRepository {
  static const _key = 'rp_preferensi_wilayah';

  @override
  Future<({String nama, String provinsi})?> baca() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final nama = map['nama'];
      final provinsi = map['provinsi'];
      if (nama is! String || provinsi is! String) return null;
      if (nama.isEmpty || provinsi.isEmpty) return null;
      return (nama: nama, provinsi: provinsi);
    } catch (_) {
      return null; // data korup → anggap belum pernah disimpan
    }
  }

  @override
  Future<void> simpan({required String nama, required String provinsi}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({'nama': nama, 'provinsi': provinsi}));
  }
}
