import 'package:equatable/equatable.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';

class Historial extends Equatable {
  final String id;
  final List<Viaje> viajes;

  const Historial({
    required this.id,
    required this.viajes,
  });

  @override
  List<Object?> get props => [id, viajes];
}
