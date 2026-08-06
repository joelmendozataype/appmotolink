class ApiConstants {
  /// URL del backend. Por defecto apunta al servicio publicado en Render,
  /// que es lo que necesita el APK que se reparte al equipo.
  ///
  /// Para desarrollar contra un backend local no hace falta editar este
  /// archivo, basta con pasar la URL al compilar:
  ///
  ///   flutter run --dart-define=MOTOLINK_API_URL=http://localhost:8000
  ///
  /// Ojo con la máquina de destino: `localhost` solo sirve para web y
  /// escritorio. Dentro del emulador Android el host es 10.0.2.2, y en un
  /// teléfono físico hay que usar la IP de la máquina en la red local.
  static const String _host = String.fromEnvironment(
    'MOTOLINK_API_URL',
    defaultValue: 'https://motolink-api-arja.onrender.com',
  );

  static const String baseUrl = '$_host/api';
  static const String socketUrl = _host;

  static const String usuarios = '/usuarios';
  static const String login = '/usuarios/login';
  static const String mototaxistas = '/mototaxistas';
  static const String solicitudesViaje = '/solicitudes-viaje';
  static const String ofertas = '/ofertas';
  static const String viajes = '/viajes';
  static const String historial = '/historial';
  static const String calificaciones = '/calificaciones';
}
