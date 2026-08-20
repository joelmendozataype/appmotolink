import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/core/utils/sesion_guard.dart';
import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';
import 'package:mobile/shared/widgets/campo_tarifa.dart';

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
                // Antes solo se veían los dos nombres, uno encima del
                // otro: no había forma de saber cuál era el origen y cuál
                // el destino salvo por el orden.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Lugar(
                          icono: Icons.my_location,
                          etiqueta: 'Lugar de origen',
                          nombre: widget.origen,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Icon(Icons.arrow_downward, size: 18),
                        ),
                        _Lugar(
                          icono: Icons.flag,
                          etiqueta: 'Lugar de destino',
                          nombre: widget.destino,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: CampoTarifa(
                    controller: _tarifaController,
                    etiqueta: '¿Cuánto quieres pagar?',
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

/// Un lugar del viaje, con su etiqueta encima para no confundir el origen
/// con el destino.
class _Lugar extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String nombre;

  const _Lugar({
    required this.icono,
    required this.etiqueta,
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: colores.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TextStyle(fontSize: 12, color: colores.onSurfaceVariant),
              ),
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
