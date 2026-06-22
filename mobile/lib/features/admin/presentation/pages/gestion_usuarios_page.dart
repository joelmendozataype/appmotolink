import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';

class GestionUsuariosPage extends StatefulWidget {
  const GestionUsuariosPage({super.key});

  @override
  State<GestionUsuariosPage> createState() => _GestionUsuariosPageState();
}

class _GestionUsuariosPageState extends State<GestionUsuariosPage> {
  List<Usuario> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    final usuarios = await ServiceLocator.listarUsuarios();
    if (!mounted) return;
    setState(() {
      _usuarios = usuarios;
      _cargando = false;
    });
  }

  String _etiquetaRol(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.pasajero:
        return 'Pasajero';
      case RolUsuario.mototaxista:
        return 'Mototaxista';
      case RolUsuario.administrador:
        return 'Administrador';
    }
  }

  Future<void> _eliminar(String usuarioId) async {
    await ServiceLocator.eliminarUsuario(usuarioId);
    _cargarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de usuarios')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final usuario = _usuarios[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(usuario.nombre[0])),
                    title: Text(usuario.nombre),
                    subtitle: Text(
                      '${usuario.correo} · ${_etiquetaRol(usuario.rol)}',
                    ),
                    trailing: usuario.rol == RolUsuario.administrador
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _eliminar(usuario.id),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
