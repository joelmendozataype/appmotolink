import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/shared/widgets/async_state_view.dart';

class GestionUsuariosPage extends StatefulWidget {
  const GestionUsuariosPage({super.key});

  @override
  State<GestionUsuariosPage> createState() => _GestionUsuariosPageState();
}

class _GestionUsuariosPageState extends State<GestionUsuariosPage> {
  List<Usuario> _usuarios = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final usuarios = await ServiceLocator.listarUsuarios();
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
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
    try {
      await ServiceLocator.eliminarUsuario(usuarioId);
      _cargarUsuarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de usuarios')),
      body: AsyncStateView<List<Usuario>>(
        cargando: _cargando,
        error: _error,
        datos: _usuarios,
        estaVacio: (l) => l.isEmpty,
        onReintentar: _cargarUsuarios,
        mensajeVacio: 'No hay usuarios registrados',
        builder: (usuarios) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final usuario = usuarios[index];
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
      ),
    );
  }
}
