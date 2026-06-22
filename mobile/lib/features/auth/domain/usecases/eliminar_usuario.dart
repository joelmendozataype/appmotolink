import 'package:mobile/features/auth/domain/repositories/usuario_repository.dart';

class EliminarUsuario {
  final UsuarioRepository repository;

  EliminarUsuario(this.repository);

  Future<void> call(String id) => repository.eliminarUsuario(id);
}
