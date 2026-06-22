import 'package:flutter/foundation.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Servicio único (singleton) que envuelve el cliente Socket.IO de la app.
///
/// Maneja conexión, reconexión automática y suscripción a salas (rooms) y
/// a los 5 eventos de negociación de MOTOLINK.
class SocketService {
  SocketService._internal();

  static final SocketService instance = SocketService._internal();

  io.Socket? _socket;

  /// Notifica a la UI si el socket está conectado (para mostrar un banner
  /// de "sin conexión" o similar).
  final ValueNotifier<bool> conectado = ValueNotifier(false);

  bool get estaConectado => _socket?.connected ?? false;

  void connect([String baseUrl = 'http://10.0.2.2:8000']) {
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

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    conectado.value = false;
  }

  /// Se suscribe a un canal del servidor: `conductores`, `solicitud_<id>`
  /// o `usuario_<id>`.
  void joinRoom(String room) => _socket?.emit('join_room', {'room': room});

  void leaveRoom(String room) => _socket?.emit('leave_room', {'room': room});

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) => _socket?.off(event);

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
}
