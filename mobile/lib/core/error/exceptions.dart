class ServerException implements Exception {
  final String message;

  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

/// El backend no respondió: sin internet, servidor caído, o tardando más
/// de la cuenta.
///
/// Se distingue de [ServerException] porque no es lo mismo "el servidor
/// dijo que no" que "el servidor no dijo nada": el segundo caso suele
/// resolverse reintentando.
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Extrae el mensaje "detail" que DRF incluye en sus respuestas de error
/// (ej. 409 Conflict) para mostrarlo directamente al usuario; si no hay uno
/// reconocible, cae a un mensaje genérico en vez de mostrar el JSON crudo.
String mensajeDeError(Object error) {
  if (error is NetworkException) return error.message;
  if (error is ServerException) {
    final match = RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(error.message);
    if (match != null) return match.group(1)!;
  }
  return 'Ocurrió un problema de conexión. Intenta de nuevo.';
}
