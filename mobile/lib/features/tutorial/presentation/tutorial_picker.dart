import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../domain/tutorial_page.dart';
import 'tutorial_dialog.dart';

/// Pilih panduan yang ingin diputar ulang dari halaman Profil.
Future<void> showTutorialPicker(BuildContext context) async {
  final page = await showModalBottomSheet<TutorialPage>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final tone = AppTone.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panduan Aplikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tone.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Putar ulang panduan singkat untuk tiap halaman.',
                      style: TextStyle(fontSize: 12.5, color: tone.textMuted),
                    ),
                  ],
                ),
              ),
              for (final p in TutorialPage.values)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tone.tintBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconFor(p), color: tone.accent, size: 20),
                  ),
                  title: Text(
                    'Panduan ${p.label}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tone.text,
                    ),
                  ),
                  subtitle: Text(
                    _subtitleFor(p),
                    style: TextStyle(fontSize: 12, color: tone.textMuted),
                  ),
                  trailing: Icon(
                    Icons.play_circle_outline_rounded,
                    color: tone.accent,
                    size: 22,
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(p),
                ),
            ],
          ),
        ),
      );
    },
  );

  if (page != null && context.mounted) {
    await showTutorialDialog(context, page: page);
  }
}

IconData _iconFor(TutorialPage page) => switch (page) {
  TutorialPage.beranda => Icons.home_rounded,
  TutorialPage.riwayat => Icons.history_rounded,
  TutorialPage.profil => Icons.person_rounded,
};

String _subtitleFor(TutorialPage page) => switch (page) {
  TutorialPage.beranda => 'Form prediksi, lokasi, dan tombol hitung.',
  TutorialPage.riwayat => 'Kartu riwayat, filter, dan pencarian.',
  TutorialPage.profil => 'Akun, preferensi wilayah, dan bantuan.',
};
