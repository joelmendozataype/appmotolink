import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/features/trip_tracking/domain/repositories/viaje_repository.dart';

class FinalizarViaje {
  final ViajeRepository repository;

  FinalizarViaje(this.repository);

  Future<Viaje> call(String viajeId) {
    return repository.finalizarViaje(viajeId);
  }
}
