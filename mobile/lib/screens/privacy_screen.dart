import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          'Kebijakan Privasi',
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

          // Ringkasan
          _buildHighlightCard(
            isDark: isDark,
            icon: Icons.shield_outlined,
            color: Colors.indigo,
            text:
                'RumahPoint berkomitmen melindungi privasi Anda. '
                'Kami tidak menjual data pribadi kepada pihak ketiga manapun.',
          ),
          const SizedBox(height: 20),

          _buildSection(
            context: context,
            icon: Icons.person_outline,
            iconColor: isDark ? const Color(0xFF818CF8) : Colors.indigo,
            title: 'Data yang Kami Kumpulkan',
            items: [
              'Nama dan alamat email saat registrasi akun.',
              'Riwayat prediksi: parameter properti yang Anda masukkan (luas, kamar, lokasi) dan hasil estimasi.',
              'Data teknis: versi aplikasi, jenis perangkat, dan log error (untuk perbaikan bug).',
            ],
          ),

          _buildSection(
            context: context,
            icon: Icons.storage_outlined,
            iconColor: isDark ? const Color(0xFF818CF8) : Colors.indigo,
            title: 'Cara Kami Menyimpan Data',
            items: [
              'Riwayat prediksi disimpan secara lokal di perangkat Anda menggunakan SharedPreferences.',
              'Kredensial login (token JWT) disimpan di secure storage yang terenkripsi.',
              'Kami tidak menyimpan kata sandi Anda dalam bentuk teks biasa.',
            ],
          ),

          _buildSection(
            context: context,
            icon: Icons.share_outlined,
            iconColor: isDark ? const Color(0xFF818CF8) : Colors.indigo,
            title: 'Penggunaan & Pembagian Data',
            items: [
              'Data prediksi Anda digunakan untuk meningkatkan akurasi model Machine Learning kami.',
              'Data tidak dibagikan kepada pihak komersial ketiga.',
              'Informasi agregat (tanpa identitas) dapat digunakan untuk keperluan riset akademik Polinema.',
            ],
          ),

          _buildSection(
            context: context,
            icon: Icons.lock_outline,
            iconColor: isDark ? const Color(0xFF818CF8) : Colors.indigo,
            title: 'Keamanan Data',
            items: [
              'Komunikasi antara aplikasi dan server menggunakan HTTPS (TLS).',
              'Token akses memiliki masa berlaku 15 menit dan diperbarui secara otomatis.',
              'Anda dapat menghapus semua data lokal kapan saja melalui Pengaturan → Hapus Cache.',
            ],
          ),

          _buildSection(
            context: context,
            icon: Icons.manage_accounts_outlined,
            iconColor: isDark ? const Color(0xFF818CF8) : Colors.indigo,
            title: 'Hak Pengguna',
            items: [
              'Anda berhak meminta penghapusan akun dan seluruh data terkait.',
              'Anda berhak mengakses riwayat data prediksi Anda kapan saja.',
              'Untuk permintaan penghapusan data, hubungi: pbl-rumahpoint@polinema.ac.id.',
            ],
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

  Widget _buildLastUpdated(String date, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF312E81).withValues(alpha: 0.3)
            : Colors.indigo.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
              : Colors.indigo.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            color: isDark ? const Color(0xFF818CF8) : Colors.indigo,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Terakhir diperbarui: $date',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF818CF8) : Colors.indigo,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF312E81).withValues(alpha: 0.3)
            : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
              : color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isDark ? const Color(0xFF818CF8) : color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFE2E8F0) : Colors.black54,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? const Color(0xFFCBD5E1) : Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          color: bodyColor,
                          height: 1.6,
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
    );
  }
}
