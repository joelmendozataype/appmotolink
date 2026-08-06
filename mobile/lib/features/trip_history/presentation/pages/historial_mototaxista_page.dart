import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/enums/estado_viaje.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/utils/formato_fecha.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/shared/widgets/async_state_view.dart';
import 'package:provider/provider.dart';

class HistorialMototaxistaPage extends StatefulWidget {
  const HistorialMototaxistaPage({super.key});

  @override
  State<HistorialMototaxistaPage> createState() =>
      _HistorialMototaxistaPageState();
}

class _HistorialMototaxistaPageState extends State<HistorialMototaxistaPage> {
  List<Viaje> _viajes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final usuario = context.read<AuthProvider>().usuarioActual;
    if (usuario == null) {
      setState(() => _cargando = false);
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final historial = await ServiceLocator.obtenerHistorial(usuario.id);
      if (!mounted) return;
      setState(() {
        _viajes = historial.viajes;
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

  String _etiquetaEstado(EstadoViaje estado) {
    switch (estado) {
      case EstadoViaje.finalizado:
        return 'Finalizado';
      case EstadoViaje.cancelado:
        return 'Cancelado';
      case EstadoViaje.asignado:
        return 'Asignado';
      case EstadoViaje.enCurso:
        return 'En curso';
    }
  }

  /// Estado, fecha y —si el viaje ya terminó— cuánto duró.
  String _detalle(Viaje viaje) {
    final duracion = FormatoFecha.duracion(viaje.duracionMinutos);
    final segunda = duracion == null
        ? FormatoFecha.legible(viaje.creadoEn)
        : '${FormatoFecha.legible(viaje.creadoEn)} · $duracion';
    return '${_etiquetaEstado(viaje.estado)}\n$segunda';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de viajes')),
      body: AsyncStateView<List<Viaje>>(
        cargando: _cargando,
        error: _error,
        datos: _viajes,
        estaVacio: (l) => l.isEmpty,
        onReintentar: _cargarHistorial,
        mensajeVacio: 'Aún no tienes viajes registrados',
        builder: (viajes) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: viajes.length,
          itemBuilder: (context, index) {
            final viaje = viajes[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(viaje.pasajero.nombre),
                subtitle: Text(_detalle(viaje)),
                isThreeLine: true,
                trailing: Text(
                  'S/ ${viaje.tarifaFinal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
