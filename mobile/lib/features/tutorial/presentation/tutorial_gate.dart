import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tutorial_page.dart';
import 'tutorial_dialog.dart';
import 'tutorial_providers.dart';

/// Menampilkan panduan sekali saat halaman pertama kali dibuka.
///
/// Dipasang di route Beranda, Riwayat, dan Profil supaya layar tidak perlu
/// tahu soal penyimpanan status panduan.
class TutorialGate extends ConsumerStatefulWidget {
  const TutorialGate({super.key, required this.page, required this.child});

  final TutorialPage page;
  final Widget child;

  @override
  ConsumerState<TutorialGate> createState() => _TutorialGateState();
}

class _TutorialGateState extends ConsumerState<TutorialGate> {
  /// Antrean agar dua halaman yang terbangun bersamaan tidak menumpuk dialog.
  static Future<void> _tail = Future<void>.value();

  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedule());
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    final next = _tail.then((_) => _maybeShow());
    _tail = next.catchError((_) {});
  }

  Future<void> _maybeShow() async {
    if (!mounted) return;
    final store = ref.read(tutorialStoreProvider);
    if (await store.isSeen(widget.page)) return;
    if (!mounted) return;

    await showTutorialDialog(context, page: widget.page);
    await store.markSeen(widget.page);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
