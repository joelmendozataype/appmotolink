import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/utils/formato_fecha.dart';
import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';
import 'package:mobile/shared/widgets/async_state_view.dart';

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
    SocketService.instance.off(SocketEvents.solicitudCreada, _onSolicitudCreada);
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

  /// El color y el texto dependen de si este conductor ya respondió.
  ///
  /// Antes todas se veían iguales: pulsaba "Ofertar" en una que ya había
  /// respondido y recibía un 409 sin haber podido saberlo antes.
  Widget _botonOfertar(SolicitudViaje solicitud, bool respondida) {
    if (respondida) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.check, size: 16),
        label: const Text('Ofertado'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
        // Sigue pulsable para poder ver el detalle, pero no invita a
        // ofertar de nuevo.
        onPressed: () => _verSolicitud(solicitud),
      );
    }
    final enNegociacion = solicitud.estado == EstadoSolicitud.enNegociacion;
    return FilledButton(
      style: enNegociacion
          // Ámbar: sigue abierta, pero ya hay otros compitiendo.
          ? FilledButton.styleFrom(backgroundColor: Colors.amber.shade800)
          : null,
      onPressed: () => _verSolicitud(solicitud),
      child: const Text('Ofertar'),
    );
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
      body: AsyncStateView<List<SolicitudViaje>>(
        cargando: _cargando,
        error: _error,
        datos: _disponibles,
        estaVacio: (l) => l.isEmpty,
        onReintentar: _cargarSolicitudes,
        mensajeVacio: 'No hay solicitudes disponibles ahora',
        builder: (disponibles) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: disponibles.length,
          itemBuilder: (context, index) {
            final solicitud = disponibles[index];
            final respondida = solicitud.yaRespondida ?? false;
            final enNegociacion =
                solicitud.estado == EstadoSolicitud.enNegociacion;

            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  Icons.location_on,
                  color: respondida ? Colors.grey : null,
                ),
                title: Text('${solicitud.origen} → ${solicitud.destino}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarifa propuesta: S/ ${solicitud.tarifaPropuesta.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          FormatoFecha.legible(solicitud.creadoEn),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (enNegociacion) ...[
                          const SizedBox(width: 8),
                          const _Etiqueta('En negociación'),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: _botonOfertar(solicitud, respondida),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Distintivo pequeño para el estado de la solicitud.
class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
      ),
    );
  }
}
