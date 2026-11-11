import 'package:shared_preferences/shared_preferences.dart';

import '../domain/tutorial_page.dart';

/// Penyimpanan status "panduan sudah dilihat" di perangkat ini.
///
/// Belum ada identitas akun yang tersimpan (login masih dummy), jadi status
/// disimpan per perangkat. Saat auth JWT selesai, kunci bisa diberi awalan
/// email pengguna tanpa mengubah alur presentasi.
class TutorialStore {
  Future<bool> isSeen(TutorialPage page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(page.storageKey) ?? false;
    } catch (_) {
      // Penyimpanan gagal → jangan tampilkan popup berulang kali.
      return true;
    }
  }

  Future<void> markSeen(TutorialPage page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(page.storageKey, true);
    } catch (_) {
      // Diamkan: panduan hanya pelengkap, kegagalan simpan tidak fatal.
    }
  }

  Future<void> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final page in TutorialPage.values) {
        await prefs.remove(page.storageKey);
      }
    } catch (_) {
      // Diamkan.
    }
  }
}
