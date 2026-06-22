import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';
import 'package:mobile/features/trip_request/domain/repositories/solicitud_viaje_repository.dart';

class CrearSolicitudViaje {
  final SolicitudViajeRepository repository;

  CrearSolicitudViaje(this.repository);

  Future<SolicitudViaje> call(SolicitudViaje solicitud, String pasajeroId) {
    return repository.crearSolicitud(solicitud, pasajeroId);
  }
}
