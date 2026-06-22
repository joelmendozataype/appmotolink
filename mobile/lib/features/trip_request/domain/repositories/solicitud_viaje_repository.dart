import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';

abstract class SolicitudViajeRepository {
  Future<SolicitudViaje> crearSolicitud(
    SolicitudViaje solicitud,
    String pasajeroId,
  );
  Future<SolicitudViaje> obtenerSolicitud(String id);
  Future<List<SolicitudViaje>> obtenerSolicitudesDisponibles();
  Future<SolicitudViaje> actualizarEstado(String id, EstadoSolicitud estado);
  Future<void> cancelarSolicitud(String id);
}
