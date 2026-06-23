import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/features/trip_request/data/models/solicitud_viaje_model.dart';

void main() {
  group('SolicitudViajeModel.fromJson', () {
    // El backend usa snake_case ("tarifa_propuesta"); un bug real de esta
    // app esperaba camelCase y dejaba el campo en null.
    test('lee tarifa_propuesta en snake_case', () {
      final solicitud = SolicitudViajeModel.fromJson({
        'id': 's-1',
        'origen': 'Plaza Pampas',
        'destino': 'Mercado',
        'tarifa_propuesta': 9.0,
        'estado': 'pendiente',
      });

      expect(solicitud.tarifaPropuesta, 9.0);
      expect(solicitud.estado, EstadoSolicitud.pendiente);
    });

    test('reconoce los cinco estados posibles', () {
      for (final estado in [
        'pendiente',
        'enNegociacion',
        'aceptada',
        'cancelada',
        'finalizada',
      ]) {
        final solicitud = SolicitudViajeModel.fromJson({
          'id': 's-1',
          'origen': 'A',
          'destino': 'B',
          'tarifa_propuesta': 5.0,
          'estado': estado,
        });
        expect(solicitud.estado.name, estado);
      }
    });
  });

  group('SolicitudViajeModel.toJson', () {
    test('serializa tarifa_propuesta en snake_case para el backend', () {
      const solicitud = SolicitudViajeModel(
        id: 's-1', origen: 'A', destino: 'B',
        tarifaPropuesta: 7.5, estado: EstadoSolicitud.pendiente,
      );

      final json = solicitud.toJson();

      expect(json['tarifa_propuesta'], 7.5);
      expect(json.containsKey('tarifaPropuesta'), false);
    });
  });
}
