import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final appBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor =
        isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Disclaimer Penilaian Properti',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: dividerColor,
            height: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Warning banner utama
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF78350F).withValues(alpha: 0.28)
                  : Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hasil estimasi dari RumahPoint adalah alat bantu analisis, '
                    'bukan penilaian resmi (appraisal) yang diakui secara hukum. '
                    'Jangan jadikan satu-satunya dasar keputusan transaksi properti.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFE2E8F0) : Colors.black54,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildCard(
            context: context,
            icon: Icons.model_training_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Tentang Model Prediksi',
            content:
                'RumahPoint menggunakan algoritma Random Forest yang dilatih dengan 64.650 data '
                'properti dari 403 kabupaten/kota di Indonesia. Model ini memiliki nilai R² (koefisien determinasi) '
                'sebesar 0,49 — artinya sekitar 49% variasi harga dapat dijelaskan oleh model. '
                'Sisa 51% dipengaruhi faktor yang belum tercakup dalam dataset seperti kondisi fisik '
                'bangunan, akses jalan, dan faktor lokal spesifik. '
                'Angka tersebut rata-rata seluruh wilayah: pada kabupaten/kota yang data latihnya masih sedikit, '
                'galat estimasi membesar dan aplikasi menandainya dengan peringatan.',
          ),

          _buildCard(
            context: context,
            icon: Icons.location_off_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Keterbatasan Geografis',
            content:
                'Dataset pelatihan tersebar di 403 kabupaten/kota dengan kepadatan yang tidak merata. '
                'Wilayah yang jumlah data latihnya belum cukup ditandai dengan peringatan saat prediksi. '
                'Estimasi untuk properti di luar wilayah yang pernah dilatih, atau di kecamatan yang sangat spesifik, '
                'mungkin kurang akurat karena model melakukan ekstrapolasi di luar distribusi data latih.',
          ),

          _buildCard(
            context: context,
            icon: Icons.trending_up_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Dinamika Pasar Properti',
            content:
                'Harga properti bersifat sangat dinamis dan dipengaruhi oleh: kondisi ekonomi makro, '
                'kebijakan pemerintah (BI Rate, subsidi KPR), sentiment pasar, dan faktor musiman. '
                'Model kami dilatih pada data historis dan tidak memprediksi pergerakan harga di masa depan.',
          ),

          _buildCard(
            context: context,
            icon: Icons.rule_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Bukan Penilai Resmi (KJPP)',
            content:
                'Penilaian resmi properti untuk keperluan KPR, sengketa hukum, atau keperluan perpajakan '
                'harus dilakukan oleh Kantor Jasa Penilai Publik (KJPP) yang berizin dari Kemenkeu RI. '
                'RumahPoint tidak dapat menggantikan fungsi KJPP dan tidak memiliki kewenangan hukum '
                'sebagai lembaga penilai.',
          ),

          _buildCard(
            context: context,
            icon: Icons.school_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Konteks Akademik',
            content:
                'RumahPoint dikembangkan sebagai proyek berbasis masalah (PBL) mahasiswa Teknologi Informasi '
                'Polinema Semester 5. Aplikasi ini bersifat non-komersial dan merupakan karya ilmiah '
                'untuk keperluan pembelajaran. Pengembang tidak bertanggung jawab atas kerugian yang '
                'timbul akibat penggunaan hasil prediksi ini.',
          ),

          const SizedBox(height: 24),

          // Panduan penggunaan yang baik
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : Colors.green.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Panduan Penggunaan yang Bijak',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...[
                  'Gunakan sebagai referensi awal sebelum survei lapangan.',
                  'Bandingkan hasil dengan listing di platform properti lain.',
                  'Konsultasikan dengan agen properti berpengalaman untuk keputusan final.',
                  'Lakukan due diligence dan cek legalitas dokumen properti.',
                ].map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.arrow_right,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'RumahPoint v1.0.0 © 2026 Kelompok 5 PBL Polinema',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final contentColor = isDark ? const Color(0xFFCBD5E1) : Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: contentColor,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
