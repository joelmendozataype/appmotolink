import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/formato_fecha.dart';

void main() {
  group('legible', () {
    test('hoy muestra la hora', () {
      final ahora = DateTime.now();
      final fecha = DateTime(ahora.year, ahora.month, ahora.day, 14, 30);
      expect(FormatoFecha.legible(fecha), 'Hoy 14:30');
    });

    test('ayer se nombra como tal', () {
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      final fecha = DateTime(ayer.year, ayer.month, ayer.day, 9, 5);
      expect(FormatoFecha.legible(fecha), 'Ayer 09:05');
    });

    test('otro año incluye el año y omite la hora', () {
      expect(FormatoFecha.legible(DateTime(2020, 12, 3, 18, 42)),
          '3 dic 2020');
    });

    test('sin fecha lo dice en vez de inventarla', () {
      // Los viajes migrados desde la base anterior no tienen fecha.
      expect(FormatoFecha.legible(null), 'Fecha no registrada');
    });
  });

  group('duracion', () {
    test('menos de una hora va en minutos', () {
      expect(FormatoFecha.duracion(8), '8 min');
      expect(FormatoFecha.duracion(59), '59 min');
    });

    test('una hora justa no arrastra minutos', () {
      expect(FormatoFecha.duracion(60), '1 h');
      expect(FormatoFecha.duracion(120), '2 h');
    });

    test('mas de una hora combina ambos', () {
      expect(FormatoFecha.duracion(85), '1 h 25 min');
    });

    test('devuelve null cuando no se puede calcular', () {
      expect(FormatoFecha.duracion(null), isNull);
      expect(FormatoFecha.duracion(-5), isNull);
    });
  });
}
