import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/core/utils/sesion_guard.dart';
import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';

class ProponerTarifaPage extends StatefulWidget {
  final String origen;
  final String destino;

  const ProponerTarifaPage({
    super.key,
    required this.origen,
    required this.destino,
  });

  @override
  State<ProponerTarifaPage> createState() => _ProponerTarifaPageState();
}

class _ProponerTarifaPageState extends State<ProponerTarifaPage> {
  final _formKey = GlobalKey<FormState>();
  final _tarifaController = TextEditingController();
  bool _cargando = false;

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    final tarifa = double.parse(_tarifaController.text.trim());
    final pasajero = usuarioEnSesion(context);
    if (pasajero == null) return;
    final pasajeroId = pasajero.id;

    setState(() => _cargando = true);
    try {
      final solicitud = await ServiceLocator.crearSolicitudViaje(
        SolicitudViaje(
          id: '',
          origen: widget.origen,
          destino: widget.destino,
          tarifaPropuesta: tarifa,
          estado: EstadoSolicitud.pendiente,
        ),
        pasajeroId,
      );
      if (!mounted) return;
      context.pushReplacement(AppRoutes.ofertasRecibidasPath(solicitud.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proponer tarifa')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.my_location),
                    title: Text(widget.origen),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.arrow_downward, size: 16),
                        const SizedBox(width: 8),
                        Text(widget.destino),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _tarifaController,
                    decoration: const InputDecoration(
                      labelText: '¿Cuánto quieres pagar? (S/)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa una tarifa';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Tarifa inválida';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _cargando ? null : _enviarSolicitud,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _cargando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar solicitud'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
