import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';

class ListaPasajerosPage extends StatefulWidget {
  const ListaPasajerosPage({super.key});

  @override
  State<ListaPasajerosPage> createState() => _ListaPasajerosPageState();
}

class _ListaPasajerosPageState extends State<ListaPasajerosPage> {
  List<Usuario> _pasajeros = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final pasajeros = await ServiceLocator.listarPasajeros();
    if (!mounted) return;
    setState(() {
      _pasajeros = pasajeros;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Pasajeros')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pasajeros.length,
              itemBuilder: (context, index) {
                final pasajero = _pasajeros[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(pasajero.nombre[0])),
                    title: Text(pasajero.nombre),
                    subtitle: Text(pasajero.correo),
                  ),
                );
              },
            ),
    );
  }
}
