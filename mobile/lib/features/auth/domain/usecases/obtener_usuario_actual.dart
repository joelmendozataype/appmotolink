import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/auth/domain/repositories/usuario_repository.dart';

class ObtenerUsuarioActual {
  final UsuarioRepository repository;

  ObtenerUsuarioActual(this.repository);

  Future<Usuario> call() {
    return repository.obtenerUsuarioActual();
  }
}
