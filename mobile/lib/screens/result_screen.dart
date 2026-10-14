import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../features/prediction/domain/entities/prediction.dart';
import '../features/prediction/presentation/providers/prediction_providers.dart';
import '../theme.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(predictionControllerProvider).current;
    if (p == null) {
      return const Scaffold(
        body: Center(child: Text('Belum ada hasil. Isi form di Beranda.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Estimasi Valuasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.lokasi,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              _KategoriChip(kategori: p.kategori),
            ],
          ),
          const SizedBox(height: 16),
          _PriceCard(p: p),
          const SizedBox(height: 16),
          _DetailCard(p: p),
          const SizedBox(height: 16),
          const Text(
            'Estimasi dihasilkan model Random Forest. Rentang ±25% dari nilai tengah sebagai indikasi, bukan interval statistik ketat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.p});

  final Prediction p;

  @override
  Widget build(BuildContext context) {
    final hasRentang = p.rentangBawah.isNotEmpty && p.rentangAtas.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: AppColors.amber),
                SizedBox(width: 6),
                Text(
                  'HARGA WAJAR (FAIR MARKET)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.amberDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'TAKSIRAN NILAI PROPERTI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatRupiah(p.estimasiHarga),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            if (hasRentang) ...[
              const SizedBox(height: 4),
              Text(
                'Rentang: ${p.rentangBawah} – ${p.rentangAtas}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppColors.line, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Skor Keyakinan AI',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatPersen(p.confidence),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amberDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: p.confidence.clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.p});

  final Prediction p;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            _row('Luas tanah', '${formatLuas(p.luasM2)} m²'),
            _row('Luas bangunan', '${formatLuas(p.luasBangunan)} m²'),
            _row('Kamar tidur', '${p.jumlahKamar}'),
            _row('Kamar mandi', '${p.jumlahKamarMandi}'),
            _row('Usia bangunan', '${p.usiaBangunan} tahun'),
            _row('Lokasi', p.lokasi, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _KategoriChip extends StatelessWidget {
  const _KategoriChip({required this.kategori});

  final String kategori;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        kategori,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.amberDark,
        ),
      ),
    );
  }
}
