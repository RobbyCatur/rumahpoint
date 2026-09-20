import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumahpoint/main.dart';

void main() {
  testWidgets('Form screen renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RumahPointApp()));
    await tester.pumpAndSettle();
    expect(find.text('Rumah Point - Prediksi Harga'), findsOneWidget);
    expect(find.text('Hitung Estimasi Harga'), findsOneWidget);
  });
}
