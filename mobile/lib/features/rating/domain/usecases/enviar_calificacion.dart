import 'package:mobile/features/rating/domain/entities/calificacion_entity.dart';
import 'package:mobile/features/rating/domain/repositories/calificacion_repository.dart';

class EnviarCalificacion {
  final CalificacionRepository repository;

  EnviarCalificacion(this.repository);

  Future<Calificacion> call(String viajeId, int puntuacion, String comentario) {
    return repository.enviar(viajeId, puntuacion, comentario);
  }
}
