import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/trip_history/data/models/historial_model.dart';

abstract class HistorialRemoteDataSource {
  Future<HistorialModel> obtenerHistorial(String usuarioId);
}

class HistorialRemoteDataSourceImpl implements HistorialRemoteDataSource {
  final ApiClient client;

  HistorialRemoteDataSourceImpl(this.client);

  @override
  Future<HistorialModel> obtenerHistorial(String usuarioId) async {
    final json = await client.get(
      '${ApiConstants.historial}?usuarioId=$usuarioId',
    );
    return HistorialModel.fromJson(json as Map<String, dynamic>);
  }
}
