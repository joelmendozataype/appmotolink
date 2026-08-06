import 'package:flutter/foundation.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/storage/sesion_storage.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';

/// Estado de sesión real (ChangeNotifier), única fuente de verdad sobre
/// quién está autenticado. Las páginas se suscriben con
/// `context.watch<AuthProvider>()` y disparan acciones con
/// `context.read<AuthProvider>()`.
///
/// La sesión se guarda cifrada en el dispositivo (ver [SesionStorage]) y
/// se restaura al arrancar: antes vivía solo en memoria y se perdía al
/// cerrar la app, obligando a iniciar sesión cada vez.
class AuthProvider extends ChangeNotifier {
  final SesionStorage _storage;

  AuthProvider({SesionStorage? storage})
      : _storage = storage ?? const SesionStorage();

  Usuario? _usuarioActual;

  Usuario? get usuarioActual => _usuarioActual;
  bool get autenticado => _usuarioActual != null;

  Future<Usuario> login(String correo, String contrasena) async {
    final usuario = await ServiceLocator.loginUsuario(correo, contrasena);
    await _recordar(usuario);
    return usuario;
  }

  Future<Usuario> registrarPasajero(Usuario usuario) async {
    final creado = await ServiceLocator.registrarUsuario(usuario);
    await _recordar(creado);
    return creado;
  }

  Future<Mototaxista> registrarMototaxista(Mototaxista mototaxista) async {
    final creado =
        await ServiceLocator.registrarPerfilMototaxista(mototaxista);
    await _recordar(creado.usuario);
    return creado;
  }

  /// Recupera la sesión de un arranque anterior.
  ///
  /// No basta con leer lo guardado: la cookie caduca a los 7 días y el
  /// usuario puede haber sido desactivado. Por eso se valida contra el
  /// backend con /usuarios/me antes de darla por buena; si no responde,
  /// se descarta y se empieza de cero.
  ///
  /// Devuelve el usuario restaurado, o null si no había sesión guardada
  /// o ya no es válida.
  Future<Usuario?> restaurarSesion() async {
    final cookie = await _storage.leerCookie();
    if (cookie == null) return null;

    ServiceLocator.apiClient.restaurarSesion(cookie);
    try {
      final usuario = await ServiceLocator.obtenerUsuarioActual();
      _usuarioActual = usuario;
      notifyListeners();
      return usuario;
    } catch (_) {
      // Sesión caducada, revocada, o backend inalcanzable. En los tres
      // casos lo correcto es volver a pedir credenciales.
      await _olvidar();
      return null;
    }
  }

  Future<void> cerrarSesion() async {
    try {
      await ServiceLocator.logoutUsuario();
    } catch (_) {
      // Que el backend no conteste no debe impedir cerrar sesión aquí:
      // lo importante es borrar la credencial del dispositivo.
    }
    await _olvidar();
  }

  Future<void> _recordar(Usuario usuario) async {
    _usuarioActual = usuario;
    final cookie = ServiceLocator.apiClient.sessionCookie;
    if (cookie != null) {
      await _storage.guardar(cookie: cookie, usuario: usuario);
    }
    notifyListeners();
  }

  Future<void> _olvidar() async {
    ServiceLocator.apiClient.cerrarSesion();
    await _storage.limpiar();
    _usuarioActual = null;
    notifyListeners();
  }
}
