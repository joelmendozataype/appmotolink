import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:mobile/core/realtime/socket_service.dart';

/// Estos tests cubren un fallo real: el conductor ofertaba, volvía al
/// inicio y ya no se enteraba de que un pasajero lo había seleccionado.
///
/// La causa estaba aquí. Al ofertar, la app hace `go()`, que reemplaza la
/// pila: la pantalla nueva se suscribía ANTES de que la vieja se
/// destruyera, y el `dispose` de la vieja —con el `off(evento)` de
/// entonces, que borraba todos los manejadores— se llevaba por delante lo
/// que la nueva acababa de registrar, además de abandonar su sala.
void main() {
  late SocketService servicio;

  setUp(() {
    servicio = SocketService.instance;
    // Sin conectar: solo se comprueba la contabilidad interna, que es
    // donde estaba el fallo.
    for (final sala in servicio.salasActivas.keys.toList()) {
      var restantes = servicio.salasActivas[sala] ?? 0;
      while (restantes-- > 0) {
        servicio.leaveRoom(sala);
      }
    }
  });

  group('salas', () {
    test('dos pantallas piden la misma sala y solo una la suelta', () {
      servicio.joinRoom('usuario_1');
      servicio.joinRoom('usuario_1');
      expect(servicio.salasActivas['usuario_1'], 2);

      servicio.leaveRoom('usuario_1');
      // Sigue dentro: la otra pantalla continúa viva.
      expect(servicio.salasActivas['usuario_1'], 1);

      servicio.leaveRoom('usuario_1');
      expect(servicio.salasActivas.containsKey('usuario_1'), isFalse);
    });

    test('el relevo entre pantallas no deja al usuario fuera de su sala', () {
      // Orden real al hacer go(): entra la nueva, luego se destruye la vieja.
      servicio.joinRoom('usuario_1'); // pantalla vieja
      servicio.joinRoom('usuario_1'); // pantalla nueva
      servicio.leaveRoom('usuario_1'); // dispose de la vieja

      expect(servicio.salasActivas['usuario_1'], 1,
          reason: 'la pantalla nueva debe seguir dentro de la sala');
    });

    test('soltar una sala en la que no se estaba no rompe la cuenta', () {
      servicio.leaveRoom('sala_que_no_existe');
      expect(servicio.salasActivas.containsKey('sala_que_no_existe'), isFalse);
    });
  });

  group('manejadores', () {
    test('quitar el propio no borra el de otra pantalla', () {
      final recibidos = <String>[];
      void deLaVieja(dynamic _) => recibidos.add('vieja');
      void deLaNueva(dynamic _) => recibidos.add('nueva');

      servicio.on(SocketEvents.viajeAsignado, deLaVieja);
      servicio.on(SocketEvents.viajeAsignado, deLaNueva);
      servicio.off(SocketEvents.viajeAsignado, deLaVieja);

      // El de la pantalla nueva tiene que seguir registrado: es el que
      // lleva al conductor a la pantalla del viaje.
      expect(
        servicio.manejadoresDe(SocketEvents.viajeAsignado),
        contains(deLaNueva),
      );
      expect(
        servicio.manejadoresDe(SocketEvents.viajeAsignado),
        isNot(contains(deLaVieja)),
      );
    });
  });
}
