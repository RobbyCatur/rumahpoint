import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
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
          _buildLastUpdated('1 Oktober 2026'),
          const SizedBox(height: 20),

          // Ringkasan
          _buildHighlightCard(
            icon: Icons.shield_outlined,
            color: Colors.indigo,
            text:
                'RumahPoint berkomitmen melindungi privasi Anda. '
                'Kami tidak menjual data pribadi kepada pihak ketiga manapun.',
          ),
          const SizedBox(height: 20),

          _buildSection(
            icon: Icons.person_outline,
            iconColor: Colors.indigo,
            title: 'Data yang Kami Kumpulkan',
            items: [
              'Nama dan alamat email saat registrasi akun.',
              'Riwayat prediksi: parameter properti yang Anda masukkan (luas, kamar, lokasi) dan hasil estimasi.',
              'Data teknis: versi aplikasi, jenis perangkat, dan log error (untuk perbaikan bug).',
            ],
          ),

          _buildSection(
            icon: Icons.storage_outlined,
            iconColor: Colors.indigo,
            title: 'Cara Kami Menyimpan Data',
            items: [
              'Riwayat prediksi disimpan secara lokal di perangkat Anda menggunakan SharedPreferences.',
              'Kredensial login (token JWT) disimpan di secure storage yang terenkripsi.',
              'Kami tidak menyimpan kata sandi Anda dalam bentuk teks biasa.',
            ],
          ),

          _buildSection(
            icon: Icons.share_outlined,
            iconColor: Colors.indigo,
            title: 'Penggunaan & Pembagian Data',
            items: [
              'Data prediksi Anda digunakan untuk meningkatkan akurasi model Machine Learning kami.',
              'Data tidak dibagikan kepada pihak komersial ketiga.',
              'Informasi agregat (tanpa identitas) dapat digunakan untuk keperluan riset akademik Polinema.',
            ],
          ),

          _buildSection(
            icon: Icons.lock_outline,
            iconColor: Colors.indigo,
            title: 'Keamanan Data',
            items: [
              'Komunikasi antara aplikasi dan server menggunakan HTTPS (TLS).',
              'Token akses memiliki masa berlaku 15 menit dan diperbarui secara otomatis.',
              'Anda dapat menghapus semua data lokal kapan saja melalui Pengaturan → Hapus Cache.',
            ],
          ),

          _buildSection(
            icon: Icons.manage_accounts_outlined,
            iconColor: Colors.indigo,
            title: 'Hak Pengguna',
            items: [
              'Anda berhak meminta penghapusan akun dan seluruh data terkait.',
              'Anda berhak mengakses riwayat data prediksi Anda kapan saja.',
              'Untuk permintaan penghapusan data, hubungi: pbl-rumahpoint@polinema.ac.id.',
            ],
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

  Widget _buildLastUpdated(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.update, color: Colors.indigo, size: 16),
          const SizedBox(width: 8),
          Text(
            'Terakhir diperbarui: $date',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.indigo,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
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
