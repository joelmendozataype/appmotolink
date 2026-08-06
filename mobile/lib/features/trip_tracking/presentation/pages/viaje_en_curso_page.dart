import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/location/location_service.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/shared/widgets/error_retry_view.dart';
import 'package:mobile/shared/widgets/mapa_viaje.dart';

class ViajeEnCursoPage extends StatefulWidget {
  final String viajeId;

  const ViajeEnCursoPage({super.key, required this.viajeId});

  @override
  State<ViajeEnCursoPage> createState() => _ViajeEnCursoPageState();
}

class _ViajeEnCursoPageState extends State<ViajeEnCursoPage> {
  Viaje? _viaje;
  String? _error;
  bool _finalizando = false;

  Position? _posicionInicial;
  Position? _posicionActual;
  final List<Position> _recorrido = [];
  StreamSubscription<Position>? _suscripcionUbicacion;

  @override
  void initState() {
    super.initState();
    _cargarViaje();
    _iniciarSeguimientoGps();
  }

  @override
  void dispose() {
    _suscripcionUbicacion?.cancel();
    super.dispose();
  }

  Future<void> _cargarViaje() async {
    setState(() => _error = null);
    try {
      final viaje = await ServiceLocator.obtenerViajePorId(widget.viajeId);
      if (!mounted) return;
      setState(() => _viaje = viaje);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    }
  }

  /// Sensor GPS real durante el viaje: captura la posición al iniciar y
  /// sigue la ubicación en vivo para mostrar cuánto se ha recorrido desde
  /// ese punto. Si el GPS no está disponible, el viaje sigue funcionando
  /// igual (este panel simplemente no se muestra).
  Future<void> _iniciarSeguimientoGps() async {
    try {
      final inicial = await LocationService.obtenerUbicacionActual();
      if (!mounted) return;
      setState(() {
        _posicionInicial = inicial;
        _posicionActual = inicial;
        _recorrido.add(inicial);
      });
      _suscripcionUbicacion = LocationCalculos.seguirUbicacion().listen((pos) {
        if (!mounted) return;
        setState(() {
          _posicionActual = pos;
          // Se acumula para dibujar el trazo del recorrido en el mapa.
          _recorrido.add(pos);
        });
      });
    } on LocationPermissionDeniedException {
      // GPS desactivado o permiso denegado: el viaje continúa sin el
      // panel de seguimiento, no es un error bloqueante.
    }
  }

  Future<void> _finalizarViaje() async {
    setState(() => _finalizando = true);
    try {
      await ServiceLocator.finalizarViaje(widget.viajeId);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.calificacionPath(widget.viajeId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  String _textoSeguimientoGps() {
    final inicial = _posicionInicial;
    final actual = _posicionActual;
    if (inicial == null || actual == null) {
      return 'Obteniendo ubicación GPS...';
    }
    final metros = LocationCalculos.distanciaEnMetros(inicial, actual);
    return 'Recorrido: ${LocationCalculos.distanciaLegible(metros)}';
  }

  @override
  Widget build(BuildContext context) {
    final viaje = _viaje;
    return Scaffold(
      appBar: AppBar(title: const Text('Viaje en curso')),
      body: _error != null
          ? ErrorRetryView(mensaje: _error!, onRetry: _cargarViaje)
          : viaje == null
          ? const Center(child: CircularProgressIndicator())
          : MapaViaje(
              posicion: _posicionActual,
              recorrido: _recorrido,
              icono: Icons.person_pin_circle,
              leyenda: _textoSeguimientoGps(),
            ),
      // Los datos del conductor y el botón van en bottomNavigationBar, no
      // dentro del body: Flutter dibuja los SnackBar por encima del body
      // pero por debajo de esta barra, así que el botón "Finalizar viaje"
      // nunca queda tapado por una notificación.
      bottomNavigationBar: (_error != null || viaje == null)
          ? null
          : _barraInferior(viaje),
    );
  }

  Widget _barraInferior(Viaje viaje) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.two_wheeler)),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Finalizar viaje'),
              ),
              onPressed: _finalizando ? null : _finalizarViaje,
            ),
          ],
        ),
      ),
    );
  }
}
