import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_provider.dart';
import 'settings_screen.dart';
import 'personal_info_screen.dart';
import 'region_preference_screen.dart';
import 'help_regulation_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Colors.black87, 
            fontSize: 22, 
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                // Mengarah ke halaman Pengaturan Utama (Menu Roda Gigi)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_outlined, color: Colors.black87, size: 22),
              ),
            ),
          )
        ],
      ),
      
      body: userState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) {
             return const Center(child: Text('Data pengguna tidak ditemukan.'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Card Profil
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B), 
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(user.nama), 
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 22, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -4,
                              right: -4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.check_circle, 
                                  color: Colors.blue, 
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.nama,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Baris Statistik
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildStatCard(user.totalValuasi.toString(), 'Valuasi')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(user.totalDisimpan.toString(), 'Disimpan')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(user.totalPortofolio.toString(), 'Portofolio')),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Daftar Menu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Informasi Pribadi & Sandi',
                          onTap: () => _navigateToSettings(context, 'Informasi Pribadi & Sandi'),
                        ),
                        _buildMenuDivider(),
                        _buildMenuItem(
                          icon: Icons.location_on_outlined,
                          iconColor: Colors.blue,
                          title: 'Preferensi Wilayah & NJOP',
                          onTap: () => _navigateToSettings(context, 'Preferensi Wilayah & NJOP'),
                        ),
                        _buildMenuDivider(),
                        _buildMenuItem(
                          icon: Icons.history, 
                          iconColor: Colors.grey.shade600,
                          title: 'Bantuan & Regulasi',
                          onTap: () => _navigateToSettings(context, 'Bantuan & Regulasi'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Tombol Logout Tersendiri
                  InkWell(
                    onTap: () async {
                       await ref.read(userProvider.notifier).logout();
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Proses logout dieksekusi.')),
                         );
                       }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              color: Colors.red, 
                              fontWeight: FontWeight.w600, 
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Logika navigasi ke file yang telah dipecah
  void _navigateToSettings(BuildContext context, String title) {
    Widget destination;
    
    if (title == 'Informasi Pribadi & Sandi') {
      destination = const PersonalInfoScreen();
    } else if (title == 'Preferensi Wilayah & NJOP') {
      destination = const RegionPreferenceScreen();
    } else {
      destination = const HelpRegulationScreen();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = "";
    int numWords = names.length > 2 ? 2 : names.length;
    for(int i = 0; i < numWords; i++){
      if(names[i].isNotEmpty){
        initials += names[i][0].toUpperCase();
      }
    }
    return initials;
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value, 
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: const TextStyle(
              fontSize: 12, 
              color: Colors.grey, 
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon, 
    required Color iconColor, 
    required String title, 
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
           color: iconColor.withOpacity(0.08),
           shape: BoxShape.circle,
         ),
         child: Icon(icon, color: iconColor, size: 22)
      ),
      title: Text(
        title, 
        style: const TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.w600, 
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
    );
  }
}