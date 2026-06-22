import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/features/trip_request/data/datasources/solicitud_viaje_remote_datasource.dart';
import 'package:mobile/features/trip_request/data/models/solicitud_viaje_model.dart';
import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';
import 'package:mobile/features/trip_request/domain/repositories/solicitud_viaje_repository.dart';

class SolicitudViajeRepositoryImpl implements SolicitudViajeRepository {
  final SolicitudViajeRemoteDataSource remoteDataSource;

  SolicitudViajeRepositoryImpl(this.remoteDataSource);

  SolicitudViajeModel _toModel(SolicitudViaje solicitud) => SolicitudViajeModel(
        id: solicitud.id,
        origen: solicitud.origen,
        destino: solicitud.destino,
        tarifaPropuesta: solicitud.tarifaPropuesta,
        estado: solicitud.estado,
      );

  @override
  Future<SolicitudViaje> crearSolicitud(
    SolicitudViaje solicitud,
    String pasajeroId,
  ) {
    return remoteDataSource.crearSolicitud(_toModel(solicitud), pasajeroId);
  }

  @override
  Future<SolicitudViaje> obtenerSolicitud(String id) {
    return remoteDataSource.obtenerSolicitud(id);
  }

  @override
  Future<List<SolicitudViaje>> obtenerSolicitudesDisponibles() {
    return remoteDataSource.obtenerSolicitudesDisponibles();
  }

  @override
  Future<SolicitudViaje> actualizarEstado(String id, EstadoSolicitud estado) {
    return remoteDataSource.actualizarEstado(id, estado);
  }

  @override
  Future<void> cancelarSolicitud(String id) {
    return remoteDataSource.cancelarSolicitud(id);
  }
}
