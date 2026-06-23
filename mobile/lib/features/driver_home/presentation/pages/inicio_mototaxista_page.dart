import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class InicioMototaxistaPage extends StatefulWidget {
  const InicioMototaxistaPage({super.key});

  @override
  State<InicioMototaxistaPage> createState() => _InicioMototaxistaPageState();
}

class _InicioMototaxistaPageState extends State<InicioMototaxistaPage> {
  @override
  void initState() {
    super.initState();
    final conductorId = context.read<AuthProvider>().usuarioActual?.id;
    if (conductorId != null) {
      // El pasajero puede asignarle el viaje en cualquier momento mientras
      // el conductor espera aquí: se suscribe a su propio canal para
      // saberlo en tiempo real (paso 7 de la negociación).
      SocketService.instance.joinRoom(SocketRooms.usuario(conductorId));
      SocketService.instance.onViajeAsignado(_onViajeAsignado);
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
    SocketService.instance.off(SocketEvents.viajeAsignado);
    SocketService.instance.off(SocketEvents.solicitudCreada);
    final conductorId = context.read<AuthProvider>().usuarioActual?.id;
    if (conductorId != null) {
      SocketService.instance.leaveRoom(SocketRooms.usuario(conductorId));
    }
    SocketService.instance.leaveRoom(SocketRooms.conductores);
    super.dispose();
  }

  void _onViajeAsignado(dynamic data) {
    if (!mounted) return;
    final viajeId = data['id'] as String?;
    if (viajeId == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Un pasajero te seleccionó!')),
    );
    context.push(AppRoutes.viajeAsignadoPath(viajeId));
  }

  void _onSolicitudCreada(dynamic data) {
    if (!mounted) return;
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.two_wheeler, size: 96, color: Colors.teal),
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
    );
  }
}
