import 'package:mobile/features/trip_history/domain/entities/historial_entity.dart';
import 'package:mobile/features/trip_history/domain/repositories/historial_repository.dart';

class ObtenerHistorial {
  final HistorialRepository repository;

  ObtenerHistorial(this.repository);

  Future<Historial> call(String usuarioId) {
    return repository.obtenerHistorial(usuarioId);
  }
}
