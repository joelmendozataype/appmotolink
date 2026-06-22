import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/shared/widgets/error_retry_view.dart';

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
      body: _error != null
          ? ErrorRetryView(mensaje: _error!, onRetry: _cargar)
          : _cargando
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
