import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/prediction.dart';
import '../state/prediction_controller.dart';
import '../theme.dart';
import '../utils/format.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';
  String _filter = 'Semua';

  List<Prediction> _applyFilter(List<Prediction> history) {
    return history.reversed.where((p) {
      final matchFilter = _filter == 'Semua' || p.kategori == _filter;
      final matchQuery =
          p.lokasi.toLowerCase().contains(_query.toLowerCase());
      return matchFilter && matchQuery;
    }).toList();
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Semua riwayat prediksi akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(predictionControllerProvider.notifier).clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(predictionControllerProvider).history;
    final items = _applyFilter(history);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Valuasi'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Hapus semua',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Cari riwayat lokasi...',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                for (final f in ['Semua', 'Murah', 'Mahal']) ...[
                  ChoiceChip(
                    label: Text(f == 'Semua'
                        ? 'Semua (${history.length})'
                        : f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                  if (f != 'Mahal') const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _HistoryCard(p: items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.p});

  final Prediction p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ref.read(predictionControllerProvider.notifier).select(p);
          context.push('/hasil');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work_rounded,
                    color: AppColors.amberDark, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.lokasi,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${p.luasM2.round()} m² • ${p.jumlahKamar} KT • ${p.jumlahKamarMandi} KM',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTanggal(p.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    p.estimasiString,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.kategori,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amberDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 48, color: AppColors.line),
          SizedBox(height: 12),
          Text(
            'Belum ada riwayat',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Hasil prediksi akan tersimpan di sini.',
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
