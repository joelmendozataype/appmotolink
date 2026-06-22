import 'package:equatable/equatable.dart';

class Calificacion extends Equatable {
  final String id;
  final String viajeId;
  final int puntuacion;
  final String comentario;

  const Calificacion({
    required this.id,
    required this.viajeId,
    required this.puntuacion,
    required this.comentario,
  });

  @override
  List<Object?> get props => [id, viajeId, puntuacion, comentario];
}
