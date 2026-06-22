import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';
import 'package:mobile/shared/widgets/error_retry_view.dart';
import 'package:provider/provider.dart';

/// El conductor responde a una solicitud: aceptar la tarifa propuesta,
/// contraofertar una distinta, o rechazarla. Las tres acciones crean una
/// Oferta en el backend; el viaje recién se asigna cuando el pasajero
/// selecciona una oferta (ver InicioMototaxistaPage, que escucha el
/// evento ViajeAsignado por socket).
class ContraofertaPage extends StatefulWidget {
  final String solicitudId;

  const ContraofertaPage({super.key, required this.solicitudId});

  @override
  State<ContraofertaPage> createState() => _ContraofertaPageState();
}

class _ContraofertaPageState extends State<ContraofertaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tarifaController;
  SolicitudViaje? _solicitud;
  String? _errorCarga;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _tarifaController = TextEditingController();
    _cargarSolicitud();
  }

  Future<void> _cargarSolicitud() async {
    setState(() => _errorCarga = null);
    try {
      final disponibles = await ServiceLocator.obtenerSolicitudesDisponibles();
      final solicitud =
          disponibles.firstWhere((s) => s.id == widget.solicitudId);
      if (!mounted) return;
      setState(() {
        _solicitud = solicitud;
        _tarifaController.text = solicitud.tarifaPropuesta.toStringAsFixed(2);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorCarga = mensajeDeError(e));
    }
  }

  String get _conductorId => context.read<AuthProvider>().usuarioActual!.id;

  Future<void> _responder(Future<void> Function() accion) async {
    setState(() => _enviando = true);
    try {
      await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respuesta enviada. Esperando selección del pasajero.'),
        ),
      );
      context.go(AppRoutes.inicioMototaxista);
    } on ServerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e))),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _aceptar() => _responder(
        () => ServiceLocator.aceptarSolicitud(widget.solicitudId, _conductorId),
      );

  Future<void> _contraofertar() {
    if (!_formKey.currentState!.validate()) return Future.value();
    final tarifa = double.parse(_tarifaController.text.trim());
    return _responder(
      () => ServiceLocator.contraofertarSolicitud(
        widget.solicitudId,
        _conductorId,
        tarifa,
      ),
    );
  }

  Future<void> _rechazar() => _responder(
        () => ServiceLocator.rechazarSolicitud(widget.solicitudId, _conductorId),
      );

  @override
  Widget build(BuildContext context) {
    final solicitud = _solicitud;
    return Scaffold(
      appBar: AppBar(title: const Text('Responder solicitud')),
      body: _errorCarga != null
          ? ErrorRetryView(mensaje: _errorCarga!, onRetry: _cargarSolicitud)
          : solicitud == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(
                            '${solicitud.origen} → ${solicitud.destino}',
                          ),
                          subtitle: Text(
                            'Tarifa propuesta por el pasajero: S/ ${solicitud.tarifaPropuesta.toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        onPressed: _enviando ? null : _aceptar,
                        label: const Text('Aceptar tarifa propuesta'),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _tarifaController,
                          decoration: const InputDecoration(
                            labelText: 'O propone tu tarifa (S/)',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa una tarifa';
                            }
                            final n = double.tryParse(v);
                            if (n == null || n <= 0) return 'Tarifa inválida';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _enviando ? null : _contraofertar,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Enviar contraoferta'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _enviando ? null : _rechazar,
                        child: const Text('Rechazar solicitud'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
