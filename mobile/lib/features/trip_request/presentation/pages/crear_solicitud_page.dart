import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/location/location_service.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/core/utils/validaciones.dart';

class CrearSolicitudPage extends StatefulWidget {
  const CrearSolicitudPage({super.key});

  @override
  State<CrearSolicitudPage> createState() => _CrearSolicitudPageState();
}

class _CrearSolicitudPageState extends State<CrearSolicitudPage> {
  final _formKey = GlobalKey<FormState>();
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  bool _ubicando = false;

  Future<void> _usarUbicacionActual() async {
    setState(() => _ubicando = true);
    try {
      final posicion = await LocationService.obtenerUbicacionActual();
      _origenController.text = LocationService.formatear(posicion);
    } on LocationPermissionDeniedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _ubicando = false);
    }
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;
    context.push(
      AppRoutes.proponerTarifa,
      extra: {
        'origen': _origenController.text.trim(),
        'destino': _destinoController.text.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear solicitud')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _origenController,
                    decoration: InputDecoration(
                      labelText: 'Origen',
                      prefixIcon: const Icon(Icons.my_location),
                      suffixIcon: _ubicando
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.gps_fixed),
                              tooltip: 'Usar mi ubicación GPS',
                              onPressed: _usarUbicacionActual,
                            ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        Validaciones.lugar(v, campo: 'el origen'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destinoController,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        Validaciones.lugar(v, campo: 'el destino'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _continuar,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
