import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';
import 'package:mobile/features/trip_request/domain/repositories/solicitud_viaje_repository.dart';

class ObtenerSolicitudesDisponibles {
  final SolicitudViajeRepository repository;

  ObtenerSolicitudesDisponibles(this.repository);

  Future<List<SolicitudViaje>> call() {
    return repository.obtenerSolicitudesDisponibles();
  }
}
