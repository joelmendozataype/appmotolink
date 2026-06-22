import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/auth/domain/repositories/usuario_repository.dart';

class LoginUsuario {
  final UsuarioRepository repository;

  LoginUsuario(this.repository);

  Future<Usuario> call(String correo, String contrasena) {
    return repository.login(correo, contrasena);
  }
}
