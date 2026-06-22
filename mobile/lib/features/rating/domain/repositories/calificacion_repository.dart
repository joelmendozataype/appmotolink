import 'package:mobile/features/rating/domain/entities/calificacion_entity.dart';

abstract class CalificacionRepository {
  Future<Calificacion> enviar(String viajeId, int puntuacion, String comentario);
}
