import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';

class ConductorSeleccionadoPage extends StatefulWidget {
  final Oferta oferta;

  const ConductorSeleccionadoPage({super.key, required this.oferta});

  @override
  State<ConductorSeleccionadoPage> createState() =>
      _ConductorSeleccionadoPageState();
}

class _ConductorSeleccionadoPageState
    extends State<ConductorSeleccionadoPage> {
  bool _cargando = false;

  Future<void> _iniciarViaje() async {
    setState(() => _cargando = true);
    try {
      final viaje = await ServiceLocator.seleccionarOferta(widget.oferta.id);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.viajeEnCursoPath(viaje.id));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conductor = widget.oferta.conductor;
    return Scaffold(
      appBar: AppBar(title: const Text('Conductor seleccionado')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.two_wheeler, size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  conductor.usuario.nombre,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${conductor.marcaVehiculo} ${conductor.modeloVehiculo}'),
                Text('Placa: ${conductor.placa}'),
                Text('Licencia: ${conductor.licencia}'),
                const SizedBox(height: 16),
                Text(
                  'Tarifa acordada: S/ ${widget.oferta.tarifa.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _cargando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar viaje'),
                  ),
                  onPressed: _cargando ? null : _iniciarViaje,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
