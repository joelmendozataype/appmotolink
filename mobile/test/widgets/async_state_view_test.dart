import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/widgets/async_state_view.dart';

void main() {
  Widget envolver(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('muestra el spinner mientras cargando es true', (tester) async {
    await tester.pumpWidget(envolver(
      AsyncStateView<List<int>>(
        cargando: true,
        error: null,
        datos: const [],
        estaVacio: (l) => l.isEmpty,
        onReintentar: () {},
        mensajeVacio: 'vacío',
        builder: (datos) => const Text('datos'),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('datos'), findsNothing);
  });

  testWidgets('muestra ErrorRetryView con el mensaje cuando hay error',
      (tester) async {
    await tester.pumpWidget(envolver(
      AsyncStateView<List<int>>(
        cargando: false,
        error: 'Algo salió mal',
        datos: const [],
        estaVacio: (l) => l.isEmpty,
        onReintentar: () {},
        mensajeVacio: 'vacío',
        builder: (datos) => const Text('datos'),
      ),
    ));

    expect(find.text('Algo salió mal'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('llama a onReintentar al tocar el botón de error',
      (tester) async {
    var reintentos = 0;
    await tester.pumpWidget(envolver(
      AsyncStateView<List<int>>(
        cargando: false,
        error: 'Error de red',
        datos: const [],
        estaVacio: (l) => l.isEmpty,
        onReintentar: () => reintentos++,
        mensajeVacio: 'vacío',
        builder: (datos) => const Text('datos'),
      ),
    ));

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(reintentos, 1);
  });

  testWidgets('muestra el mensaje vacío cuando los datos están vacíos',
      (tester) async {
    await tester.pumpWidget(envolver(
      AsyncStateView<List<int>>(
        cargando: false,
        error: null,
        datos: const [],
        estaVacio: (l) => l.isEmpty,
        onReintentar: () {},
        mensajeVacio: 'No hay nada aquí',
        builder: (datos) => const Text('datos'),
      ),
    ));

    expect(find.text('No hay nada aquí'), findsOneWidget);
  });

  testWidgets('llama al builder cuando hay datos', (tester) async {
    await tester.pumpWidget(envolver(
      AsyncStateView<List<int>>(
        cargando: false,
        error: null,
        datos: const [1, 2, 3],
        estaVacio: (l) => l.isEmpty,
        onReintentar: () {},
        mensajeVacio: 'vacío',
        builder: (datos) => Text('${datos.length} elementos'),
      ),
    ));

    expect(find.text('3 elementos'), findsOneWidget);
  });
}
