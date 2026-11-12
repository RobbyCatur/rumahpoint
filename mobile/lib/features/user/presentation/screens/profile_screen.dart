import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tutorial/presentation/tutorial_picker.dart';
import '../providers/user_providers.dart';
import 'settings_screen.dart';
import 'personal_info_screen.dart';
import 'region_preference_screen.dart';
import 'help_regulation_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Profil Saya',
          style: TextStyle(
            color: textColor,
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
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
                ),
                child: Icon(Icons.settings_outlined, color: textColor, size: 22),
              ),
            ),
          )
        ],
      ),
      body: userState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: textColor),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'Data pengguna tidak ditemukan.',
                style: TextStyle(color: textColor),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Card Profil — header identitas statis (navigasi
                  // ke PersonalInfoScreen hanya lewat menu di bawah).
                  Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.nama,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ),

                  const SizedBox(height: 24),

                  // Daftar Menu
                  Material(
                    color: cardColor,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          context: context,
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Informasi Pribadi & Sandi',
                          onTap: () => _navigateToSettings(
                            context,
                            'Informasi Pribadi & Sandi',
                          ),
                        ),
                        _buildMenuDivider(context),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.location_on_outlined,
                          iconColor: Colors.blue,
                          title: 'Preferensi Wilayah',
                          onTap: () => _navigateToSettings(
                            context,
                            'Preferensi Wilayah',
                          ),
                        ),
                        _buildMenuDivider(context),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.tips_and_updates_outlined,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Panduan Aplikasi',
                          onTap: () => showTutorialPicker(context),
                        ),
                        _buildMenuDivider(context),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.help_outline,
                          iconColor: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade600,
                          title: 'Bantuan & Regulasi',
                          onTap: () => _navigateToSettings(
                            context,
                            'Bantuan & Regulasi',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tombol Logout
                  InkWell(
                    onTap: () async {
                      await ref.read(userProvider.notifier).logout();
                      if (context.mounted) context.go('/');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF450A0A).withValues(alpha: 0.4)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF991B1B).withValues(alpha: 0.5)
                              : Colors.red.shade100,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: isDark
                                ? const Color(0xFFF87171)
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFF87171)
                                  : Colors.red,
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
    } else if (title == 'Preferensi Wilayah') {
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
    for (int i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials;
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: subtitleColor,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildMenuDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: isDark
            ? const Color(0xFF334155)
            : Colors.grey.withValues(alpha: 0.15),
      ),
    );
  }
}
