import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumahpoint/main.dart';

void main() {
  testWidgets('Login screen renders actions', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();
    expect(find.text('Selamat Datang 👋'), findsOneWidget);
    expect(find.text('Lupa password?'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsOneWidget);
  });
}
