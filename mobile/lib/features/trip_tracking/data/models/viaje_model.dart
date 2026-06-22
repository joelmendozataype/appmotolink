import 'package:mobile/core/enums/estado_viaje.dart';
import 'package:mobile/features/auth/data/models/usuario_model.dart';
import 'package:mobile/features/profile/data/models/mototaxista_model.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';

class ViajeModel extends Viaje {
  const ViajeModel({
    required super.id,
    required super.pasajero,
    required super.conductor,
    required super.tarifaFinal,
    required super.estado,
  });

  factory ViajeModel.fromJson(Map<String, dynamic> json) {
    return ViajeModel(
      id: json['id'] as String,
      pasajero:
          UsuarioModel.fromJson(json['pasajero'] as Map<String, dynamic>),
      conductor:
          MototaxistaModel.fromJson(json['conductor'] as Map<String, dynamic>),
      tarifaFinal: (json['tarifa_final'] as num).toDouble(),
      estado: EstadoViaje.values.byName(json['estado'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pasajero': UsuarioModel(
        id: pasajero.id,
        nombre: pasajero.nombre,
        correo: pasajero.correo,
        contrasena: pasajero.contrasena,
        rol: pasajero.rol,
      ).toJson(),
      'conductor': MototaxistaModel(
        usuario: conductor.usuario,
        licencia: conductor.licencia,
        placa: conductor.placa,
        marcaVehiculo: conductor.marcaVehiculo,
        modeloVehiculo: conductor.modeloVehiculo,
      ).toJson(),
      'tarifa_final': tarifaFinal,
      'estado': estado.name,
    };
  }
}
