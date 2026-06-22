import 'package:mobile/core/enums/estado_solicitud.dart';
import 'package:mobile/features/trip_request/domain/entities/solicitud_viaje_entity.dart';

class SolicitudViajeModel extends SolicitudViaje {
  const SolicitudViajeModel({
    required super.id,
    required super.origen,
    required super.destino,
    required super.tarifaPropuesta,
    required super.estado,
  });

  factory SolicitudViajeModel.fromJson(Map<String, dynamic> json) {
    return SolicitudViajeModel(
      id: json['id'] as String,
      origen: json['origen'] as String,
      destino: json['destino'] as String,
      tarifaPropuesta: (json['tarifa_propuesta'] as num).toDouble(),
      estado: EstadoSolicitud.values.byName(json['estado'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origen': origen,
      'destino': destino,
      'tarifa_propuesta': tarifaPropuesta,
      'estado': estado.name,
    };
  }
}
