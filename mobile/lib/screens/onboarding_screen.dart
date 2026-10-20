import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/rumahpoint.png',
                    width: 68,
                    height: 68,
                    errorBuilder: (_, _, _) => Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.home_work_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Selamat datang di\nRumahPoint',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kenali nilai wajar properti di Indonesia dengan lebih mudah, cepat, dan berbasis data.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'RumahPoint membantu memperkirakan harga rumah dan memahami kategorinya sebelum kamu mengambil keputusan.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Apa yang bisa kamu lakukan?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const _FeatureTile(
                  icon: Icons.calculate_rounded,
                  title: 'Prediksi harga properti',
                  description:
                      'Masukkan detail rumah dan dapatkan estimasi harga dalam hitungan detik.',
                ),
                const SizedBox(height: 12),
                const _FeatureTile(
                  icon: Icons.location_city_rounded,
                  title: 'Berbasis data berbagai kota',
                  description:
                      'Gunakan referensi data properti dari beberapa kota di Indonesia.',
                ),
                const SizedBox(height: 12),
                const _FeatureTile(
                  icon: Icons.history_rounded,
                  title: 'Simpan riwayat prediksi',
                  description:
                      'Pantau kembali hasil prediksi yang pernah kamu buat kapan saja.',
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Mulai Sekarang'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Buat akun atau masuk untuk mulai menggunakan RumahPoint.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.amberDark, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
