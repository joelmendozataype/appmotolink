import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/validaciones.dart';

void main() {
  group('contrasena', () {
    test('acepta una razonable', () {
      expect(Validaciones.contrasena('MotoLink2026'), isNull);
    });

    test('rechaza vacía', () {
      expect(Validaciones.contrasena(''), 'Ingresa una contraseña');
      expect(Validaciones.contrasena(null), 'Ingresa una contraseña');
    });

    test('rechaza menos de 8 caracteres', () {
      // Las pantallas de registro pedían 4 mientras el backend exigía 8:
      // la app daba por buena una contraseña que el servidor rechazaba.
      expect(Validaciones.contrasena('clave12'), 'Mínimo 8 caracteres');
    });

    test('rechaza solo números', () {
      expect(Validaciones.contrasena('12345678'), isNotNull);
    });

    test('rechaza las más comunes', () {
      expect(Validaciones.contrasena('password'),
          'Esa contraseña es demasiado común');
      expect(Validaciones.contrasena('PASSWORD'),
          'Esa contraseña es demasiado común');
    });

    test('el mínimo coincide con el del backend', () {
      // Si algún día cambia en Django, este número debe seguirlo.
      expect(Validaciones.longitudMinimaContrasena, 8);
    });
  });
}
