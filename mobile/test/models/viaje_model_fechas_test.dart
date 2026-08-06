import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trip_tracking/data/models/viaje_model.dart';

Map<String, dynamic> _json({
  String? creadoEn,
  String? finalizadoEn,
  num? duracion,
}) {
  return {
    'id': 'v-1',
    'pasajero': {
      'id': 'p-1',
      'nombre': 'Ana',
      'correo': 'ana@motolink.com',
      'rol': 'pasajero',
    },
    'conductor': {
      'usuario': {
        'id': 'c-1',
        'nombre': 'Carlos',
        'correo': 'carlos@motolink.com',
        'rol': 'mototaxista',
      },
      'licencia': 'LIC-1',
      'placa': 'ABC-123',
      'marca_vehiculo': 'Honda',
      'modelo_vehiculo': 'Wave',
    },
    'tarifa_final': 10.5,
    'estado': 'finalizado',
    'creado_en': creadoEn,
    'finalizado_en': finalizadoEn,
    'duracion_minutos': duracion,
  };
}

void main() {
  test('parsea las fechas que envía el backend', () {
    final viaje = ViajeModel.fromJson(_json(
      creadoEn: '2026-08-05T14:00:00Z',
      finalizadoEn: '2026-08-05T14:23:00Z',
      duracion: 23,
    ));

    expect(viaje.creadoEn, isNotNull);
    expect(viaje.finalizadoEn, isNotNull);
    expect(viaje.duracionMinutos, 23);
  });

  test('las fechas llegan en hora local, no en UTC', () {
    final viaje = ViajeModel.fromJson(_json(creadoEn: '2026-08-05T14:00:00Z'));
    expect(viaje.creadoEn!.isUtc, isFalse);
  });

  test('un viaje migrado sin fechas no revienta al parsear', () {
    // La base anterior no guardaba fechas: llegan como null.
    final viaje = ViajeModel.fromJson(_json());

    expect(viaje.creadoEn, isNull);
    expect(viaje.finalizadoEn, isNull);
    expect(viaje.duracionMinutos, isNull);
    expect(viaje.tarifaFinal, 10.5);
  });

  test('un viaje en curso todavía no tiene fecha de cierre', () {
    final viaje = ViajeModel.fromJson(_json(creadoEn: '2026-08-05T14:00:00Z'));

    expect(viaje.creadoEn, isNotNull);
    expect(viaje.finalizadoEn, isNull);
    expect(viaje.duracionMinutos, isNull);
  });

  test('una fecha con formato inesperado no tumba la pantalla', () {
    final viaje = ViajeModel.fromJson(_json(creadoEn: 'esto-no-es-fecha'));
    expect(viaje.creadoEn, isNull);
  });
}
