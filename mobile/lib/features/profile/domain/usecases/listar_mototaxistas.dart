import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';
import 'package:mobile/features/profile/domain/repositories/mototaxista_repository.dart';

class ListarMototaxistas {
  final MototaxistaRepository repository;

  ListarMototaxistas(this.repository);

  Future<List<Mototaxista>> call() => repository.listarTodos();
}
