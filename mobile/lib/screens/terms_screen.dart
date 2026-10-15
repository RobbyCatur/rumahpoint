import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Syarat & Ketentuan',
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

          _buildSection(
            number: '1',
            title: 'Penerimaan Syarat',
            body:
                'Dengan menggunakan aplikasi RumahPoint, Anda menyatakan telah membaca, memahami, '
                'dan menyetujui seluruh syarat dan ketentuan yang tercantum di sini. '
                'Jika Anda tidak menyetujui sebagian atau seluruh ketentuan, harap hentikan penggunaan aplikasi.',
          ),

          _buildSection(
            number: '2',
            title: 'Deskripsi Layanan',
            body:
                'RumahPoint adalah aplikasi estimasi harga properti berbasis Machine Learning yang dikembangkan '
                'sebagai proyek akademik (PBL TI Polinema Semester 5). '
                'Aplikasi menyediakan fitur: estimasi harga properti, klasifikasi kategori harga (Murah/Mahal), '
                'riwayat prediksi, dan preferensi wilayah.',
          ),

          _buildSection(
            number: '3',
            title: 'Penggunaan yang Diizinkan',
            body:
                'Layanan RumahPoint hanya boleh digunakan untuk keperluan referensi pribadi dan non-komersial. '
                'Pengguna dilarang: (a) mereproduksi atau mendistribusikan konten aplikasi tanpa izin tertulis; '
                '(b) melakukan reverse engineering terhadap model prediksi; '
                '(c) menggunakan layanan untuk tujuan yang melanggar hukum yang berlaku di Indonesia.',
          ),

          _buildSection(
            number: '4',
            title: 'Batasan Tanggung Jawab',
            body:
                'Hasil prediksi yang dihasilkan RumahPoint bersifat estimasi berdasarkan data historis dan '
                'tidak menjamin keakuratan harga aktual di pasar. '
                'Tim pengembang tidak bertanggung jawab atas keputusan investasi atau transaksi properti '
                'yang dibuat berdasarkan hasil prediksi aplikasi ini.',
          ),

          _buildSection(
            number: '5',
            title: 'Perubahan Layanan',
            body:
                'Tim pengembang berhak mengubah, menangguhkan, atau menghentikan layanan sewaktu-waktu '
                'tanpa pemberitahuan sebelumnya. '
                'Perubahan pada syarat dan ketentuan ini akan diumumkan melalui pembaruan aplikasi.',
          ),

          _buildSection(
            number: '6',
            title: 'Hukum yang Berlaku',
            body:
                'Syarat dan ketentuan ini tunduk pada hukum yang berlaku di Republik Indonesia. '
                'Segala sengketa yang timbul akan diselesaikan secara musyawarah. '
                'Jika tidak tercapai kesepakatan, penyelesaian mengacu pada ketentuan hukum Indonesia.',
          ),

          const SizedBox(height: 32),
          _buildContactInfo(),
          const SizedBox(height: 20),
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
        color: Colors.teal.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.update, color: Colors.teal, size: 16),
          const SizedBox(width: 8),
          Text(
            'Terakhir diperbarui: $date',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.teal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String body,
  }) {
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
                  color: Colors.teal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertanyaan tentang Ketentuan?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hubungi kami di: pbl-rumahpoint@polinema.ac.id',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
