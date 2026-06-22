import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/profile/data/models/mototaxista_model.dart';

abstract class MototaxistaRemoteDataSource {
  Future<MototaxistaModel> obtenerPerfil(String usuarioId);
  Future<MototaxistaModel> registrarPerfil(MototaxistaModel mototaxista);
  Future<MototaxistaModel> actualizarPerfil(MototaxistaModel mototaxista);
  Future<List<MototaxistaModel>> listarTodos();
}

class MototaxistaRemoteDataSourceImpl implements MototaxistaRemoteDataSource {
  final ApiClient client;

  MototaxistaRemoteDataSourceImpl(this.client);

  @override
  Future<MototaxistaModel> obtenerPerfil(String usuarioId) async {
    final json = await client.get('${ApiConstants.mototaxistas}/$usuarioId');
    return MototaxistaModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<MototaxistaModel> registrarPerfil(
    MototaxistaModel mototaxista,
  ) async {
    // El id del usuario anidado lo asigna el backend; no se envía.
    final body = mototaxista.toJson();
    (body['usuario'] as Map<String, dynamic>).remove('id');
    final json = await client.post(ApiConstants.mototaxistas, body);
    return MototaxistaModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<MototaxistaModel> actualizarPerfil(
    MototaxistaModel mototaxista,
  ) async {
    final json = await client.put(
      '${ApiConstants.mototaxistas}/${mototaxista.usuario.id}',
      mototaxista.toJson(),
    );
    return MototaxistaModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<MototaxistaModel>> listarTodos() async {
    final json = await client.get(ApiConstants.mototaxistas);
    return (json as List<dynamic>)
        .map((e) => MototaxistaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
