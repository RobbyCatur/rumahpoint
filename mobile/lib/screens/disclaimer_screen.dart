import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Disclaimer Penilaian Properti',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.withOpacity(0.15),
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
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hasil estimasi dari RumahPoint adalah alat bantu analisis, '
                    'bukan penilaian resmi (appraisal) yang diakui secara hukum. '
                    'Jangan jadikan satu-satunya dasar keputusan transaksi properti.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildCard(
            icon: Icons.model_training_outlined,
            iconColor: Colors.orange,
            title: 'Tentang Model Prediksi',
            content:
                'RumahPoint menggunakan algoritma Random Forest yang dilatih dengan dataset '
                'properti dari 7 kota di Indonesia. Model ini memiliki nilai R² (koefisien determinasi) '
                'sebesar 0,85 — artinya sekitar 85% variasi harga dapat dijelaskan oleh model. '
                'Sisa 15% dipengaruhi faktor yang belum tercakup dalam dataset seperti kondisi fisik '
                'bangunan, akses jalan, dan faktor lokal spesifik.',
          ),

          _buildCard(
            icon: Icons.location_off_outlined,
            iconColor: Colors.orange,
            title: 'Keterbatasan Geografis',
            content:
                'Dataset pelatihan hanya mencakup 7 wilayah: Jakarta Selatan, Jakarta Utara, '
                'Bekasi, Bogor, Depok, Tangerang, dan Surabaya. '
                'Estimasi untuk properti di luar wilayah ini atau di kecamatan yang sangat spesifik '
                'mungkin kurang akurat karena model melakukan ekstrapolasi di luar distribusi data latih.',
          ),

          _buildCard(
            icon: Icons.trending_up_outlined,
            iconColor: Colors.orange,
            title: 'Dinamika Pasar Properti',
            content:
                'Harga properti bersifat sangat dinamis dan dipengaruhi oleh: kondisi ekonomi makro, '
                'kebijakan pemerintah (BI Rate, subsidi KPR), sentiment pasar, dan faktor musiman. '
                'Model kami dilatih pada data historis dan tidak memprediksi pergerakan harga di masa depan.',
          ),

          _buildCard(
            icon: Icons.rule_outlined,
            iconColor: Colors.orange,
            title: 'Bukan Penilai Resmi (KJPP)',
            content:
                'Penilaian resmi properti untuk keperluan KPR, sengketa hukum, atau keperluan perpajakan '
                'harus dilakukan oleh Kantor Jasa Penilai Publik (KJPP) yang berizin dari Kemenkeu RI. '
                'RumahPoint tidak dapat menggantikan fungsi KJPP dan tidak memiliki kewenangan hukum '
                'sebagai lembaga penilai.',
          ),

          _buildCard(
            icon: Icons.school_outlined,
            iconColor: Colors.orange,
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
              color: Colors.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Panduan Penggunaan yang Bijak',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
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
          const Text(
            'RumahPoint v1.0.0 © 2026 Kelompok 5 PBL Polinema',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
