import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/negotiation/data/models/oferta_model.dart';
import 'package:mobile/features/trip_tracking/data/models/viaje_model.dart';

/// Contrato real del backend (trips.presentation.views.SolicitudViajeViewSet
/// y negotiation.presentation.views.OfertaViewSet):
///   POST /solicitudes-viaje/{id}/aceptar/        {conductor_id}          -> Oferta
///   POST /solicitudes-viaje/{id}/contraofertar/  {conductor_id, tarifa}  -> Oferta
///   POST /solicitudes-viaje/{id}/rechazar/       {conductor_id}          -> Oferta
///   GET  /solicitudes-viaje/{id}/ofertas/                                -> lista de Oferta
///   POST /ofertas/{id}/seleccionar/                                      -> Viaje
abstract class OfertaRemoteDataSource {
  Future<OfertaModel> aceptarSolicitud(String solicitudId, String conductorId);

  Future<OfertaModel> contraofertarSolicitud(
    String solicitudId,
    String conductorId,
    double tarifa,
  );

  Future<OfertaModel> rechazarSolicitud(String solicitudId, String conductorId);

  Future<List<OfertaModel>> obtenerOfertas(String solicitudId);

  Future<ViajeModel> seleccionarOferta(String ofertaId);
}

class OfertaRemoteDataSourceImpl implements OfertaRemoteDataSource {
  final ApiClient client;

  OfertaRemoteDataSourceImpl(this.client);

  @override
  Future<OfertaModel> aceptarSolicitud(
    String solicitudId,
    String conductorId,
  ) async {
    final json = await client.post(
      '${ApiConstants.solicitudesViaje}/$solicitudId/aceptar',
      {'conductor_id': conductorId},
    );
    return OfertaModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<OfertaModel> contraofertarSolicitud(
    String solicitudId,
    String conductorId,
    double tarifa,
  ) async {
    final json = await client.post(
      '${ApiConstants.solicitudesViaje}/$solicitudId/contraofertar',
      {'conductor_id': conductorId, 'tarifa': tarifa},
    );
    return OfertaModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<OfertaModel> rechazarSolicitud(
    String solicitudId,
    String conductorId,
  ) async {
    final json = await client.post(
      '${ApiConstants.solicitudesViaje}/$solicitudId/rechazar',
      {'conductor_id': conductorId},
    );
    return OfertaModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<OfertaModel>> obtenerOfertas(String solicitudId) async {
    final json = await client.get(
      '${ApiConstants.solicitudesViaje}/$solicitudId/ofertas',
    );
    return (json as List<dynamic>)
        .map((e) => OfertaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ViajeModel> seleccionarOferta(String ofertaId) async {
    final json = await client.post(
      '${ApiConstants.ofertas}/$ofertaId/seleccionar',
      {},
    );
    return ViajeModel.fromJson(json as Map<String, dynamic>);
  }
}
