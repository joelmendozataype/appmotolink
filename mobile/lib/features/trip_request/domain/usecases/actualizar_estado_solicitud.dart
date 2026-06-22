import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';
import 'package:mobile/features/trip_request/domain/repositories/solicitud_viaje_repository.dart';

class ActualizarEstadoSolicitud {
  final SolicitudViajeRepository repository;

  ActualizarEstadoSolicitud(this.repository);

  Future<SolicitudViaje> call(String id, EstadoSolicitud estado) {
    return repository.actualizarEstado(id, estado);
  }
}
