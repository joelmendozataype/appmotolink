import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/enums/estado_viaje.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
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
    final historial = await ServiceLocator.obtenerHistorial(usuario.id);
    if (!mounted) return;
    setState(() {
      _viajes = historial.viajes;
      _cargando = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de viajes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _viajes.isEmpty
              ? const Center(child: Text('Aún no tienes viajes registrados'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _viajes.length,
                  itemBuilder: (context, index) {
                    final viaje = _viajes[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(viaje.pasajero.nombre),
                        subtitle: Text(_etiquetaEstado(viaje.estado)),
                        trailing: Text(
                          'S/ ${viaje.tarifaFinal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
