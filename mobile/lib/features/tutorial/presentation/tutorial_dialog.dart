import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../domain/tutorial_page.dart';
import 'tutorial_content.dart';

/// Tampilkan kartu panduan berurutan dengan latar belakang di-blur.
///
/// Pemanggil bertanggung jawab menandai panduan sebagai sudah dilihat setelah
/// dialog ditutup (lihat `TutorialGate`).
Future<void> showTutorialDialog(
  BuildContext context, {
  required TutorialPage page,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Panduan ${page.label}',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _TutorialDialog(page: page);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog({required this.page});

  final TutorialPage page;

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  int _index = 0;

  List<TutorialStep> get _steps => tutorialContent[widget.page]!;

  bool get _isLast => _index == _steps.length - 1;

  void _close() => Navigator.of(context).pop();

  void _next() {
    if (_isLast) {
      _close();
      return;
    }
    setState(() => _index++);
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    final step = _steps[_index];

    return Stack(
      children: [
        // Latar belakang di-blur + digelapkan agar kartu mudah dibaca.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
          ),
        ),
        // Ketuk area luar kartu untuk menutup.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: tone.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: tone.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          step: step,
                          page: widget.page,
                          index: _index,
                          total: _steps.length,
                          onClose: _close,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: tone.text,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.message,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: tone.textSoft,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ProgressDots(count: _steps.length, index: _index),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _close,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Lewati'),
                            ),
                            const Spacer(),
                            if (_index > 0)
                              IconButton(
                                onPressed: _back,
                                tooltip: 'Kembali',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                ),
                              ),
                            const SizedBox(width: 4),
                            FilledButton(
                              onPressed: _next,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(_isLast ? 'Selesai' : 'Lanjut'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.page,
    required this.index,
    required this.total,
    required this.onClose,
  });

  final TutorialStep step;
  final TutorialPage page;
  final int index;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tone.tintBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(step.icon, color: tone.accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panduan ${page.label}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: tone.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Langkah ${index + 1} dari $total',
                style: TextStyle(fontSize: 11.5, color: tone.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          tooltip: 'Tutup',
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, color: tone.textMuted, size: 22),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? tone.accent : tone.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          if (i != count - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
