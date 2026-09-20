import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/prediction_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(predictionControllerProvider).history.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Prediksi'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              onPressed: () =>
                  ref.read(predictionControllerProvider.notifier).clearHistory(),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text('Belum ada riwayat.'))
          : ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = history[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(p.kategori == 'Murah' ? 'M' : 'P'),
                  ),
                  title: Text(p.estimasiString),
                  subtitle: Text('${p.lokasi} • ${p.luasM2} m2 • ${p.jumlahKamar} kt'),
                  trailing: Text(
                    '${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
    );
  }
}
