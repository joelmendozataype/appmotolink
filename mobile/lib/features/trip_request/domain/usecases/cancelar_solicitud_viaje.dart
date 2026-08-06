import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';
import 'package:mobile/features/trip_request/domain/repositories/solicitud_viaje_repository.dart';

class CancelarSolicitudViaje {
  final SolicitudViajeRepository repository;

  CancelarSolicitudViaje(this.repository);

  Future<SolicitudViaje> call(String id) {
    return repository.cancelarSolicitud(id);
  }
}
