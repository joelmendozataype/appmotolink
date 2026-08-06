import 'package:mobile/core/enums/estado_viaje.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';

abstract class ViajeRepository {
  Future<Viaje> obtenerPorId(String viajeId);
  Future<Viaje> obtenerViajeActivo(String usuarioId);
  Future<Viaje> actualizarEstado(String viajeId, EstadoViaje estado);
  Future<Viaje> finalizarViaje(String viajeId);

  Future<Viaje> cancelarViaje(String viajeId);
  Future<List<Viaje>> listarTodos();
}
