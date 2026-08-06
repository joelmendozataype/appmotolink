import 'package:equatable/equatable.dart';
import 'package:mobile/core/enums/estado_viaje.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';

class Viaje extends Equatable {
  final String id;
  final Usuario pasajero;
  final Mototaxista conductor;
  final double tarifaFinal;
  final EstadoViaje estado;

  /// Cuándo se asignó el viaje. Es null en los viajes migrados desde la
  /// base anterior, que no guardaba fechas.
  final DateTime? creadoEn;

  /// Cuándo se cerró. Null mientras siga en curso.
  final DateTime? finalizadoEn;

  /// Duración en minutos, calculada por el backend. Null si el viaje no
  /// ha terminado o si le faltan fechas.
  final int? duracionMinutos;

  const Viaje({
    required this.id,
    required this.pasajero,
    required this.conductor,
    required this.tarifaFinal,
    required this.estado,
    this.creadoEn,
    this.finalizadoEn,
    this.duracionMinutos,
  });

  @override
  List<Object?> get props => [
        id,
        pasajero,
        conductor,
        tarifaFinal,
        estado,
        creadoEn,
        finalizadoEn,
        duracionMinutos,
      ];
}
