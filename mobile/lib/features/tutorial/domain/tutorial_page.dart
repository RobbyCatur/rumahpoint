/// Halaman aplikasi yang punya panduan singkat untuk pengguna baru.
///
/// Enum ini sengaja tidak bergantung pada Flutter agar bisa dipakai lapisan
/// data (kunci penyimpanan) maupun presentasi (judul & isi langkah).
enum TutorialPage {
  beranda,
  riwayat,
  profil;

  /// Kunci SharedPreferences. Naikkan versinya bila isi panduan berubah
  /// agar pengguna lama ikut melihat panduan yang baru.
  String get storageKey => 'rp_tutorial_v1_$name';

  String get label => switch (this) {
    TutorialPage.beranda => 'Beranda',
    TutorialPage.riwayat => 'Riwayat',
    TutorialPage.profil => 'Profil',
  };
}
