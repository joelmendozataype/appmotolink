import 'dart:convert';

import 'package:mobile/core/storage/almacen_seguro.dart';
import 'package:mobile/features/auth/data/models/usuario_model.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';

/// Guarda la sesión entre arranques de la app.
///
/// Antes `AuthProvider` la mantenía solo en memoria: al cerrar la app —o
/// tras un hot restart— se perdía, y como toda la API exige autenticación,
/// había que volver a escribir correo y contraseña cada vez.
///
/// Se usa almacenamiento cifrado y no `shared_preferences` porque lo que
/// se guarda es la cookie de sesión: con ella se actúa en nombre del
/// usuario hasta que caduca, así que merece el mismo cuidado que una
/// contraseña. En Android esto se apoya en EncryptedSharedPreferences.
class SesionStorage {
  static const _claveCookie = 'motolink.sesion.cookie';
  static const _claveUsuario = 'motolink.sesion.usuario';

  final AlmacenSeguro _storage;

  const SesionStorage({AlmacenSeguro? storage})
      : _storage = storage ?? const AlmacenSeguroFlutter();

  Future<void> guardar({required String cookie, required Usuario usuario}) async {
    final datos = UsuarioModel.fromEntity(usuario).toJson();
    // La contraseña no se guarda jamás. Tras el login llega vacía (el
    // backend es write_only), pero conviene que no dependa de eso.
    datos.remove('contrasena');

    await _storage.escribir(_claveCookie, cookie);
    await _storage.escribir(_claveUsuario, jsonEncode(datos));
  }

  Future<String?> leerCookie() => _storage.leer(_claveCookie);

  Future<Usuario?> leerUsuario() async {
    final json = await _storage.leer(_claveUsuario);
    if (json == null) return null;
    try {
      return UsuarioModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      // Formato viejo o dato corrupto: se descarta en vez de arrastrar el
      // problema a cada arranque.
      await limpiar();
      return null;
    }
  }

  Future<void> limpiar() async {
    await _storage.borrar(_claveCookie);
    await _storage.borrar(_claveUsuario);
  }
}
