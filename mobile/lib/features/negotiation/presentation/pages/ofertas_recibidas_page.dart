import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/realtime/socket_events.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';

class OfertasRecibidasPage extends StatefulWidget {
  final String solicitudId;

  const OfertasRecibidasPage({super.key, required this.solicitudId});

  @override
  State<OfertasRecibidasPage> createState() => _OfertasRecibidasPageState();
}

class _OfertasRecibidasPageState extends State<OfertasRecibidasPage> {
  List<Oferta> _ofertas = [];
  bool _cargando = true;

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
    final ofertas = await ServiceLocator.obtenerOfertas(widget.solicitudId);
    if (!mounted) return;
    setState(() {
      _ofertas = ofertas;
      _cargando = false;
    });
  }

  void _onNuevaOferta(dynamic data) {
    if (!mounted) return;
    final conductor = data['conductorNombre'] ?? 'Un conductor';
    final tarifa = data['tarifa'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$conductor respondió con S/ $tarifa')),
    );
    _cargarOfertas();
  }

  void _seleccionar(Oferta oferta) {
    context.push(AppRoutes.conductorSeleccionado, extra: oferta);
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
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _ofertas.isEmpty
              ? const Center(child: Text('Esperando ofertas de mototaxistas...'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ofertas.length,
                  itemBuilder: (context, index) {
                    final oferta = _ofertas[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading:
                            const CircleAvatar(child: Icon(Icons.two_wheeler)),
                        title: Text(oferta.conductor.usuario.nombre),
                        subtitle: Text(
                          '${oferta.conductor.marcaVehiculo} ${oferta.conductor.modeloVehiculo} · Placa ${oferta.conductor.placa}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'S/ ${oferta.tarifa.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
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
    );
  }
}
