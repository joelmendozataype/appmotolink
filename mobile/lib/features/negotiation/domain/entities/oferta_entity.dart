import 'package:equatable/equatable.dart';
import 'package:mobile/core/enums/estado_oferta.dart';
import 'package:mobile/core/enums/tipo_oferta.dart';
import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';

class Oferta extends Equatable {
  final String id;
  final Mototaxista conductor;
  final double tarifa;
  final TipoOferta tipo;
  final EstadoOferta estado;
  final DateTime fecha;

  const Oferta({
    required this.id,
    required this.conductor,
    required this.tarifa,
    required this.tipo,
    required this.estado,
    required this.fecha,
  });

  @override
  List<Object?> get props => [id, conductor, tarifa, tipo, estado, fecha];
}
