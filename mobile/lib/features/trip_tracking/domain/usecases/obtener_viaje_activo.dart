import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/features/trip_tracking/domain/repositories/viaje_repository.dart';

class ObtenerViajeActivo {
  final ViajeRepository repository;

  ObtenerViajeActivo(this.repository);

  Future<Viaje> call(String usuarioId) {
    return repository.obtenerViajeActivo(usuarioId);
  }
}
