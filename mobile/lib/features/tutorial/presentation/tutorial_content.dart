import 'package:flutter/material.dart';

import '../domain/tutorial_page.dart';

/// Satu langkah panduan yang ditampilkan sebagai kartu popup.
class TutorialStep {
  const TutorialStep({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

/// Panduan singkat untuk fitur utama tiap halaman.
const tutorialContent = <TutorialPage, List<TutorialStep>>{
  TutorialPage.beranda: [
    TutorialStep(
      icon: Icons.tune_rounded,
      title: 'Isi detail properti',
      message:
          'Atur luas tanah, luas bangunan, jumlah kamar, dan kondisi rumah. '
          'Kamu bisa menggeser atau mengetik angkanya langsung.',
    ),
    TutorialStep(
      icon: Icons.location_on_outlined,
      title: 'Tentukan lokasi',
      message:
          'Pilih provinsi dan kabupaten/kota, atau pakai tombol lokasi saat '
          'ini agar Beranda langsung mengisi wilayahmu.',
    ),
    TutorialStep(
      icon: Icons.calculate_outlined,
      title: 'Hitung valuasi',
      message:
          'Tekan “Hitung Valuasi Sekarang” untuk melihat estimasi harga, '
          'rentang, dan kategori Murah/Mahal.',
    ),
  ],
  TutorialPage.riwayat: [
    TutorialStep(
      icon: Icons.history_rounded,
      title: 'Riwayat tersimpan otomatis',
      message:
          'Setiap hasil prediksi masuk ke sini. Ketuk kartu untuk membuka '
          'kembali detailnya kapan saja.',
    ),
    TutorialStep(
      icon: Icons.filter_alt_outlined,
      title: 'Saring dengan satu tombol',
      message:
          'Tombol Filter membantumu menyaring berdasarkan kategori, lokasi '
          'yang pernah dicari, dan rentang tanggal.',
    ),
    TutorialStep(
      icon: Icons.search_rounded,
      title: 'Cari lebih cepat',
      message:
          'Gunakan kolom pencarian untuk menemukan riwayat lokasi tertentu '
          'tanpa menggulir daftar.',
    ),
  ],
  TutorialPage.profil: [
    TutorialStep(
      icon: Icons.person_outline_rounded,
      title: 'Kelola akun',
      message:
          'Buka Informasi Pribadi & Sandi untuk melihat data akun dan '
          'mengatur keamananmu.',
    ),
    TutorialStep(
      icon: Icons.location_city_rounded,
      title: 'Atur wilayah default',
      message:
          'Preferensi Wilayah membuat Beranda langsung memakai lokasi '
          'favoritmu setiap kali dibuka.',
    ),
    TutorialStep(
      icon: Icons.help_outline_rounded,
      title: 'Bantuan & panduan',
      message:
          'Di Bantuan & Regulasi kamu bisa membaca panduan, dan memutar '
          'ulang tutorial ini kapan saja lewat menu Panduan Aplikasi.',
    ),
  ],
};
