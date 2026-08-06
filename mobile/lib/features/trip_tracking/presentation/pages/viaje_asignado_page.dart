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

class ViajeAsignadoPage extends StatefulWidget {
  final String viajeId;

  const ViajeAsignadoPage({super.key, required this.viajeId});

  @override
  State<ViajeAsignadoPage> createState() => _ViajeAsignadoPageState();
}

class _ViajeAsignadoPageState extends State<ViajeAsignadoPage> {
  Viaje? _viaje;
  String? _error;
  bool _finalizando = false;

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

  /// El conductor ve su propia posición sobre el mapa mientras lleva al
  /// pasajero. Si el permiso está denegado, el viaje sigue funcionando:
  /// el mapa se queda centrado sin marcador, y nada más.
  Future<void> _iniciarSeguimientoGps() async {
    try {
      final inicial = await LocationService.obtenerUbicacionActual();
      if (!mounted) return;
      setState(() {
        _posicionActual = inicial;
        _recorrido.add(inicial);
      });
      _suscripcionUbicacion = LocationCalculos.seguirUbicacion().listen((pos) {
        if (!mounted) return;
        setState(() {
          _posicionActual = pos;
          _recorrido.add(pos);
        });
      });
    } on LocationPermissionDeniedException {
      // Sin GPS el viaje continúa igual; no es un error bloqueante.
    }
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

  Future<void> _finalizarViaje() async {
    setState(() => _finalizando = true);
    try {
      await ServiceLocator.finalizarViaje(widget.viajeId);
      if (!mounted) return;
      context.go(AppRoutes.inicioMototaxista);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viaje = _viaje;
    return Scaffold(
      appBar: AppBar(title: const Text('Viaje asignado')),
      body: _error != null
          ? ErrorRetryView(mensaje: _error!, onRetry: _cargarViaje)
          : viaje == null
          ? const Center(child: CircularProgressIndicator())
          : MapaViaje(
              posicion: _posicionActual,
              recorrido: _recorrido,
              icono: Icons.two_wheeler,
            ),
      // Ver la nota en viaje_en_curso_page: al vivir en bottomNavigationBar,
      // el botón queda por encima de cualquier SnackBar en vez de debajo.
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
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(viaje.pasajero.nombre),
              subtitle: const Text('Pasajero'),
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
