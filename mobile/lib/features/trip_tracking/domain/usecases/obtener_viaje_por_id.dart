import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/features/trip_tracking/domain/repositories/viaje_repository.dart';

class ObtenerViajePorId {
  final ViajeRepository repository;

  ObtenerViajePorId(this.repository);

  Future<Viaje> call(String viajeId) {
    return repository.obtenerPorId(viajeId);
  }
}
