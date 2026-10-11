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

  /// Kunci bulan terpilih "tahun-bulan" (mis. 2025-9); null = semua bulan.
  String? _bulan;

  static String _monthKey(DateTime d) => '${d.year}-${d.month}';

  /// Daftar bulan unik dari riwayat, terbaru dulu.
  List<DateTime> _availableMonths(List<Prediction> history) {
    final seen = <String>{};
    final months = <DateTime>[];
    for (final p in history.reversed) {
      final key = _monthKey(p.createdAt);
      if (seen.add(key)) {
        months.add(DateTime(p.createdAt.year, p.createdAt.month));
      }
    }
    return months;
  }

  List<Prediction> _applyFilter(List<Prediction> history) {
    return history.reversed.where((p) {
      final matchFilter = _filter == 'Semua' || p.kategori == _filter;
      final matchQuery =
          p.lokasi.toLowerCase().contains(_query.toLowerCase());
      final matchMonth = _bulan == null || _monthKey(p.createdAt) == _bulan;
      return matchFilter && matchQuery && matchMonth;
    }).toList();
  }

  /// Kelompokkan item (sudah terurut terbaru) per bulan, terbaru dulu.
  List<({String key, DateTime month, List<Prediction> items})> _groupByMonth(
      List<Prediction> items) {
    final groups =
        <({String key, DateTime month, List<Prediction> items})>[];
    for (final p in items) {
      final key = _monthKey(p.createdAt);
      if (groups.isEmpty || groups.last.key != key) {
        groups.add((
          key: key,
          month: DateTime(p.createdAt.year, p.createdAt.month),
          items: [p],
        ));
      } else {
        groups.last.items.add(p);
      }
    }
    return groups;
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
    final months = _availableMonths(history);
    final items = _applyFilter(history);
    final groups = _groupByMonth(items);

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
          if (months.length > 1)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                children: [
                  ChoiceChip(
                    label: const Text('Semua bulan'),
                    selected: _bulan == null,
                    onSelected: (_) => setState(() => _bulan = null),
                  ),
                  for (final m in months) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(formatBulanSingkat(m)),
                      selected: _bulan == _monthKey(m),
                      onSelected: (_) =>
                          setState(() => _bulan = _monthKey(m)),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: groups.length,
                    itemBuilder: (context, gi) {
                      final g = groups[gi];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                2, gi == 0 ? 8 : 20, 2, 8),
                            child: Text(
                              formatBulanPenuh(g.month),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          for (var i = 0; i < g.items.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _HistoryCard(p: g.items[i]),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Badge kategori kecil: hijau + panah turun untuk Murah,
/// merah + panah naik untuk Mahal.
class _KategoriBadge extends StatelessWidget {
  const _KategoriBadge({required this.kategori});

  final String kategori;

  @override
  Widget build(BuildContext context) {
    final isMurah = kategori.toLowerCase() == 'murah';
    final fg = isMurah ? AppColors.success : AppColors.danger;
    final bg = isMurah ? AppColors.successSoft : AppColors.dangerSoft;
    final icon =
        isMurah ? Icons.trending_down_rounded : Icons.trending_up_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            kategori,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
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
                  _KategoriBadge(kategori: p.kategori),
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
