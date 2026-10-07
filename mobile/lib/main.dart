import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const ProviderScope(child: RumahPointApp()));
}

class RumahPointApp extends StatelessWidget {
  const RumahPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rumah Point',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF59E0B)),
        useMaterial3: true,
      ),
      home: const DummyShell(),
    );
  }
}

// Tiruan Navigation Bar hanya untuk uji coba visual
class DummyShell extends StatelessWidget {
  const DummyShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const ProfileScreen(), // Memanggil layar profil buatanmu
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1), // Garis tipis pembatas di atas menu
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white, // Membuat latar belakang putih bersih
          elevation: 0, // Menghilangkan bayangan bawaan
          currentIndex: 2, // Mengunci fokus pada tab "Profil"
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFF59E0B), // Warna saat menu dipilih
          unselectedItemColor: Colors.grey.shade400, // Warna saat menu tidak dipilih
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.home_rounded),
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.history_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.history_rounded),
              ),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.person_outline_rounded),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.person_rounded),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}