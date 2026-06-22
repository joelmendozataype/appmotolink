import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';

class ListaConductoresPage extends StatefulWidget {
  const ListaConductoresPage({super.key});

  @override
  State<ListaConductoresPage> createState() => _ListaConductoresPageState();
}

class _ListaConductoresPageState extends State<ListaConductoresPage> {
  List<Mototaxista> _conductores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final conductores = await ServiceLocator.listarMototaxistas();
    if (!mounted) return;
    setState(() {
      _conductores = conductores;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Conductores')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _conductores.length,
              itemBuilder: (context, index) {
                final conductor = _conductores[index];
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
    );
  }
}
