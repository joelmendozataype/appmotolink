import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Mapa de un viaje en curso, sobre cartografía de OpenStreetMap.
///
/// Sustituye a los recuadros de relleno que decían "Mapa en vivo
/// (simulado)". Se eligió OpenStreetMap frente a Google Maps y Mapbox
/// porque las tres fuentes comparten los mismos datos de calles —Mapbox
/// se construye sobre OSM— y solo OSM funciona sin tarjeta de crédito ni
/// token, sin sacar el proyecto Firebase del plan gratuito.
///
/// Cambiar de proveedor más adelante es cambiar `urlTemplate`: el resto
/// del widget no depende de quién sirva las imágenes.
class MapaViaje extends StatefulWidget {
  /// Posición propia, la que se sigue con el GPS del dispositivo.
  final Position? posicion;

  /// Recorrido acumulado, para dibujar por dónde se ha pasado.
  final List<Position> recorrido;

  /// Icono del marcador propio: distingue al mototaxista del pasajero.
  final IconData icono;

  /// Texto que se muestra bajo el mapa (distancia recorrida, estado...).
  final String? leyenda;

  const MapaViaje({
    super.key,
    required this.posicion,
    this.recorrido = const [],
    this.icono = Icons.my_location,
    this.leyenda,
  });

  @override
  State<MapaViaje> createState() => _MapaViajeState();
}

class _MapaViajeState extends State<MapaViaje> {
  final MapController _controlador = MapController();

  /// Pampas, Tayacaja. Solo se usa mientras el GPS no ha respondido
  /// todavía, para no arrancar mostrando el océano frente a África, que
  /// es donde cae la coordenada (0, 0).
  static const _centroPorDefecto = LatLng(-12.3987, -74.8684);

  LatLng? get _puntoActual => widget.posicion == null
      ? null
      : LatLng(widget.posicion!.latitude, widget.posicion!.longitude);

  @override
  void didUpdateWidget(MapaViaje anterior) {
    super.didUpdateWidget(anterior);
    // Seguir la posición según avanza, sin arrebatarle el control al
    // usuario: solo se recentra cuando la posición cambia de verdad.
    final punto = _puntoActual;
    if (punto != null && widget.posicion != anterior.posicion) {
      _controlador.move(punto, _controlador.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final punto = _puntoActual;
    final colores = Theme.of(context).colorScheme;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            initialCenter: punto ?? _centroPorDefecto,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              // Sin rotación: en un viaje desorienta más que ayuda, y se
              // activa sin querer al hacer zoom con dos dedos.
              flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // Requisito de la política de uso de OpenStreetMap: sus
              // servidores son infraestructura donada y exigen que cada
              // cliente se identifique.
              userAgentPackageName: 'pe.edu.unh.motolink',
              maxZoom: 19,
            ),
            if (widget.recorrido.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.recorrido
                        .map((p) => LatLng(p.latitude, p.longitude))
                        .toList(),
                    strokeWidth: 4,
                    color: colores.primary,
                  ),
                ],
              ),
            if (punto != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: punto,
                    width: 44,
                    height: 44,
                    child: _Pin(icono: widget.icono, color: colores.primary),
                  ),
                ],
              ),
            // La atribución no es decorativa: la licencia de
            // OpenStreetMap obliga a mostrar el crédito.
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (punto == null)
          const Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _Aviso('Buscando tu ubicación…'),
          ),
        if (widget.leyenda != null)
          Positioned(
            bottom: 12,
            left: 12,
            child: _Aviso(widget.leyenda!),
          ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  final IconData icono;
  final Color color;

  const _Pin({required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icono, color: Colors.white, size: 24),
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 13)),
    );
  }
}
