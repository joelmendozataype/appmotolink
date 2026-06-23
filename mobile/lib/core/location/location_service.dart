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

/// Cálculos sobre posiciones GPS reales (no simuladas): distancia entre dos
/// puntos, tiempo estimado a velocidad de mototaxi urbano, formato legible
/// y un stream para seguir la ubicación en vivo durante un viaje.
class LocationCalculos {
  LocationCalculos._();

  /// Distancia en línea recta entre dos posiciones, vía la fórmula de
  /// Haversine que ya implementa geolocator.
  static double distanciaEnMetros(Position origen, Position destino) {
    return Geolocator.distanceBetween(
      origen.latitude,
      origen.longitude,
      destino.latitude,
      destino.longitude,
    );
  }

  /// Minutos estimados para recorrer [metros] a una velocidad promedio de
  /// mototaxi urbano (20 km/h por defecto), redondeado hacia arriba.
  static int minutosEstimados(double metros, {double velocidadKmh = 20}) {
    final metrosPorMinuto = (velocidadKmh * 1000) / 60;
    return (metros / metrosPorMinuto).ceil();
  }

  static String distanciaLegible(double metros) {
    if (metros < 1000) return '${metros.round()} m';
    return '${(metros / 1000).toStringAsFixed(1)} km';
  }

  /// Stream de posiciones en vivo (ej. para seguir el avance durante un
  /// viaje en curso). [distanciaMinimaMetros] evita actualizaciones
  /// excesivas cuando el dispositivo apenas se mueve.
  static Stream<Position> seguirUbicacion({int distanciaMinimaMetros = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanciaMinimaMetros,
      ),
    );
  }
}
