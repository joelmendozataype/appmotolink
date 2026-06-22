import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/auth/domain/repositories/usuario_repository.dart';

class ListarUsuarios {
  final UsuarioRepository repository;

  ListarUsuarios(this.repository);

  Future<List<Usuario>> call() => repository.listarTodos();
}
