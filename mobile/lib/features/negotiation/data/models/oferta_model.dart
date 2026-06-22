import 'package:mobile/core/enums/estado_oferta.dart';
import 'package:mobile/core/enums/tipo_oferta.dart';
import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';
import 'package:mobile/features/profile/data/models/mototaxista_model.dart';

class OfertaModel extends Oferta {
  const OfertaModel({
    required super.id,
    required super.conductor,
    required super.tarifa,
    required super.tipo,
    required super.estado,
    required super.fecha,
  });

  factory OfertaModel.fromJson(Map<String, dynamic> json) {
    return OfertaModel(
      id: json['id'] as String,
      conductor:
          MototaxistaModel.fromJson(json['conductor'] as Map<String, dynamic>),
      tarifa: (json['tarifa'] as num).toDouble(),
      tipo: TipoOferta.values.byName(json['tipo'] as String),
      estado: EstadoOferta.values.byName(json['estado'] as String),
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }
}
