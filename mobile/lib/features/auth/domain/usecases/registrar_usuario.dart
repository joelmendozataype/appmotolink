import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/auth/domain/repositories/usuario_repository.dart';

class RegistrarUsuario {
  final UsuarioRepository repository;

  RegistrarUsuario(this.repository);

  Future<Usuario> call(Usuario usuario) {
    return repository.registrar(usuario);
  }
}
