import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/shared/widgets/mapa_viaje.dart';

Position _posicion(double lat, double lon) => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime(2026, 8, 6),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

Widget _envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

void main() {
  testWidgets('sin ubicación todavía, avisa en vez de mostrar el mapa vacío',
      (tester) async {
    await tester.pumpWidget(_envolver(const MapaViaje(posicion: null)));

    expect(find.text('Buscando tu ubicación…'), findsOneWidget);
    // El mapa se dibuja igual, centrado en Pampas, para no dejar la
    // pantalla en blanco mientras responde el GPS.
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('con ubicación, dibuja el marcador y oculta el aviso',
      (tester) async {
    await tester.pumpWidget(_envolver(
      MapaViaje(posicion: _posicion(-12.3987, -74.8684)),
    ));

    expect(find.text('Buscando tu ubicación…'), findsNothing);
    expect(find.byType(MarkerLayer), findsOneWidget);
  });

  testWidgets('el recorrido se dibuja solo con dos puntos o más',
      (tester) async {
    await tester.pumpWidget(_envolver(MapaViaje(
      posicion: _posicion(-12.3987, -74.8684),
      recorrido: [_posicion(-12.3987, -74.8684)],
    )));
    expect(find.byType(PolylineLayer), findsNothing);

    await tester.pumpWidget(_envolver(MapaViaje(
      posicion: _posicion(-12.3990, -74.8690),
      recorrido: [
        _posicion(-12.3987, -74.8684),
        _posicion(-12.3990, -74.8690),
      ],
    )));
    expect(find.byType(PolylineLayer), findsOneWidget);
  });

  testWidgets('muestra la leyenda que se le pasa', (tester) async {
    await tester.pumpWidget(_envolver(MapaViaje(
      posicion: _posicion(-12.3987, -74.8684),
      leyenda: 'Recorrido: 1.2 km',
    )));

    expect(find.text('Recorrido: 1.2 km'), findsOneWidget);
  });

  testWidgets('acredita a OpenStreetMap, como exige su licencia',
      (tester) async {
    await tester.pumpWidget(_envolver(
      MapaViaje(posicion: _posicion(-12.3987, -74.8684)),
    ));

    expect(find.byType(RichAttributionWidget), findsOneWidget);
  });
}
