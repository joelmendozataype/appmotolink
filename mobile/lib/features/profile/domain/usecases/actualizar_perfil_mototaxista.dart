import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';
import 'package:mobile/features/profile/domain/repositories/mototaxista_repository.dart';

class ActualizarPerfilMototaxista {
  final MototaxistaRepository repository;

  ActualizarPerfilMototaxista(this.repository);

  Future<Mototaxista> call(Mototaxista mototaxista) {
    return repository.actualizarPerfil(mototaxista);
  }
}
