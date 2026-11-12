import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = AppTone.of(context);

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
                const SizedBox(height: 30),
                Text(
                  'Selamat datang di RumahPoint',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: tone.text,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Prediksi harga properti dengan mudah dan berbasis data.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tone.textSoft,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Fitur RumahPoint',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: tone.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                const _FeatureTile(
                  icon: Icons.calculate_rounded,
                  title: 'Prediksi harga properti',
                  description:
                      'Dapatkan estimasi harga dalam hitungan detik.',
                ),
                const SizedBox(height: 12),
                const _FeatureTile(
                  icon: Icons.location_city_rounded,
                  title: 'Berbasis data berbagai kota',
                  description:
                      'Gunakan data properti dari berbagai kota.',
                ),
                const SizedBox(height: 12),
                const _FeatureTile(
                  icon: Icons.history_rounded,
                  title: 'Simpan riwayat prediksi',
                  description:
                      'Lihat kembali prediksi kapan saja.',
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Mulai Sekarang'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Masuk atau buat akun untuk mulai.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tone.textMuted,
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
    final tone = AppTone.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone.accent, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tone.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tone.textMuted,
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
