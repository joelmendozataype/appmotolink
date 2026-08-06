import 'package:flutter/material.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';

/// Escucha los avisos que no pertenecen a ninguna pantalla concreta.
///
/// Que a un conductor le asignen un viaje puede pasar esté donde esté:
/// mirando solicitudes, en su historial o en el inicio. Antes solo lo
/// escuchaba la pantalla de inicio, así que desde cualquier otra el aviso
/// se perdía —y el evento OfertaAceptada, que el backend emitía desde el
/// principio, no lo escuchaba nadie en absoluto.
///
/// Al vivir por encima del router, funciona en toda la app y sobrevive a
/// la navegación.
class EscuchaGlobal {
  EscuchaGlobal._();

  static final EscuchaGlobal instance = EscuchaGlobal._();

  /// Para poder mostrar avisos sin un BuildContext de pantalla.
  static final mensajeria = GlobalKey<ScaffoldMessengerState>();

  AuthProvider? _auth;
  bool _activa = false;

  void activar(AuthProvider auth) {
    _auth = auth;
    if (_activa) return;
    _activa = true;
    SocketService.instance.onViajeAsignado(_onViajeAsignado);
    SocketService.instance.onOfertaAceptada(_onOfertaAceptada);
    SocketService.instance.onViajeFinalizado(_onViajeFinalizado);
  }

  String? get _usuarioId => _auth?.usuarioActual?.id;

  void _avisar(String texto) {
    mensajeria.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(texto), duration: const Duration(seconds: 5)),
      );
  }

  /// El pasajero eligió a este conductor. Llega antes que ViajeAsignado y
  /// sirve para avisar cuanto antes.
  void _onOfertaAceptada(dynamic data) {
    if (data is! Map) return;
    if (data['conductorId']?.toString() != _usuarioId) return;
    _avisar('¡Un pasajero aceptó tu oferta!');
  }

  /// El viaje se cerró: quien no pulsó el botón se quedaba en la pantalla
  /// del viaje con los botones vivos, y al pulsarlos recibía un 409
  /// "Este viaje ya fue cerrado" sin entender por qué.
  void _onViajeFinalizado(dynamic data) {
    if (data is! Map) return;
    final usuarioId = _usuarioId;
    final viajeId = data['id']?.toString();
    if (usuarioId == null || viajeId == null) return;

    final soyPasajero = data['pasajeroId']?.toString() == usuarioId;
    final soyConductor = data['conductorId']?.toString() == usuarioId;
    if (!soyPasajero && !soyConductor) return;

    _avisar('El viaje terminó.');
    // El pasajero pasa a calificar; el conductor vuelve a su inicio a
    // esperar el siguiente.
    AppRouter.router.go(
      soyPasajero
          ? AppRoutes.calificacionPath(viajeId)
          : AppRoutes.inicioMototaxista,
    );
  }

  /// El viaje ya existe: se avisa a ambas partes y se lleva a cada una a
  /// su pantalla, que no es la misma.
  void _onViajeAsignado(dynamic data) {
    if (data is! Map) return;
    final usuarioId = _usuarioId;
    if (usuarioId == null) return;

    final viajeId = data['id']?.toString();
    if (viajeId == null) return;

    final soyConductor = data['conductorId']?.toString() == usuarioId;
    final soyPasajero = data['pasajeroId']?.toString() == usuarioId;
    if (!soyConductor && !soyPasajero) return;

    _avisar(
      soyConductor
          ? '¡Viaje asignado! Ve a recoger a tu pasajero.'
          : '¡Viaje confirmado! Tu mototaxista va en camino.',
    );

    final rol = _auth?.usuarioActual?.rol;
    final destino = rol == RolUsuario.mototaxista
        ? AppRoutes.viajeAsignadoPath(viajeId)
        : AppRoutes.viajeEnCursoPath(viajeId);

    // Si ya está en esa pantalla, no se apila otra igual.
    if (AppRouter.router.state.matchedLocation == destino) return;
    AppRouter.router.push(destino);
  }
}
