import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';

class ViajeEnCursoPage extends StatefulWidget {
  final String viajeId;

  const ViajeEnCursoPage({super.key, required this.viajeId});

  @override
  State<ViajeEnCursoPage> createState() => _ViajeEnCursoPageState();
}

class _ViajeEnCursoPageState extends State<ViajeEnCursoPage> {
  Viaje? _viaje;
  bool _finalizando = false;

  @override
  void initState() {
    super.initState();
    _cargarViaje();
  }

  Future<void> _cargarViaje() async {
    final viaje = await ServiceLocator.obtenerViajePorId(widget.viajeId);
    if (!mounted) return;
    setState(() => _viaje = viaje);
  }

  Future<void> _finalizarViaje() async {
    setState(() => _finalizando = true);
    try {
      await ServiceLocator.finalizarViaje(widget.viajeId);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.calificacionPath(widget.viajeId));
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viaje = _viaje;
    return Scaffold(
      appBar: AppBar(title: const Text('Viaje en curso')),
      body: viaje == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.teal.shade50,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 80, color: Colors.teal),
                          SizedBox(height: 8),
                          Text('Mapa en vivo (simulado)'),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        leading:
                            const CircleAvatar(child: Icon(Icons.two_wheeler)),
                        title: Text(viaje.conductor.usuario.nombre),
                        subtitle: Text(
                          '${viaje.conductor.marcaVehiculo} ${viaje.conductor.modeloVehiculo} · ${viaje.conductor.placa}',
                        ),
                        trailing: Text(
                          'S/ ${viaje.tarifaFinal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.flag),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _finalizando
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Finalizar viaje'),
                        ),
                        onPressed: _finalizando ? null : _finalizarViaje,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
