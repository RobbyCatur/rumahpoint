import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Akses ke cache draft form (autosave). Hanya data layer yang boleh
/// menyentuh SharedPreferences & jsonDecode.
class PredictionDraftDatasource {
  static const _keyDraft = 'rp_draft';

  /// Baca draft mentah sebagai map (null bila belum ada / korup).
  Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDraft);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null; // draft korup → abaikan
    }
  }

  Future<void> saveDraft(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDraft, jsonEncode(draft));
  }
}
