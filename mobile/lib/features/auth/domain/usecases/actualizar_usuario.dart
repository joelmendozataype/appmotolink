import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/auth/domain/repositories/usuario_repository.dart';

class ActualizarUsuario {
  final UsuarioRepository repository;

  ActualizarUsuario(this.repository);

  Future<Usuario> call(Usuario usuario) {
    return repository.actualizarUsuario(usuario);
  }
}
