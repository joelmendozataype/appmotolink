import 'package:mobile/core/enums/estado_viaje.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/features/trip_tracking/domain/repositories/viaje_repository.dart';

class ActualizarEstadoViaje {
  final ViajeRepository repository;

  ActualizarEstadoViaje(this.repository);

  Future<Viaje> call(String viajeId, EstadoViaje estado) {
    return repository.actualizarEstado(viajeId, estado);
  }
}
