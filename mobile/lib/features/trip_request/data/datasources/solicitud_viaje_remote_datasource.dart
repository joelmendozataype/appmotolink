import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/trip_request/data/models/solicitud_viaje_model.dart';

abstract class SolicitudViajeRemoteDataSource {
  Future<SolicitudViajeModel> crearSolicitud(
    SolicitudViajeModel solicitud,
    String pasajeroId,
  );
  Future<SolicitudViajeModel> obtenerSolicitud(String id);
  Future<List<SolicitudViajeModel>> obtenerSolicitudesDisponibles();
  Future<SolicitudViajeModel> actualizarEstado(
    String id,
    EstadoSolicitud estado,
  );
  Future<SolicitudViajeModel> cancelarSolicitud(String id);
}

class SolicitudViajeRemoteDataSourceImpl
    implements SolicitudViajeRemoteDataSource {
  final ApiClient client;

  SolicitudViajeRemoteDataSourceImpl(this.client);

  @override
  Future<SolicitudViajeModel> crearSolicitud(
    SolicitudViajeModel solicitud,
    String pasajeroId,
  ) async {
    final body = solicitud.toJson()..['pasajero'] = pasajeroId;
    final json = await client.post(ApiConstants.solicitudesViaje, body);
    return SolicitudViajeModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<SolicitudViajeModel> obtenerSolicitud(String id) async {
    final json = await client.get('${ApiConstants.solicitudesViaje}/$id');
    return SolicitudViajeModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<SolicitudViajeModel>> obtenerSolicitudesDisponibles() async {
    final json = await client.get(ApiConstants.solicitudesViaje);
    return (json as List<dynamic>)
        .map((e) => SolicitudViajeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SolicitudViajeModel> actualizarEstado(
    String id,
    EstadoSolicitud estado,
  ) async {
    final json = await client.put(
      '${ApiConstants.solicitudesViaje}/$id',
      {'estado': estado.name},
    );
    return SolicitudViajeModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<SolicitudViajeModel> cancelarSolicitud(String id) async {
    // POST /cancelar/ y no DELETE: la solicitud queda en estado
    // 'cancelada' en vez de desaparecer, para que el conductor que ya
    // ofertó vea qué pasó y siga contando en el historial.
    final json = await client.post(
      '${ApiConstants.solicitudesViaje}/$id/cancelar',
      {},
    );
    return SolicitudViajeModel.fromJson(json as Map<String, dynamic>);
  }
}
