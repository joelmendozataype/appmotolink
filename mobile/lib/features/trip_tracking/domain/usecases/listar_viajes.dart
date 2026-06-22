import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/features/trip_tracking/domain/repositories/viaje_repository.dart';

class ListarViajes {
  final ViajeRepository repository;

  ListarViajes(this.repository);

  Future<List<Viaje>> call() => repository.listarTodos();
}
