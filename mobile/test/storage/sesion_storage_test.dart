import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/storage/almacen_seguro.dart';
import 'package:mobile/core/storage/sesion_storage.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';

void main() {
  late AlmacenSeguroEnMemoria almacen;
  late SesionStorage sesion;

  const usuario = Usuario(
    id: 'u-1',
    nombre: 'Ana Torres',
    correo: 'ana@motolink.com',
    contrasena: 'no-deberia-guardarse',
    rol: RolUsuario.pasajero,
  );

  setUp(() {
    almacen = AlmacenSeguroEnMemoria();
    sesion = SesionStorage(storage: almacen);
  });

  test('guarda y recupera la sesión completa', () async {
    await sesion.guardar(cookie: 'sessionid=abc123', usuario: usuario);

    expect(await sesion.leerCookie(), 'sessionid=abc123');
    final recuperado = await sesion.leerUsuario();
    expect(recuperado?.correo, 'ana@motolink.com');
    expect(recuperado?.rol, RolUsuario.pasajero);
  });

  test('nunca persiste la contraseña', () async {
    await sesion.guardar(cookie: 'c', usuario: usuario);

    expect(almacen.datos.values.join(' ').contains('no-deberia-guardarse'),
        isFalse);
    final guardado =
        jsonDecode(almacen.datos['motolink.sesion.usuario']!) as Map;
    expect(guardado.containsKey('contrasena'), isFalse);
  });

  test('sin sesión guardada devuelve null en vez de fallar', () async {
    expect(await sesion.leerCookie(), isNull);
    expect(await sesion.leerUsuario(), isNull);
  });

  test('limpiar borra las dos claves', () async {
    await sesion.guardar(cookie: 'c', usuario: usuario);
    await sesion.limpiar();

    expect(await sesion.leerCookie(), isNull);
    expect(await sesion.leerUsuario(), isNull);
    expect(almacen.datos, isEmpty);
  });

  test('un dato corrupto se descarta en vez de romper cada arranque',
      () async {
    await sesion.guardar(cookie: 'c', usuario: usuario);
    // Simula un formato viejo o un guardado a medias.
    almacen.datos['motolink.sesion.usuario'] = '{esto no es json';

    expect(await sesion.leerUsuario(), isNull);
    // Y además se limpia, para no repetir el fallo en el siguiente arranque.
    expect(almacen.datos, isEmpty);
  });
}
