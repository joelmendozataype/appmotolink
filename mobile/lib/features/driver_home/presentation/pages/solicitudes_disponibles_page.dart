import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';
import 'package:mobile/shared/widgets/error_retry_view.dart';

class SolicitudesDisponiblesPage extends StatefulWidget {
  const SolicitudesDisponiblesPage({super.key});

  @override
  State<SolicitudesDisponiblesPage> createState() =>
      _SolicitudesDisponiblesPageState();
}

class _SolicitudesDisponiblesPageState
    extends State<SolicitudesDisponiblesPage> {
  List<SolicitudViaje> _disponibles = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
    // 3. El conductor se suscribe al canal global de solicitudes nuevas.
    SocketService.instance.joinRoom(SocketRooms.conductores);
    SocketService.instance.onSolicitudCreada(_onSolicitudCreada);
  }

  @override
  void dispose() {
    SocketService.instance.off(SocketEvents.solicitudCreada);
    SocketService.instance.leaveRoom(SocketRooms.conductores);
    super.dispose();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final disponibles = await ServiceLocator.obtenerSolicitudesDisponibles();
      if (!mounted) return;
      setState(() {
        _disponibles = disponibles;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mensajeDeError(e);
        _cargando = false;
      });
    }
  }

  void _onSolicitudCreada(dynamic data) {
    if (!mounted) return;
    final origen = data['origen'] ?? '';
    final destino = data['destino'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nueva solicitud: $origen → $destino')),
    );
    _cargarSolicitudes();
  }

  void _verSolicitud(SolicitudViaje solicitud) {
    context.push(AppRoutes.contraofertaPath(solicitud.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSolicitudes,
          ),
        ],
      ),
      body: _error != null
          ? ErrorRetryView(mensaje: _error!, onRetry: _cargarSolicitudes)
          : _cargando
          ? const Center(child: CircularProgressIndicator())
          : _disponibles.isEmpty
              ? const Center(child: Text('No hay solicitudes disponibles ahora'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _disponibles.length,
                  itemBuilder: (context, index) {
                    final solicitud = _disponibles[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(Icons.location_on),
                        title:
                            Text('${solicitud.origen} → ${solicitud.destino}'),
                        subtitle: Text(
                          'Tarifa propuesta: S/ ${solicitud.tarifaPropuesta.toStringAsFixed(2)}',
                        ),
                        trailing: FilledButton(
                          onPressed: () => _verSolicitud(solicitud),
                          child: const Text('Ofertar'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
