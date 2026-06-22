import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/enums/estado_viaje.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/trip_tracking/data/models/viaje_model.dart';

/// El Viaje no se crea directamente desde el móvil: nace en el backend
/// cuando el pasajero selecciona una oferta (ver OfertaRemoteDataSource.
/// seleccionarOferta). Este datasource solo consulta/actualiza el viaje
/// ya creado.
abstract class ViajeRemoteDataSource {
  Future<ViajeModel> obtenerPorId(String viajeId);
  Future<ViajeModel> obtenerViajeActivo(String usuarioId);
  Future<ViajeModel> actualizarEstado(String viajeId, EstadoViaje estado);
  Future<ViajeModel> finalizarViaje(String viajeId);
  Future<List<ViajeModel>> listarTodos();
}

class ViajeRemoteDataSourceImpl implements ViajeRemoteDataSource {
  final ApiClient client;

  ViajeRemoteDataSourceImpl(this.client);

  @override
  Future<ViajeModel> obtenerPorId(String viajeId) async {
    final json = await client.get('${ApiConstants.viajes}/$viajeId');
    return ViajeModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<ViajeModel> obtenerViajeActivo(String usuarioId) async {
    final json = await client.get(
      '${ApiConstants.viajes}/activo?usuarioId=$usuarioId',
    );
    return ViajeModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<ViajeModel> actualizarEstado(
    String viajeId,
    EstadoViaje estado,
  ) async {
    final json = await client.put(
      '${ApiConstants.viajes}/$viajeId',
      {'estado': estado.name},
    );
    return ViajeModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<ViajeModel> finalizarViaje(String viajeId) async {
    final json = await client.put(
      '${ApiConstants.viajes}/$viajeId/finalizar',
      {},
    );
    return ViajeModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<ViajeModel>> listarTodos() async {
    final json = await client.get(ApiConstants.viajes);
    return (json as List<dynamic>)
        .map((e) => ViajeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
