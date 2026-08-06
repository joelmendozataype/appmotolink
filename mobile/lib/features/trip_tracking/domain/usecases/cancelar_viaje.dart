import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/features/trip_tracking/domain/repositories/viaje_repository.dart';

/// Cualquiera de las dos partes puede cancelar un viaje que aún no
/// terminó. El backend comprueba que quien lo pide participa en él y que
/// sigue activo: si el otro acaba de cerrarlo, responde 409.
class CancelarViaje {
  final ViajeRepository repository;

  CancelarViaje(this.repository);

  Future<Viaje> call(String viajeId) {
    return repository.cancelarViaje(viajeId);
  }
}
