import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('MOTOLINK arranca y muestra el splash', (tester) async {
    await tester.pumpWidget(const MotolinkApp());

    // Antes se buscaba el texto 'MOTOLINK'. Ahora el nombre va dentro del
    // logo, así que se comprueba que se dibuje esa imagen.
    final logo = tester.widget<Image>(find.byType(Image).first);
    expect((logo.image as AssetImage).assetName, 'assets/logo_motolink.png');

    await tester.pump(const Duration(seconds: 3));
  });
}
