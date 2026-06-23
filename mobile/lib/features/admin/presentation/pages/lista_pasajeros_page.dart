import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/shared/widgets/async_state_view.dart';

class ListaPasajerosPage extends StatefulWidget {
  const ListaPasajerosPage({super.key});

  @override
  State<ListaPasajerosPage> createState() => _ListaPasajerosPageState();
}

class _ListaPasajerosPageState extends State<ListaPasajerosPage> {
  List<Usuario> _pasajeros = [];
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
      final pasajeros = await ServiceLocator.listarPasajeros();
      if (!mounted) return;
      setState(() {
        _pasajeros = pasajeros;
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
      appBar: AppBar(title: const Text('Lista de Pasajeros')),
      body: AsyncStateView<List<Usuario>>(
        cargando: _cargando,
        error: _error,
        datos: _pasajeros,
        estaVacio: (l) => l.isEmpty,
        onReintentar: _cargar,
        mensajeVacio: 'No hay pasajeros registrados',
        builder: (pasajeros) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pasajeros.length,
          itemBuilder: (context, index) {
            final pasajero = pasajeros[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(pasajero.nombre[0])),
                title: Text(pasajero.nombre),
                subtitle: Text(pasajero.correo),
              ),
            );
          },
        ),
      ),
    );
  }
}
