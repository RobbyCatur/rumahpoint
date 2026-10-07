import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rumahpoint/main.dart';
import 'package:rumahpoint/router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Beranda renders banner, form, and bottom nav',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();

    router.go('/beranda');
    await tester.pumpAndSettle();

    expect(find.text('Kalkulasi Nilai Pasar Properti'), findsOneWidget);
    expect(find.text('Hitung Valuasi Sekarang'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
