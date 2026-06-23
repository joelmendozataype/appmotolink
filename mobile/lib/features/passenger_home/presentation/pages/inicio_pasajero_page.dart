import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class InicioPasajeroPage extends StatefulWidget {
  const InicioPasajeroPage({super.key});

  @override
  State<InicioPasajeroPage> createState() => _InicioPasajeroPageState();
}

class _InicioPasajeroPageState extends State<InicioPasajeroPage> {
  @override
  void initState() {
    super.initState();
    final pasajeroId = context.read<AuthProvider>().usuarioActual?.id;
    if (pasajeroId != null) {
      // El conductor puede aceptar/contraofertar mientras el pasajero está
      // en cualquier pantalla (ej. aquí en inicio); se suscribe a su propio
      // canal para enterarse en tiempo real sin depender de estar parado
      // en "Ofertas recibidas".
      SocketService.instance.joinRoom(SocketRooms.usuario(pasajeroId));
      SocketService.instance.onOfertaCreada(_onOferta);
      SocketService.instance.onContraOfertaCreada(_onOferta);
    }
  }

  @override
  void dispose() {
    SocketService.instance.off(SocketEvents.ofertaCreada);
    SocketService.instance.off(SocketEvents.contraOfertaCreada);
    final pasajeroId = context.read<AuthProvider>().usuarioActual?.id;
    if (pasajeroId != null) {
      SocketService.instance.leaveRoom(SocketRooms.usuario(pasajeroId));
    }
    super.dispose();
  }

  void _onOferta(dynamic data) {
    if (!mounted) return;
    final solicitudId = data['solicitudId'] as String?;
    if (solicitudId == null) return;
    final conductor = data['conductorNombre'] ?? 'Un conductor';
    final tarifa = data['tarifa'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$conductor respondió con S/ $tarifa'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () =>
              context.push(AppRoutes.ofertasRecibidasPath(solicitudId)),
        ),
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await context.read<AuthProvider>().cerrarSesion();
    if (context.mounted) context.go(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${usuario?.nombre ?? "Pasajero"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => context.push(AppRoutes.historialPasajero),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
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
                const Icon(Icons.electric_moped, size: 96, color: Colors.teal),
                const SizedBox(height: 24),
                Text(
                  '¿A dónde quieres ir?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.add_location_alt),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Solicitar un viaje'),
                  ),
                  onPressed: () => context.push(AppRoutes.crearSolicitud),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
