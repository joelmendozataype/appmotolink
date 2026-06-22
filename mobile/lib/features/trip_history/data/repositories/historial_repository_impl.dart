import 'package:mobile/features/trip_history/data/datasources/historial_remote_datasource.dart';
import 'package:mobile/features/trip_history/domain/entities/historial_entity.dart';
import 'package:mobile/features/trip_history/domain/repositories/historial_repository.dart';

class HistorialRepositoryImpl implements HistorialRepository {
  final HistorialRemoteDataSource remoteDataSource;

  HistorialRepositoryImpl(this.remoteDataSource);

  @override
  Future<Historial> obtenerHistorial(String usuarioId) {
    return remoteDataSource.obtenerHistorial(usuarioId);
  }
}
