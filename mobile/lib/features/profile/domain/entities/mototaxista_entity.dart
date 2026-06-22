import 'package:equatable/equatable.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';

class Mototaxista extends Equatable {
  final Usuario usuario;
  final String licencia;
  final String placa;
  final String marcaVehiculo;
  final String modeloVehiculo;

  const Mototaxista({
    required this.usuario,
    required this.licencia,
    required this.placa,
    required this.marcaVehiculo,
    required this.modeloVehiculo,
  });

  @override
  List<Object?> get props => [
        usuario,
        licencia,
        placa,
        marcaVehiculo,
        modeloVehiculo,
      ];
}
