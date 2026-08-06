import 'package:flutter/foundation.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Servicio único (singleton) que envuelve el cliente Socket.IO de la app.
///
/// Maneja conexión, reconexión automática y suscripción a salas (rooms) y
/// a los eventos de negociación de MOTOLINK.
///
/// Las suscripciones se llevan por manejador y las salas por conteo de
/// referencias. Antes no era así, y provocaba un fallo difícil de ver:
/// `off(evento)` borraba los manejadores de TODAS las pantallas, y
/// `leaveRoom` abandonaba la sala aunque otra pantalla montada siguiera
/// necesitándola. Como al ofertar la app hace `go()` —que reemplaza la
/// pila— la pantalla nueva se suscribía antes de que la vieja se
/// destruyera, y el `dispose` de la vieja borraba lo que acababa de
/// registrar la nueva. El conductor quedaba fuera de su propia sala y no
/// se enteraba de que un pasajero lo había seleccionado.
class SocketService {
  SocketService._internal();

  static final SocketService instance = SocketService._internal();

  io.Socket? _socket;

  /// Cuántas pantallas vivas necesitan cada sala. Solo se abandona cuando
  /// llega a cero.
  final Map<String, int> _salas = {};

  /// Manejadores vivos por evento, para poder quitar solo el propio.
  final Map<String, List<Function(dynamic)>> _manejadores = {};

  /// Notifica a la UI si el socket está conectado (para mostrar un banner
  /// de "sin conexión" o similar).
  final ValueNotifier<bool> conectado = ValueNotifier(false);

  bool get estaConectado => _socket?.connected ?? false;

  @visibleForTesting
  Map<String, int> get salasActivas => Map.unmodifiable(_salas);

  @visibleForTesting
  List<Function(dynamic)> manejadoresDe(String event) =>
      List.unmodifiable(_manejadores[event] ?? const []);

  void connect([String baseUrl = 'http://localhost:8000']) {
    if (_socket != null) return;

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        conectado.value = true;
        debugPrint('[SocketService] conectado: ${_socket!.id}');
        _reingresarSalas();
      })
      ..onDisconnect((reason) {
        conectado.value = false;
        debugPrint('[SocketService] desconectado: $reason');
      })
      ..onReconnectAttempt((intento) {
        debugPrint('[SocketService] intento de reconexión #$intento');
      })
      ..onReconnect((_) {
        debugPrint('[SocketService] reconectado correctamente');
        conectado.value = true;
        // El servidor no recuerda las salas de una sesión anterior: tras
        // reconectar hay que volver a entrar o los avisos dejan de llegar
        // en silencio.
        _reingresarSalas();
      })
      ..onReconnectError((error) {
        debugPrint('[SocketService] error al reconectar: $error');
      })
      ..onConnectError((error) {
        debugPrint('[SocketService] error de conexión: $error');
      })
      ..onError((error) {
        debugPrint('[SocketService] error: $error');
      });
  }

  void _reingresarSalas() {
    for (final sala in _salas.keys) {
      _socket?.emit('join_room', {'room': sala});
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _salas.clear();
    _manejadores.clear();
    conectado.value = false;
  }

  /// Se suscribe a un canal del servidor: `conductores`, `solicitud_<id>`
  /// o `usuario_<id>`.
  ///
  /// Si dos pantallas piden la misma sala, solo se entra una vez y hace
  /// falta que ambas la suelten para abandonarla.
  void joinRoom(String room) {
    final previas = _salas[room] ?? 0;
    _salas[room] = previas + 1;
    if (previas == 0) {
      _socket?.emit('join_room', {'room': room});
    }
  }

  void leaveRoom(String room) {
    final previas = _salas[room];
    if (previas == null) return;
    if (previas <= 1) {
      _salas.remove(room);
      _socket?.emit('leave_room', {'room': room});
    } else {
      _salas[room] = previas - 1;
    }
  }

  void on(String event, void Function(dynamic data) handler) {
    _manejadores.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  /// Quita un manejador concreto.
  ///
  /// El manejador es obligatorio a propósito: sin él se borraban también
  /// las suscripciones de otras pantallas.
  void off(String event, void Function(dynamic data) handler) {
    _manejadores[event]?.remove(handler);
    if (_manejadores[event]?.isEmpty ?? false) {
      _manejadores.remove(event);
    }
    _socket?.off(event, handler);
  }

  // ---- Listeners tipados por evento de negociación ----

  void onSolicitudCreada(void Function(dynamic data) handler) =>
      on(SocketEvents.solicitudCreada, handler);

  void onOfertaCreada(void Function(dynamic data) handler) =>
      on(SocketEvents.ofertaCreada, handler);

  void onContraOfertaCreada(void Function(dynamic data) handler) =>
      on(SocketEvents.contraOfertaCreada, handler);

  void onOfertaAceptada(void Function(dynamic data) handler) =>
      on(SocketEvents.ofertaAceptada, handler);

  void onViajeAsignado(void Function(dynamic data) handler) =>
      on(SocketEvents.viajeAsignado, handler);

  void onViajeCancelado(void Function(dynamic data) handler) =>
      on(SocketEvents.viajeCancelado, handler);

  void onSolicitudCancelada(void Function(dynamic data) handler) =>
      on(SocketEvents.solicitudCancelada, handler);
}
