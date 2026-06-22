import 'package:mobile/features/trip_history/domain/entities/historial_entity.dart';

abstract class HistorialRepository {
  Future<Historial> obtenerHistorial(String usuarioId);
}
