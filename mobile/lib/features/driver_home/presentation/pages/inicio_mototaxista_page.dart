import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/shared/widgets/aviso_viaje_activo.dart';
import 'package:provider/provider.dart';

class InicioMototaxistaPage extends StatefulWidget {
  const InicioMototaxistaPage({super.key});

  @override
  State<InicioMototaxistaPage> createState() => _InicioMototaxistaPageState();
}

class _InicioMototaxistaPageState extends State<InicioMototaxistaPage> {
  Viaje? _viajeActivo;

  /// Busca si ya hay un viaje en curso al abrir la pantalla.
  ///
  /// Depender solo del aviso en vivo era frágil: si el aviso se perdió
  /// —app cerrada, sin red, o el fallo de salas que arreglamos— el
  /// usuario se quedaba aquí sin forma de volver a su propio viaje.
  Future<void> _buscarViajeActivo() async {
    final usuarioId = context.read<AuthProvider>().usuarioActual?.id;
    if (usuarioId == null) return;
    try {
      final viaje = await ServiceLocator.obtenerViajeActivo(usuarioId);
      if (!mounted) return;
      setState(() => _viajeActivo = viaje);
    } catch (_) {
      // 404 es lo normal: no hay viaje en curso. Cualquier otro fallo
      // tampoco debe estorbar la pantalla de inicio.
      if (mounted) setState(() => _viajeActivo = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _buscarViajeActivo();
    final conductorId = context.read<AuthProvider>().usuarioActual?.id;
    if (conductorId != null) {
      // El pasajero puede asignarle el viaje en cualquier momento mientras
      // el conductor espera aquí: se suscribe a su propio canal para
      // saberlo en tiempo real (paso 7 de la negociación).
      // Solo la sala: del evento ViajeAsignado se encarga EscuchaGlobal,
      // que funciona desde cualquier pantalla. Si ambos navegaran, se
      // apilarían dos pantallas de viaje.
      SocketService.instance.joinRoom(SocketRooms.usuario(conductorId));
    }
    // También se suscribe al canal global de conductores para saber de
    // nuevas solicitudes sin necesidad de estar parado en "Solicitudes
    // disponibles" (paso 3). Sin esto, el conductor solo se enteraba de
    // una solicitud nueva si ya tenía esa pantalla abierta.
    SocketService.instance.joinRoom(SocketRooms.conductores);
    SocketService.instance.onSolicitudCreada(_onSolicitudCreada);
  }

  @override
  void dispose() {
    SocketService.instance.off(SocketEvents.solicitudCreada, _onSolicitudCreada);
    final conductorId = context.read<AuthProvider>().usuarioActual?.id;
    if (conductorId != null) {
      SocketService.instance.leaveRoom(SocketRooms.usuario(conductorId));
    }
    SocketService.instance.leaveRoom(SocketRooms.conductores);
    super.dispose();
  }

  void _onSolicitudCreada(dynamic data) {
    if (!mounted) return;
    // Esta página queda montada debajo mientras el conductor atiende un
    // viaje; sin la guarda, el aviso de nuevas solicitudes se dibujaría
    // encima y taparía el botón "Finalizar viaje".
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final origen = data['origen'] ?? '';
    final destino = data['destino'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nueva solicitud: $origen → $destino'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => context.push(AppRoutes.solicitudesDisponibles),
        ),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    await context.read<AuthProvider>().cerrarSesion();
    if (mounted) context.go(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${usuario?.nombre ?? "Mototaxista"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => context.push(AppRoutes.historialMototaxista),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_viajeActivo != null)
            AvisoViajeActivo(
              titulo: 'Tienes un viaje en curso',
              detalle: 'Pasajero: ${_viajeActivo!.pasajero.nombre}',
              onEntrar: () => context
                  .push(AppRoutes.viajeAsignadoPath(_viajeActivo!.id)),
            ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.two_wheeler,
                          size: 96, color: Colors.teal),
                      const SizedBox(height: 24),
                      Text(
                        'Solicitudes cerca de ti',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.list_alt),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Ver solicitudes disponibles'),
                        ),
                        onPressed: () =>
                            context.push(AppRoutes.solicitudesDisponibles),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
