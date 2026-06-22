import 'package:equatable/equatable.dart';
import 'package:mobile/core/enums/estado_solicitud.dart';

class SolicitudViaje extends Equatable {
  final String id;
  final String origen;
  final String destino;
  final double tarifaPropuesta;
  final EstadoSolicitud estado;

  const SolicitudViaje({
    required this.id,
    required this.origen,
    required this.destino,
    required this.tarifaPropuesta,
    required this.estado,
  });

  @override
  List<Object?> get props => [id, origen, destino, tarifaPropuesta, estado];
}
