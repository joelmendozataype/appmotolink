import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';

class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    required super.nombre,
    required super.correo,
    required super.contrasena,
    required super.rol,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      // El backend nunca devuelve la contraseña (write_only); no se necesita
      // tras la autenticación, así que se rellena vacía si no viene.
      contrasena: json['contrasena'] as String? ?? '',
      rol: RolUsuario.values.byName(json['rol'] as String),
    );
  }

  /// Envuelve una entidad para poder serializarla (guardar la sesión).
  factory UsuarioModel.fromEntity(Usuario usuario) {
    return UsuarioModel(
      id: usuario.id,
      nombre: usuario.nombre,
      correo: usuario.correo,
      contrasena: usuario.contrasena,
      rol: usuario.rol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'rol': rol.name,
    };
  }
}
