import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/validaciones.dart';

void main() {
  group('tarifa', () {
    test('acepta enteros y decimales', () {
      expect(Validaciones.tarifa('5'), isNull);
      expect(Validaciones.tarifa('12.50'), isNull);
      expect(Validaciones.tarifa('7.5'), isNull);
    });

    test('acepta el mínimo de S/ 1', () {
      expect(Validaciones.tarifa('1'), isNull);
      expect(Validaciones.tarifa('1.00'), isNull);
    });

    test('rechaza el cero y lo que baje de S/ 1', () {
      // Un viaje gratis no es una tarifa, y la solicitud llegaba igual a
      // todos los mototaxistas.
      const minimo = 'La tarifa mínima es S/ 1';
      expect(Validaciones.tarifa('0'), minimo);
      expect(Validaciones.tarifa('0.00'), minimo);
      expect(Validaciones.tarifa('0.99'), minimo);
    });

    test('rechaza vacío', () {
      expect(Validaciones.tarifa(''), 'Ingresa una tarifa');
      expect(Validaciones.tarifa(null), 'Ingresa una tarifa');
    });

    test('rechaza negativos', () {
      expect(Validaciones.tarifa('-5'), 'La tarifa mínima es S/ 1');
    });

    test('rechaza texto', () {
      expect(Validaciones.tarifa('abc'), 'Escribe solo números');
      expect(Validaciones.tarifa('5 soles'), 'Escribe solo números');
    });

    test('rechaza más de dos decimales', () {
      // En soles, el tercer decimal no significa nada.
      expect(Validaciones.tarifa('5.999'), 'Como mucho dos decimales');
    });
  });

  group('lugar', () {
    String? origen(String? v) => Validaciones.lugar(v, campo: 'el origen');

    test('acepta nombres de sitios reales', () {
      expect(origen('Ahuaycha'), isNull);
      expect(origen('Plaza de Pampas'), isNull);
      expect(origen('Jr. Grau 123'), isNull);
      expect(origen('Av. Los Andes Mz. B'), isNull);
    });

    test('acepta las coordenadas que escribe el GPS', () {
      // Si se rechazaran, el botón de ubicación rellenaría el campo con
      // algo que la propia validación da por inválido.
      expect(origen('-12.39031, -74.85911'), isNull);
      expect(origen('-12.39031,-74.85911'), isNull);
    });

    test('rechaza vacío', () {
      expect(origen(''), 'Ingresa el origen');
      expect(origen('   '), 'Ingresa el origen');
      expect(
        Validaciones.lugar('', campo: 'el destino'),
        'Ingresa el destino',
      );
    });

    test('rechaza lo tecleado al azar', () {
      // Los dos casos que aparecieron en una prueba real.
      expect(origen('.,mnhfg_#'), 'Usa solo letras, números y espacios');
      expect(origen('SX:::S:'), 'Usa solo letras, números y espacios');
    });

    test('rechaza lo que no nombra ningún sitio', () {
      expect(origen('123456'), 'Escribe el nombre del lugar');
      expect(origen('ab'), 'Escribe al menos 3 caracteres');
    });
  });

  group('nombre', () {
    test('acepta nombres normales', () {
      expect(Validaciones.nombre('Joel Mendoza Taype'), isNull);
      expect(Validaciones.nombre('Ana'), isNull);
    });

    test('acepta tildes y eñe', () {
      // Son letras corrientes en los nombres de aquí: si se rechazaran,
      // media Tayacaja no podría registrarse.
      expect(Validaciones.nombre('José Ñahui Muñoz'), isNull);
      expect(Validaciones.nombre('María Ángeles'), isNull);
    });

    test('rechaza vacío o solo espacios', () {
      expect(Validaciones.nombre(''), 'Ingresa tu nombre');
      expect(Validaciones.nombre(null), 'Ingresa tu nombre');
      expect(Validaciones.nombre('    '), 'Ingresa tu nombre');
    });

    test('rechaza números', () {
      expect(Validaciones.nombre('Juan123'), 'El nombre no puede tener números');
      expect(Validaciones.nombre('12345'), 'El nombre no puede tener números');
    });

    test('rechaza signos', () {
      expect(Validaciones.nombre('Juan@Perez'), 'Usa solo letras y espacios');
      expect(Validaciones.nombre('Juan_Perez'), 'Usa solo letras y espacios');
      expect(Validaciones.nombre('<script>'), 'Usa solo letras y espacios');
    });

    test('recorta los espacios de los extremos', () {
      expect(Validaciones.nombre('  Joel Mendoza  '), isNull);
    });

    test('rechaza una sola letra', () {
      expect(Validaciones.nombre('J'), 'Escribe tu nombre completo');
    });
  });

  group('correo', () {
    test('acepta uno normal', () {
      expect(Validaciones.correo('prueba.pasajero@motolink.com'), isNull);
      expect(Validaciones.correo('joel_23@gmail.com'), isNull);
      expect(Validaciones.correo('a+b@sub.dominio.pe'), isNull);
    });

    test('rechaza vacío', () {
      expect(Validaciones.correo(''), 'Ingresa tu correo');
      expect(Validaciones.correo(null), 'Ingresa tu correo');
      expect(Validaciones.correo('   '), 'Ingresa tu correo');
    });

    test('rechaza texto sin arroba', () {
      // El caso que se coló en una prueba real: el campo lo daba por bueno
      // y el error solo llegaba desde el servidor.
      expect(Validaciones.correo('12332werrd'),
          'Falta el @ (ejemplo: tucorreo@gmail.com)');
    });

    test('rechaza direcciones incompletas', () {
      const invalido = 'Correo no válido (ejemplo: tucorreo@gmail.com)';
      expect(Validaciones.correo('@gmail.com'), invalido); // sin usuario
      expect(Validaciones.correo('juan@'), invalido); // sin dominio
      expect(Validaciones.correo('juan@gmail'), invalido); // sin punto
      expect(Validaciones.correo('juan perez@gmail.com'), invalido); // espacio
      expect(Validaciones.correo('juan@@gmail.com'), invalido);
    });

    test('ignora los espacios de los extremos', () {
      // El teclado del móvil añade uno al autocompletar.
      expect(Validaciones.correo('  juan@gmail.com  '), isNull);
    });
  });

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
