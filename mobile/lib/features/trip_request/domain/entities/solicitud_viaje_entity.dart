import 'package:equatable/equatable.dart';
import 'package:mobile/core/enums/estado_solicitud.dart';

class SolicitudViaje extends Equatable {
  final String id;
  final String origen;
  final String destino;
  final double tarifaPropuesta;
  final EstadoSolicitud estado;

  /// Cuándo se pidió. Null en las migradas desde la base anterior, que no
  /// guardaba fechas.
  final DateTime? creadoEn;

  /// Si el mototaxista que consulta ya respondió a esta solicitud.
  ///
  /// Null cuando la pregunta no aplica —por ejemplo, si quien mira es un
  /// pasajero—, que no es lo mismo que "no ha respondido".
  final bool? yaRespondida;

  const SolicitudViaje({
    required this.id,
    required this.origen,
    required this.destino,
    required this.tarifaPropuesta,
    required this.estado,
    this.creadoEn,
    this.yaRespondida,
  });

  @override
  List<Object?> get props =>
      [id, origen, destino, tarifaPropuesta, estado, creadoEn, yaRespondida];
}
