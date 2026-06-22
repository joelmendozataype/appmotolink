import 'package:mobile/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:mobile/features/auth/data/models/usuario_model.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/auth/domain/repositories/usuario_repository.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepositoryImpl(this.remoteDataSource);

  UsuarioModel _toModel(Usuario usuario) => UsuarioModel(
        id: usuario.id,
        nombre: usuario.nombre,
        correo: usuario.correo,
        contrasena: usuario.contrasena,
        rol: usuario.rol,
      );

  @override
  Future<Usuario> login(String correo, String contrasena) {
    return remoteDataSource.login(correo, contrasena);
  }

  @override
  Future<Usuario> registrar(Usuario usuario) {
    return remoteDataSource.registrar(_toModel(usuario));
  }

  @override
  Future<void> logout() {
    return remoteDataSource.logout();
  }

  @override
  Future<Usuario> obtenerUsuarioActual() {
    return remoteDataSource.obtenerUsuarioActual();
  }

  @override
  Future<Usuario> actualizarUsuario(Usuario usuario) {
    return remoteDataSource.actualizarUsuario(_toModel(usuario));
  }

  @override
  Future<List<Usuario>> listarTodos() {
    return remoteDataSource.listarTodos();
  }

  @override
  Future<List<Usuario>> listarPasajeros() {
    return remoteDataSource.listarPasajeros();
  }

  @override
  Future<void> eliminarUsuario(String id) {
    return remoteDataSource.eliminarUsuario(id);
  }
}
