import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('MOTOLINK arranca y muestra el splash', (tester) async {
    await tester.pumpWidget(const MotolinkApp());

    expect(find.text('MOTOLINK'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}
