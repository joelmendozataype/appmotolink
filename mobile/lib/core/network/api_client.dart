import 'dart:convert';

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

  Future<dynamic> get(String path) async {
    final response = await _client.get(_uri(path), headers: _headers);
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _client.delete(_uri(path), headers: _headers);
    return _decode(response);
  }
}
