import 'package:mobile/features/trip_request/domain/repositories/solicitud_viaje_repository.dart';

class CancelarSolicitudViaje {
  final SolicitudViajeRepository repository;

  CancelarSolicitudViaje(this.repository);

  Future<void> call(String id) {
    return repository.cancelarSolicitud(id);
  }
}
