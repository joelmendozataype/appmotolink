import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/enums/estado_oferta.dart';
import 'package:mobile/core/enums/tipo_oferta.dart';
import 'package:mobile/features/negotiation/data/models/oferta_model.dart';

void main() {
  group('OfertaModel.fromJson', () {
    // DRF serializa DecimalField como string por defecto ("9.00"); un bug
    // real de esta app crasheaba aquí con `(json['tarifa'] as num)` antes
    // de fijar COERCE_DECIMAL_TO_STRING=False en el backend. Esta prueba
    // documenta el contrato esperado: el backend ya entrega un número.
    test('parsea tarifa como num, no como string', () {
      final json = {
        'id': 'of-1',
        'conductor': {
          'usuario': {
            'id': 'u-1',
            'nombre': 'Carlos',
            'correo': 'carlos@motolink.com',
            'rol': 'mototaxista',
          },
          'licencia': 'LIC-1',
          'placa': 'ABC-123',
          'marca_vehiculo': 'Honda',
          'modelo_vehiculo': 'Wave',
        },
        'tarifa': 9.5,
        'tipo': 'contraoferta',
        'estado': 'pendiente',
        'fecha': '2026-06-22T10:00:00Z',
      };

      final oferta = OfertaModel.fromJson(json);

      expect(oferta.tarifa, 9.5);
      expect(oferta.tipo, TipoOferta.contraoferta);
      expect(oferta.estado, EstadoOferta.pendiente);
      expect(oferta.conductor.usuario.nombre, 'Carlos');
    });

    test('parsea tarifa entera sin decimales (num int)', () {
      final json = {
        'id': 'of-2',
        'conductor': {
          'usuario': {
            'id': 'u-2',
            'nombre': 'Luis',
            'correo': 'luis@motolink.com',
            'rol': 'mototaxista',
          },
          'licencia': 'LIC-2',
          'placa': 'XYZ-999',
          'marca_vehiculo': 'Yamaha',
          'modelo_vehiculo': 'Crypton',
        },
        'tarifa': 10,
        'tipo': 'aceptacion',
        'estado': 'aceptada',
        'fecha': '2026-06-22T10:05:00Z',
      };

      final oferta = OfertaModel.fromJson(json);

      expect(oferta.tarifa, 10.0);
      expect(oferta.tipo, TipoOferta.aceptacion);
    });
  });
}
