import 'package:mobile/features/auth/domain/repositories/usuario_repository.dart';

class LogoutUsuario {
  final UsuarioRepository repository;

  LogoutUsuario(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}
