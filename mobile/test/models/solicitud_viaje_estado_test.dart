import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/features/trip_request/data/models/solicitud_viaje_model.dart';

Map<String, dynamic> _json({
  String estado = 'pendiente',
  String? creadoEn,
  bool? yaRespondida,
}) {
  return {
    'id': 's-1',
    'pasajero': 'p-1',
    'origen': 'Pampas',
    'destino': 'Acraquia',
    'tarifa_propuesta': 9.0,
    'estado': estado,
    'creado_en': creadoEn,
    'ya_respondida': yaRespondida,
  };
}

void main() {
  test('parsea la fecha en que se hizo la solicitud', () {
    final s = SolicitudViajeModel.fromJson(
      _json(creadoEn: '2026-08-06T15:30:00Z'),
    );
    expect(s.creadoEn, isNotNull);
    expect(s.creadoEn!.isUtc, isFalse, reason: 'debe venir en hora local');
  });

  test('una solicitud migrada sin fecha no revienta', () {
    expect(SolicitudViajeModel.fromJson(_json()).creadoEn, isNull);
  });

  test('distingue si el conductor ya respondió', () {
    expect(
      SolicitudViajeModel.fromJson(_json(yaRespondida: true)).yaRespondida,
      isTrue,
    );
    expect(
      SolicitudViajeModel.fromJson(_json(yaRespondida: false)).yaRespondida,
      isFalse,
    );
  });

  test('null no es lo mismo que "no ha respondido"', () {
    // El backend solo envía el dato a los mototaxistas; para un pasajero
    // la pregunta no aplica.
    expect(SolicitudViajeModel.fromJson(_json()).yaRespondida, isNull);
  });

  test('reconoce el estado en negociación, que pinta el botón distinto', () {
    final s = SolicitudViajeModel.fromJson(_json(estado: 'enNegociacion'));
    expect(s.estado, EstadoSolicitud.enNegociacion);
  });
}
