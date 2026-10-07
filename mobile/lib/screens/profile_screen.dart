import 'package:flutter/material.dart';

import '../theme.dart';

/// Placeholder Profil — dikerjakan anggota tim lain (fitur auth).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.amberSoft,
              child: Icon(Icons.person_rounded,
                  size: 34, color: AppColors.amberDark),
            ),
            SizedBox(height: 14),
            Text(
              'Profil Pengguna',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Halaman ini sedang dalam pengembangan.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
