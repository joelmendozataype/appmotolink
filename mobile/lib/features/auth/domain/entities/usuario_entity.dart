import 'package:equatable/equatable.dart';
import 'package:mobile/core/enums/rol_usuario.dart';

class Usuario extends Equatable {
  final String id;
  final String nombre;
  final String correo;
  final String contrasena;
  final RolUsuario rol;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.rol,
  });

  @override
  List<Object?> get props => [id, nombre, correo, contrasena, rol];
}
