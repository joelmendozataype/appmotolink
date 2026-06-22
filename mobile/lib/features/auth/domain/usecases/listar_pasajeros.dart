import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/auth/domain/repositories/usuario_repository.dart';

class ListarPasajeros {
  final UsuarioRepository repository;

  ListarPasajeros(this.repository);

  Future<List<Usuario>> call() => repository.listarPasajeros();
}
