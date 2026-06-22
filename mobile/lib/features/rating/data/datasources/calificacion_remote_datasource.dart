import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/rating/data/models/calificacion_model.dart';

abstract class CalificacionRemoteDataSource {
  Future<CalificacionModel> enviar(String viajeId, int puntuacion, String comentario);
}

class CalificacionRemoteDataSourceImpl implements CalificacionRemoteDataSource {
  final ApiClient client;

  CalificacionRemoteDataSourceImpl(this.client);

  @override
  Future<CalificacionModel> enviar(
    String viajeId,
    int puntuacion,
    String comentario,
  ) async {
    final json = await client.post(ApiConstants.calificaciones, {
      'viaje': viajeId,
      'puntuacion': puntuacion,
      'comentario': comentario,
    });
    return CalificacionModel.fromJson(json as Map<String, dynamic>);
  }
}
