import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/prediction_controller.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(predictionControllerProvider).current;
    if (p == null) {
      return const Scaffold(
        body: Center(child: Text('Belum ada hasil. Kembali dan isi form.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Estimasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(p.kategori == 'Murah' ? 'Terjangkau' : 'Premium',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(p.estimasiString,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Keyakinan model: ${(p.confidence * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _row('Luas tanah', '${p.luasM2} m2'),
          _row('Kamar tidur', '${p.jumlahKamar}'),
          _row('Kamar mandi', '${p.jumlahKamarMandi}'),
          _row('Usia bangunan', '${p.usiaBangunan} tahun'),
          _row('Lokasi', p.lokasi),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tips_and_updates),
              title: const Text('Rekomendasi'),
              subtitle: Text(p.kategori == 'Murah'
                  ? 'Harga tergolong wajar untuk area ${p.lokasi}. Cocok untuk pembeli pertama.'
                  : 'Harga tinggi di area ${p.lokasi}. Nilai lebih pada lokasi & luas.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
