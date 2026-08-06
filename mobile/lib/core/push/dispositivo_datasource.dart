import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/api_client.dart';

/// Alta y baja del dispositivo en el backend, para las notificaciones.
///
/// El backend asocia el token al usuario de la sesión, nunca a un id que
/// venga en el cuerpo: así nadie puede desviar las notificaciones de otra
/// persona a su propio teléfono.
class DispositivoDataSource {
  final ApiClient client;

  const DispositivoDataSource(this.client);

  Future<void> registrar(String token) async {
    await client.post(ApiConstants.dispositivos, {'token': token});
  }

  Future<void> darDeBaja(String token) async {
    await client.deleteConCuerpo(ApiConstants.dispositivos, {'token': token});
  }
}
