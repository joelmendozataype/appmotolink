import 'package:mobile/features/auth/data/models/usuario_model.dart';
import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';

class MototaxistaModel extends Mototaxista {
  const MototaxistaModel({
    required super.usuario,
    required super.licencia,
    required super.placa,
    required super.marcaVehiculo,
    required super.modeloVehiculo,
  });

  factory MototaxistaModel.fromJson(Map<String, dynamic> json) {
    return MototaxistaModel(
      usuario: UsuarioModel.fromJson(json['usuario'] as Map<String, dynamic>),
      licencia: json['licencia'] as String,
      placa: json['placa'] as String,
      marcaVehiculo: json['marca_vehiculo'] as String,
      modeloVehiculo: json['modelo_vehiculo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario': UsuarioModel(
        id: usuario.id,
        nombre: usuario.nombre,
        correo: usuario.correo,
        contrasena: usuario.contrasena,
        rol: usuario.rol,
      ).toJson(),
      'licencia': licencia,
      'placa': placa,
      'marca_vehiculo': marcaVehiculo,
      'modelo_vehiculo': modeloVehiculo,
    };
  }
}
