import 'package:mobile/features/rating/domain/entities/calificacion_entity.dart';

class CalificacionModel extends Calificacion {
  const CalificacionModel({
    required super.id,
    required super.viajeId,
    required super.puntuacion,
    required super.comentario,
  });

  factory CalificacionModel.fromJson(Map<String, dynamic> json) {
    return CalificacionModel(
      id: json['id'] as String,
      viajeId: json['viaje'] as String,
      puntuacion: json['puntuacion'] as int,
      comentario: json['comentario'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viaje': viajeId,
      'puntuacion': puntuacion,
      'comentario': comentario,
    };
  }
}
