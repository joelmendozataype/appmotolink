import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';
import 'package:mobile/features/profile/domain/repositories/mototaxista_repository.dart';

class ObtenerPerfilMototaxista {
  final MototaxistaRepository repository;

  ObtenerPerfilMototaxista(this.repository);

  Future<Mototaxista> call(String usuarioId) {
    return repository.obtenerPerfil(usuarioId);
  }
}
