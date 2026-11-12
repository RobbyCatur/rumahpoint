import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tutorial_store.dart';

/// Satu-satunya tempat membuat [TutorialStore] untuk UI.
final tutorialStoreProvider = Provider<TutorialStore>((ref) {
  return TutorialStore();
});
