import 'package:mobile/features/rating/data/datasources/calificacion_remote_datasource.dart';
import 'package:mobile/features/rating/domain/entities/calificacion_entity.dart';
import 'package:mobile/features/rating/domain/repositories/calificacion_repository.dart';

class CalificacionRepositoryImpl implements CalificacionRepository {
  final CalificacionRemoteDataSource remoteDataSource;

  CalificacionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Calificacion> enviar(
    String viajeId,
    int puntuacion,
    String comentario,
  ) {
    return remoteDataSource.enviar(viajeId, puntuacion, comentario);
  }
}
