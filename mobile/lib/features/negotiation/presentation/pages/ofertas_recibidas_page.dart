import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';
import 'package:mobile/shared/widgets/async_state_view.dart';

class OfertasRecibidasPage extends StatefulWidget {
  final String solicitudId;

  const OfertasRecibidasPage({super.key, required this.solicitudId});

  @override
  State<OfertasRecibidasPage> createState() => _OfertasRecibidasPageState();
}

class _OfertasRecibidasPageState extends State<OfertasRecibidasPage> {
  List<Oferta> _ofertas = [];
  bool _cargando = true;
  bool _cancelando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarOfertas();
    // 5. El pasajero se suscribe al canal de su propia solicitud para
    // recibir ofertas y contraofertas en tiempo real.
    SocketService.instance.joinRoom(SocketRooms.solicitud(widget.solicitudId));
    SocketService.instance.onOfertaCreada(_onNuevaOferta);
    SocketService.instance.onContraOfertaCreada(_onNuevaOferta);
  }

  @override
  void dispose() {
    SocketService.instance.off(SocketEvents.ofertaCreada);
    SocketService.instance.off(SocketEvents.contraOfertaCreada);
    SocketService.instance.leaveRoom(SocketRooms.solicitud(widget.solicitudId));
    super.dispose();
  }

  Future<void> _cargarOfertas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ofertas = await ServiceLocator.obtenerOfertas(widget.solicitudId);
      if (!mounted) return;
      setState(() {
        _ofertas = ofertas;
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

  void _onNuevaOferta(dynamic data) {
    if (!mounted) return;
    // La lista se refresca siempre, pero el aviso solo se muestra si esta
    // pantalla está al frente: si el pasajero ya avanzó a la selección o
    // al viaje, el SnackBar se dibujaría sobre esas pantallas.
    if (ModalRoute.of(context)?.isCurrent == true) {
      final conductor = data['conductorNombre'] ?? 'Un conductor';
      final tarifa = data['tarifa'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$conductor respondió con S/ $tarifa')),
      );
    }
    _cargarOfertas();
  }

  void _seleccionar(Oferta oferta) {
    context.push(AppRoutes.conductorSeleccionado, extra: oferta);
  }

  /// El pasajero se echa atrás mientras espera ofertas. Solo funciona
  /// antes de elegir conductor: una vez hay viaje, lo que se cancela es
  /// el viaje, y el backend responde 409 si se intenta aquí.
  Future<void> _cancelarSolicitud() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Cancelar la solicitud?'),
        content: const Text(
          'Dejarás de recibir ofertas de los mototaxistas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('No, seguir esperando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _cancelando = true);
    try {
      await ServiceLocator.cancelarSolicitudViaje(widget.solicitudId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud cancelada')),
      );
      context.go(AppRoutes.inicioPasajero);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas recibidas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarOfertas,
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            tooltip: 'Cancelar solicitud',
            onPressed: _cancelando ? null : _cancelarSolicitud,
          ),
        ],
      ),
      body: AsyncStateView<List<Oferta>>(
        cargando: _cargando,
        error: _error,
        datos: _ofertas,
        estaVacio: (l) => l.isEmpty,
        onReintentar: _cargarOfertas,
        mensajeVacio: 'Esperando ofertas de mototaxistas...',
        builder: (ofertas) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ofertas.length,
          itemBuilder: (context, index) {
            final oferta = ofertas[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.two_wheeler),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(oferta.conductor.usuario.nombre),
                              Text(
                                '${oferta.conductor.marcaVehiculo} ${oferta.conductor.modeloVehiculo} · Placa ${oferta.conductor.placa}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'S/ ${oferta.tarifa.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _seleccionar(oferta),
                      child: const Text('Seleccionar'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
