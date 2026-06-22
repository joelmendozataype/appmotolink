import 'package:geolocator/geolocator.dart';

class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException(this.message);
}

/// Envuelve geolocator: pide permiso si falta y devuelve la posición GPS
/// real del dispositivo. No hace geocodificación inversa (sin clave de
/// API de mapas); el origen se representa como coordenadas.
class LocationService {
  LocationService._();

  static Future<Position> obtenerUbicacionActual() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      throw LocationPermissionDeniedException(
        'El GPS del dispositivo está desactivado.',
      );
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(
        'Permiso de ubicación denegado.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  static String formatear(Position posicion) {
    return '${posicion.latitude.toStringAsFixed(5)}, '
        '${posicion.longitude.toStringAsFixed(5)}';
  }
}
