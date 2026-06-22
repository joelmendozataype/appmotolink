import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/auth/data/models/usuario_model.dart';

abstract class UsuarioRemoteDataSource {
  Future<UsuarioModel> login(String correo, String contrasena);
  Future<UsuarioModel> registrar(UsuarioModel usuario);
  Future<void> logout();
  Future<UsuarioModel> obtenerUsuarioActual();
  Future<UsuarioModel> actualizarUsuario(UsuarioModel usuario);
  Future<List<UsuarioModel>> listarTodos();
  Future<List<UsuarioModel>> listarPasajeros();
  Future<void> eliminarUsuario(String id);
}

class UsuarioRemoteDataSourceImpl implements UsuarioRemoteDataSource {
  final ApiClient client;

  UsuarioRemoteDataSourceImpl(this.client);

  @override
  Future<UsuarioModel> login(String correo, String contrasena) async {
    final json = await client.post(ApiConstants.login, {
      'correo': correo,
      'contrasena': contrasena,
    });
    return UsuarioModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<UsuarioModel> registrar(UsuarioModel usuario) async {
    // El id lo asigna el backend (UUID); no se envía en la creación.
    final body = usuario.toJson()..remove('id');
    final json = await client.post(ApiConstants.usuarios, body);
    return UsuarioModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await client.post('${ApiConstants.usuarios}/logout', {});
  }

  @override
  Future<UsuarioModel> obtenerUsuarioActual() async {
    final json = await client.get('${ApiConstants.usuarios}/me');
    return UsuarioModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<UsuarioModel> actualizarUsuario(UsuarioModel usuario) async {
    final json = await client.put(
      '${ApiConstants.usuarios}/${usuario.id}',
      usuario.toJson(),
    );
    return UsuarioModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<UsuarioModel>> listarTodos() async {
    final json = await client.get(ApiConstants.usuarios);
    return (json as List<dynamic>)
        .map((e) => UsuarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<UsuarioModel>> listarPasajeros() async {
    final json = await client.get('${ApiConstants.usuarios}/pasajeros');
    return (json as List<dynamic>)
        .map((e) => UsuarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> eliminarUsuario(String id) async {
    await client.delete('${ApiConstants.usuarios}/$id');
  }
}
