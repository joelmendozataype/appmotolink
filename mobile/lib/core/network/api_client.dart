import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';

/// Cliente HTTP hacia el backend Django/DRF.
///
/// DRF expone todas sus rutas con barra final (DefaultRouter); por eso
/// [_uri] siempre la agrega. La sesión se sostiene manualmente: el backend
/// autentica por cookie de sesión (ver core.authentication en Django), y
/// package:http no trae un cookie jar propio, así que [ApiClient] guarda
/// la cookie recibida en el login y la reenvía en cada request siguiente.
class ApiClient {
  final http.Client _client;
  String? _sessionCookie;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

  Uri _uri(String path) {
    final queryIndex = path.indexOf('?');
    if (queryIndex == -1) {
      final withSlash = path.endsWith('/') ? path : '$path/';
      return Uri.parse('${ApiConstants.baseUrl}$withSlash');
    }
    final base = path.substring(0, queryIndex);
    final query = path.substring(queryIndex);
    final withSlash = base.endsWith('/') ? base : '$base/';
    return Uri.parse('${ApiConstants.baseUrl}$withSlash$query');
  }

  void _capturarCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      _sessionCookie = setCookie.split(';').first;
    }
  }

  /// La cookie de sesión vigente, para poder guardarla entre arranques.
  String? get sessionCookie => _sessionCookie;

  /// Restaura una cookie guardada en un arranque anterior.
  void restaurarSesion(String cookie) {
    _sessionCookie = cookie;
  }

  void cerrarSesion() {
    _sessionCookie = null;
  }

  dynamic _decode(http.Response response) {
    _capturarCookie(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ServerException(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  /// Tope de espera por petición.
  ///
  /// Generoso a propósito: el backend corre en un plan gratuito que
  /// suspende la instancia por inactividad, y despertarla ronda el minuto.
  /// Sin este tope, `package:http` espera indefinidamente y la pantalla se
  /// queda girando sin decir nada — que es exactamente lo que pasaba.
  static const Duration _espera = Duration(seconds: 90);

  /// Envuelve cada llamada para que ningún fallo de red quede mudo.
  Future<dynamic> _enviar(Future<http.Response> Function() peticion) async {
    try {
      return _decode(await peticion().timeout(_espera));
    } on TimeoutException {
      throw NetworkException(
        'El servidor tardó demasiado en responder. Puede estar despertando; '
        'espera unos segundos y vuelve a intentarlo.',
      );
    } on SocketException {
      throw NetworkException(
        'No se pudo conectar con el servidor. Revisa tu conexión a internet.',
      );
    } on http.ClientException {
      throw NetworkException(
        'Se interrumpió la conexión con el servidor. Intenta de nuevo.',
      );
    }
  }

  Future<dynamic> get(String path) =>
      _enviar(() => _client.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) => _enviar(
        () => _client.post(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body),
        ),
      );

  Future<dynamic> put(String path, Map<String, dynamic> body) => _enviar(
        () => _client.put(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body),
        ),
      );

  Future<dynamic> delete(String path) =>
      _enviar(() => _client.delete(_uri(path), headers: _headers));

  /// DELETE con cuerpo. Lo necesita la baja de dispositivos, que envía el
  /// token a borrar; el resto de bajas identifican el recurso por la URL.
  Future<dynamic> deleteConCuerpo(String path, Map<String, dynamic> body) =>
      _enviar(
        () => _client.delete(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body),
        ),
      );
}
