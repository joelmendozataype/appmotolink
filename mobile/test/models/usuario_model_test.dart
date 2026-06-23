import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/features/auth/data/models/usuario_model.dart';

void main() {
  group('UsuarioModel.fromJson', () {
    // El serializer del backend marca "contrasena" como write_only: nunca
    // la devuelve. Un bug real de esta app crasheaba aquí con
    // `json['contrasena'] as String` (cast de null) en cada login/registro.
    test('no crashea cuando el backend omite la contraseña', () {
      final json = {
        'id': 'u-1',
        'nombre': 'María',
        'correo': 'maria@motolink.com',
        'rol': 'pasajero',
      };

      final usuario = UsuarioModel.fromJson(json);

      expect(usuario.contrasena, '');
      expect(usuario.nombre, 'María');
      expect(usuario.rol, RolUsuario.pasajero);
    });

    test('parsea los tres roles válidos', () {
      for (final rol in ['pasajero', 'mototaxista', 'administrador']) {
        final usuario = UsuarioModel.fromJson({
          'id': 'u-1',
          'nombre': 'Test',
          'correo': 'test@motolink.com',
          'rol': rol,
        });
        expect(usuario.rol.name, rol);
      }
    });
  });

  group('UsuarioModel.toJson', () {
    test('serializa todos los campos', () {
      const usuario = UsuarioModel(
        id: 'u-1',
        nombre: 'María',
        correo: 'maria@motolink.com',
        contrasena: 'clave123',
        rol: RolUsuario.pasajero,
      );

      final json = usuario.toJson();

      expect(json['id'], 'u-1');
      expect(json['correo'], 'maria@motolink.com');
      expect(json['rol'], 'pasajero');
    });
  });
}
