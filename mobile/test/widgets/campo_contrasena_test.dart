import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/widgets/campo_contrasena.dart';

Widget _envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

void main() {
  testWidgets('arranca oculta', (tester) async {
    await tester.pumpWidget(_envolver(
      CampoContrasena(controller: TextEditingController(text: 'secreta')),
    ));

    final campo = tester.widget<TextField>(find.byType(TextField));
    expect(campo.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('el botón la revela y la vuelve a ocultar', (tester) async {
    await tester.pumpWidget(_envolver(
      CampoContrasena(controller: TextEditingController(text: 'secreta')),
    ));

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse);
    expect(find.byIcon(Icons.visibility), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue);
  });

  testWidgets('muestra el texto de ayuda cuando se le pasa', (tester) async {
    await tester.pumpWidget(_envolver(CampoContrasena(
      controller: TextEditingController(),
      ayuda: 'Mínimo 8 caracteres.',
    )));

    expect(find.text('Mínimo 8 caracteres.'), findsOneWidget);
  });

  testWidgets('aplica el validador que recibe', (tester) async {
    final clave = GlobalKey<FormState>();
    await tester.pumpWidget(_envolver(Form(
      key: clave,
      child: CampoContrasena(
        controller: TextEditingController(text: 'corta'),
        validator: (v) => (v!.length < 8) ? 'Muy corta' : null,
      ),
    )));

    expect(clave.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Muy corta'), findsOneWidget);
  });
}
