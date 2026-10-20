import 'package:flutter/material.dart';

/// Palet warna RumahPoint — satu aksen amber + netral slate.
/// Semua warna UI diambil dari sini agar seragam.
class AppColors {
  AppColors._();

  static const amber = Color(0xFFF59E0B);
  static const amberDark = Color(0xFFB45309);
  static const amberSoft = Color(0xFFFEF3C7);

  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);

  // Aksen tautan/aksi sekunder (mis. tombol "Gunakan Lokasi Saat Ini").
  static const link = Color(0xFF2563EB);
  static const line = Color(0xFFE2E8F0);
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;

  // Semantik kategori prediksi: Murah = emerald, Mahal = merah.
  static const success = Color(0xFF047857);
  static const successSoft = Color(0xFFECFDF5);
  static const danger = Color(0xFFB91C1C);
  static const dangerSoft = Color(0xFFFEF2F2);
}

/// Sepasang warna (terang & gelap) untuk teks dan bidang yang memakainya.
///
/// `AppColors` hanya boleh dipakai di layar terang — nilainya dibuat untuk
/// latar putih. Layar yang punya mode gelap mengambil warna lewat
/// `AppTone.of(context)` supaya teks tidak ikut gelap di atas latar gelap.
class AppTone {
  const AppTone({
    required this.text,
    required this.textSoft,
    required this.textMuted,
    required this.surface,
    required this.scaffold,
    required this.border,
    required this.tintBg,
    required this.tintBorder,
    required this.tintText,
    required this.accent,
    required this.onAccent,
    required this.link,
    required this.error,
    required this.positive,
    required this.positiveBg,
    required this.negative,
    required this.negativeBg,
  });

  /// Judul dan teks utama.
  final Color text;

  /// Paragraf isi.
  final Color textSoft;

  /// Label, keterangan kecil, ikon pendamping.
  final Color textMuted;

  /// Latar kartu dan bidang input.
  final Color surface;

  /// Latar halaman — dipakai untuk bidang yang perlu terlihat cekung.
  final Color scaffold;

  /// Garis pemisah dan tepi bidang.
  final Color border;

  /// Latar catatan (mis. peringatan akurasi model).
  final Color tintBg;

  /// Tepi panel catatan.
  final Color tintBorder;

  /// Teks di atas [tintBg].
  final Color tintText;

  /// Teks/ikon aksen yang berdiri di atas [surface].
  final Color accent;

  /// Teks di atas bidang berwarna [AppColors.amber].
  final Color onAccent;

  /// Tautan/aksi sekunder (mis. "Gunakan Lokasi Saat Ini").
  final Color link;

  /// Teks galat.
  final Color error;

  /// Teks "Murah" di atas [positiveBg].
  final Color positive;

  /// Latar badge kategori Murah.
  final Color positiveBg;

  /// Teks "Mahal" di atas [negativeBg].
  final Color negative;

  /// Latar badge kategori Mahal.
  final Color negativeBg;

  static const light = AppTone(
    text: Color(0xFF0F172A),
    textSoft: Color(0xFF1E293B),
    textMuted: Color(0xFF475569),
    surface: Colors.white,
    scaffold: Color(0xFFF8FAFC),
    border: Color(0xFFE2E8F0),
    tintBg: Color(0xFFFEF3C7),
    tintBorder: Color(0xFFFDE68A),
    tintText: Color(0xFF92400E),
    accent: Color(0xFFB45309),
    onAccent: Colors.white,
    link: Color(0xFF2563EB),
    error: Color(0xFFB91C1C),
    positive: Color(0xFF047857),
    positiveBg: Color(0xFFECFDF5),
    negative: Color(0xFFB91C1C),
    negativeBg: Color(0xFFFEF2F2),
  );

  static const dark = AppTone(
    text: Color(0xFFF8FAFC),
    textSoft: Color(0xFFE2E8F0),
    textMuted: Color(0xFFCBD5E1),
    surface: Color(0xFF1E293B),
    scaffold: Color(0xFF0F172A),
    border: Color(0xFF334155),
    tintBg: Color(0xFF422006),
    tintBorder: Color(0xFF78350F),
    tintText: Color(0xFFFCD34D),
    accent: Color(0xFFF59E0B),
    onAccent: Color(0xFF1F1300),
    link: Color(0xFF93C5FD),
    error: Color(0xFFFCA5A5),
    positive: Color(0xFF6EE7B7),
    positiveBg: Color(0xFF064E3B),
    negative: Color(0xFFFCA5A5),
    negativeBg: Color(0xFF7F1D1D),
  );

  static AppTone of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.amber,
    primary: AppColors.amber,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.amber, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.amber,
      thumbColor: AppColors.amber,
      inactiveTrackColor: AppColors.line,
      overlayColor: Color(0x1FF59E0B),
      trackHeight: 4,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.amber,
      linearTrackColor: AppColors.line,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.amberSoft,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(color: AppColors.ink, fontSize: 13),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.amberSoft,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.amber,
    brightness: Brightness.dark,
    primary: AppColors.amber,
    surface: const Color(0xFF1E293B),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.amber,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: const Color(0xFF94A3B8),
      suffixIconColor: const Color(0xFF94A3B8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.amber, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.amber,
      thumbColor: AppColors.amber,
      inactiveTrackColor: Color(0xFF334155),
      overlayColor: Color(0x1FF59E0B),
      trackHeight: 4,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.amber,
      linearTrackColor: Color(0xFF334155),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: AppColors.amberDark,
      side: const BorderSide(color: Color(0xFF334155)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF1E293B),
      indicatorColor: AppColors.amberDark,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.amber,
        foregroundColor: Colors.black87,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

