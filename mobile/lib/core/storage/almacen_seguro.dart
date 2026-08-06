import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento cifrado clave-valor, reducido a lo que MotoLink usa.
///
/// Existe esta interfaz en vez de depender directamente de
/// `FlutterSecureStorage` por dos motivos: los tests pueden sustituirla
/// por una versión en memoria sin tocar el keystore de Android, y los
/// cambios de API del paquete quedan confinados a un solo archivo (su
/// firma ya cambió una vez entre versiones).
abstract class AlmacenSeguro {
  Future<void> escribir(String clave, String valor);
  Future<String?> leer(String clave);
  Future<void> borrar(String clave);
}

class AlmacenSeguroFlutter implements AlmacenSeguro {
  final FlutterSecureStorage _storage;

  const AlmacenSeguroFlutter([
    this._storage = const FlutterSecureStorage(),
  ]);

  @override
  Future<void> escribir(String clave, String valor) =>
      _storage.write(key: clave, value: valor);

  @override
  Future<String?> leer(String clave) => _storage.read(key: clave);

  @override
  Future<void> borrar(String clave) => _storage.delete(key: clave);
}

/// Implementación en memoria, para tests.
class AlmacenSeguroEnMemoria implements AlmacenSeguro {
  final Map<String, String> datos = {};

  @override
  Future<void> escribir(String clave, String valor) async {
    datos[clave] = valor;
  }

  @override
  Future<String?> leer(String clave) async => datos[clave];

  @override
  Future<void> borrar(String clave) async {
    datos.remove(clave);
  }
}
