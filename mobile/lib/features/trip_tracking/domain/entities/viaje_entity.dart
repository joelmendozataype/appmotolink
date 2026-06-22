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

  const Viaje({
    required this.id,
    required this.pasajero,
    required this.conductor,
    required this.tarifaFinal,
    required this.estado,
  });

  @override
  List<Object?> get props => [id, pasajero, conductor, tarifaFinal, estado];
}
