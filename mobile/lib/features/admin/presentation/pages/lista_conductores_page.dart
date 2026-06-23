import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';
import 'package:mobile/shared/widgets/async_state_view.dart';

class ListaConductoresPage extends StatefulWidget {
  const ListaConductoresPage({super.key});

  @override
  State<ListaConductoresPage> createState() => _ListaConductoresPageState();
}

class _ListaConductoresPageState extends State<ListaConductoresPage> {
  List<Mototaxista> _conductores = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final conductores = await ServiceLocator.listarMototaxistas();
      if (!mounted) return;
      setState(() {
        _conductores = conductores;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Conductores')),
      body: AsyncStateView<List<Mototaxista>>(
        cargando: _cargando,
        error: _error,
        datos: _conductores,
        estaVacio: (l) => l.isEmpty,
        onReintentar: _cargar,
        mensajeVacio: 'No hay conductores registrados',
        builder: (conductores) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conductores.length,
          itemBuilder: (context, index) {
            final conductor = conductores[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.two_wheeler)),
                title: Text(conductor.usuario.nombre),
                subtitle: Text(
                  '${conductor.marcaVehiculo} ${conductor.modeloVehiculo} · Placa ${conductor.placa}\nLicencia: ${conductor.licencia}',
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
