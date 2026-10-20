import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = [
    (
      q: 'Bagaimana cara kerja prediksi harga di RumahPoint?',
      a:
          'RumahPoint menggunakan model Machine Learning (Random Forest) yang dilatih dengan data ribuan properti dari 7 kota besar di Indonesia. '
              'Anda cukup mengisi data seperti luas tanah, luas bangunan, jumlah kamar, dan lokasi — sistem kami akan memberikan estimasi harga beserta kategori Murah/Mahal secara otomatis.',
    ),
    (
      q: 'Seberapa akurat hasil prediksi harga properti?',
      a:
          'Model kami saat ini memiliki akurasi regresi R² sebesar 0,85 dan akurasi klasifikasi 93,3%. '
              'Namun, hasil prediksi bersifat estimasi dan tidak menggantikan penilaian profesional dari Appraisal atau KJPP. '
              'Gunakan hasil ini sebagai referensi awal sebelum melakukan survei lapangan.',
    ),
    (
      q: 'Kota apa saja yang didukung oleh RumahPoint?',
      a:
          'Saat ini RumahPoint mendukung 7 kota/wilayah: Jakarta Selatan, Jakarta Utara, Bekasi, Bogor, Depok, Tangerang, dan Surabaya. '
              'Kami akan terus memperluas cakupan dataset ke lebih banyak kota di Indonesia.',
    ),
    (
      q: 'Apakah data properti yang saya masukkan tersimpan?',
      a:
          'Riwayat prediksi Anda disimpan secara lokal di perangkat Anda. '
              'Data tidak dikirimkan ke pihak ketiga manapun. '
              'Anda dapat menghapus riwayat kapan saja melalui menu Pengaturan → Hapus Cache Aplikasi.',
    ),
    (
      q: 'Apa perbedaan kategori "Murah" dan "Mahal"?',
      a:
          'Kategori ditentukan berdasarkan median harga properti per kota. '
              'Properti dengan estimasi harga di atas median kota tersebut dikategorikan "Mahal", '
              'sedangkan yang di bawah median dikategorikan "Murah". '
              'Ambang batas median diperbarui setiap kali model dilatih ulang dengan data terbaru.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final appBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : Colors.grey.shade100;
    final contentColor = isDark ? const Color(0xFFCBD5E1) : Colors.black54;
    final dividerColor =
        isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Pertanyaan Umum (FAQ)',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Banner info
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF78350F).withValues(alpha: 0.28)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ketuk pertanyaan untuk melihat jawaban lengkapnya.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFE2E8F0) : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // FAQ items
          ..._faqs.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  iconColor: const Color(0xFFF59E0B),
                  collapsedIconColor:
                      isDark ? const Color(0xFF94A3B8) : Colors.grey,
                  title: Text(
                    item.q,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  children: [
                    Divider(
                      height: 1,
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.a,
                      style: TextStyle(
                        fontSize: 13,
                        color: contentColor,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'RumahPoint v1.0.0 © 2026 Kelompok 5 PBL Polinema',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
