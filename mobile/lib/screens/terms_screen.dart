import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Syarat & Ketentuan',
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
        padding: const EdgeInsets.all(20),
        children: [
          _buildLastUpdated('1 Oktober 2026', isDark: isDark),
          const SizedBox(height: 20),

          _buildSection(
            context: context,
            number: '1',
            title: 'Penerimaan Syarat',
            body:
                'Dengan menggunakan aplikasi RumahPoint, Anda menyatakan telah membaca, memahami, '
                'dan menyetujui seluruh syarat dan ketentuan yang tercantum di sini. '
                'Jika Anda tidak menyetujui sebagian atau seluruh ketentuan, harap hentikan penggunaan aplikasi.',
          ),

          _buildSection(
            context: context,
            number: '2',
            title: 'Deskripsi Layanan',
            body:
                'RumahPoint adalah aplikasi estimasi harga properti berbasis Machine Learning yang dikembangkan '
                'sebagai proyek akademik (PBL TI Polinema Semester 5). '
                'Aplikasi menyediakan fitur: estimasi harga properti, klasifikasi kategori harga (Murah/Mahal), '
                'riwayat prediksi, dan preferensi wilayah.',
          ),

          _buildSection(
            context: context,
            number: '3',
            title: 'Penggunaan yang Diizinkan',
            body:
                'Layanan RumahPoint hanya boleh digunakan untuk keperluan referensi pribadi dan non-komersial. '
                'Pengguna dilarang: (a) mereproduksi atau mendistribusikan konten aplikasi tanpa izin tertulis; '
                '(b) melakukan reverse engineering terhadap model prediksi; '
                '(c) menggunakan layanan untuk tujuan yang melanggar hukum yang berlaku di Indonesia.',
          ),

          _buildSection(
            context: context,
            number: '4',
            title: 'Batasan Tanggung Jawab',
            body:
                'Hasil prediksi yang dihasilkan RumahPoint bersifat estimasi berdasarkan data historis dan '
                'tidak menjamin keakuratan harga aktual di pasar. '
                'Tim pengembang tidak bertanggung jawab atas keputusan investasi atau transaksi properti '
                'yang dibuat berdasarkan hasil prediksi aplikasi ini.',
          ),

          _buildSection(
            context: context,
            number: '5',
            title: 'Perubahan Layanan',
            body:
                'Tim pengembang berhak mengubah, menangguhkan, atau menghentikan layanan sewaktu-waktu '
                'tanpa pemberitahuan sebelumnya. '
                'Perubahan pada syarat dan ketentuan ini akan diumumkan melalui pembaruan aplikasi.',
          ),

          _buildSection(
            context: context,
            number: '6',
            title: 'Hukum yang Berlaku',
            body:
                'Syarat dan ketentuan ini tunduk pada hukum yang berlaku di Republik Indonesia. '
                'Segala sengketa yang timbul akan diselesaikan secara musyawarah. '
                'Jika tidak tercapai kesepakatan, penyelesaian mengacu pada ketentuan hukum Indonesia.',
          ),

          const SizedBox(height: 32),
          _buildContactInfo(isDark: isDark),
          const SizedBox(height: 20),
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

  Widget _buildLastUpdated(String date, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF134E4A).withValues(alpha: 0.3)
            : Colors.teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
              : Colors.teal.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            color: isDark ? const Color(0xFF2DD4BF) : Colors.teal,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Terakhir diperbarui: $date',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF2DD4BF) : Colors.teal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String number,
    required String title,
    required String body,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? const Color(0xFFCBD5E1) : Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF14B8A6).withValues(alpha: 0.2)
                      : Colors.teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF2DD4BF) : Colors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              body,
              style: TextStyle(
                fontSize: 13,
                color: bodyColor,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo({required bool isDark}) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade50;
    final borderColor =
        isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertanyaan tentang Ketentuan?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hubungi kami di: pbl-rumahpoint@polinema.ac.id',
            style: TextStyle(fontSize: 13, color: subtitleColor),
          ),
        ],
      ),
    );
  }
}
