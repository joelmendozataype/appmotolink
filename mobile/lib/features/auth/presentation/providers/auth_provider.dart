import 'package:flutter/foundation.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';

/// Estado de sesión real (ChangeNotifier), única fuente de verdad sobre
/// quién está autenticado. Las páginas se suscriben con
/// `context.watch<AuthProvider>()` y disparan acciones con
/// `context.read<AuthProvider>()`.
class AuthProvider extends ChangeNotifier {
  Usuario? _usuarioActual;

  Usuario? get usuarioActual => _usuarioActual;
  bool get autenticado => _usuarioActual != null;

  Future<Usuario> login(String correo, String contrasena) async {
    final usuario = await ServiceLocator.loginUsuario(correo, contrasena);
    _usuarioActual = usuario;
    notifyListeners();
    return usuario;
  }

  Future<Usuario> registrarPasajero(Usuario usuario) async {
    final creado = await ServiceLocator.registrarUsuario(usuario);
    _usuarioActual = creado;
    notifyListeners();
    return creado;
  }

  Future<Mototaxista> registrarMototaxista(Mototaxista mototaxista) async {
    final creado =
        await ServiceLocator.registrarPerfilMototaxista(mototaxista);
    _usuarioActual = creado.usuario;
    notifyListeners();
    return creado;
  }

  Future<void> cerrarSesion() async {
    await ServiceLocator.logoutUsuario();
    ServiceLocator.apiClient.cerrarSesion();
    _usuarioActual = null;
    notifyListeners();
  }
}
