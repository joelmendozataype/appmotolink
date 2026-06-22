import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';

abstract class UsuarioRepository {
  Future<Usuario> login(String correo, String contrasena);
  Future<Usuario> registrar(Usuario usuario);
  Future<void> logout();
  Future<Usuario> obtenerUsuarioActual();
  Future<Usuario> actualizarUsuario(Usuario usuario);
  Future<List<Usuario>> listarTodos();
  Future<List<Usuario>> listarPasajeros();
  Future<void> eliminarUsuario(String id);
}
