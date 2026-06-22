import 'package:mobile/features/trip_history/domain/entities/historial_entity.dart';
import 'package:mobile/features/trip_tracking/data/models/viaje_model.dart';

class HistorialModel extends Historial {
  const HistorialModel({
    required super.id,
    required super.viajes,
  });

  factory HistorialModel.fromJson(Map<String, dynamic> json) {
    return HistorialModel(
      id: json['id'] as String,
      viajes: (json['viajes'] as List<dynamic>)
          .map((v) => ViajeModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'viajes': viajes
          .map((v) => ViajeModel(
                id: v.id,
                pasajero: v.pasajero,
                conductor: v.conductor,
                tarifaFinal: v.tarifaFinal,
                estado: v.estado,
              ).toJson())
          .toList(),
    };
  }
}
