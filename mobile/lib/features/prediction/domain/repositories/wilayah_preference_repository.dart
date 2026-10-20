/// Kontrak penyimpanan preferensi wilayah user (diatur di Profil).
///
/// Yang disimpan hanya nama + provinsi. Bendera `didukung` tidak ikut
/// disimpan supaya selalu dibaca ulang dari data wilayah terkini —
/// cakupan data latih model bisa berubah setelah aplikasi diperbarui.
abstract class WilayahPreferenceRepository {
  Future<({String nama, String provinsi})?> baca();

  Future<void> simpan({required String nama, required String provinsi});
}
