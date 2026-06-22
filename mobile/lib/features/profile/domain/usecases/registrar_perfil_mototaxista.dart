import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';
import 'package:mobile/features/profile/domain/repositories/mototaxista_repository.dart';

class RegistrarPerfilMototaxista {
  final MototaxistaRepository repository;

  RegistrarPerfilMototaxista(this.repository);

  Future<Mototaxista> call(Mototaxista mototaxista) {
    return repository.registrarPerfil(mototaxista);
  }
}
