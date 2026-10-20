import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wilayah.dart';
import '../../domain/repositories/wilayah_preference_repository.dart';

/// Pengendali preferensi wilayah user — diatur di Profil, dibaca Beranda
/// sebagai nilai awal form. Bergantung pada ABSTRAKSI
/// ([WilayahPreferenceRepository]) dan fungsi pencocok nama ([_cari]),
/// sehingga tidak menyentuh SharedPreferences maupun asset di sini.
class WilayahPreferenceController extends StateNotifier<KabupatenKota?> {
  WilayahPreferenceController(this._repository, this._cari) : super(null) {
    siap = _muat();
  }

  final WilayahPreferenceRepository _repository;
  final Future<KabupatenKota?> Function(String nama, String provinsi) _cari;

  /// Tuntas setelah preferensi tersimpan terbaca. Beranda menunggu ini agar
  /// tidak salah jatuh ke deteksi GPS saat nilainya masih di jalan.
  late final Future<void> siap;

  Future<void> _muat() async {
    final tersimpan = await _repository.baca();
    if (tersimpan == null) return;
    final ketemu = await _cari(tersimpan.nama, tersimpan.provinsi);
    // Nama tidak dikenal lagi (data wilayah diperbarui) → biarkan null,
    // Beranda akan jatuh ke deteksi GPS seperti biasa.
    if (ketemu != null) state = ketemu;
  }

  /// Simpan preferensi. State diubah lebih dulu supaya layar lain langsung
  /// ikut, penyimpanan dijalankan setelahnya.
  Future<void> simpan(KabupatenKota wilayah) async {
    state = wilayah;
    await _repository.simpan(nama: wilayah.nama, provinsi: wilayah.provinsi);
  }
}
