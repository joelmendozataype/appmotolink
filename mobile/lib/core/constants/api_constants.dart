class ApiConstants {
  // 10.0.2.2 es el alias especial hacia el host SOLO dentro del emulador
  // Android; para un dispositivo físico se necesita la IP de red local
  // de la máquina donde corre el backend (ambos en la misma red/WiFi).
  static const String baseUrl = 'http://localhost:8000/api';
  static const String socketUrl = 'http://localhost:8000';

  static const String usuarios = '/usuarios';
  static const String login = '/usuarios/login';
  static const String mototaxistas = '/mototaxistas';
  static const String solicitudesViaje = '/solicitudes-viaje';
  static const String ofertas = '/ofertas';
  static const String viajes = '/viajes';
  static const String historial = '/historial';
  static const String calificaciones = '/calificaciones';
}
