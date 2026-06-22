import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';

abstract class MototaxistaRepository {
  Future<Mototaxista> obtenerPerfil(String usuarioId);
  Future<Mototaxista> registrarPerfil(Mototaxista mototaxista);
  Future<Mototaxista> actualizarPerfil(Mototaxista mototaxista);
  Future<List<Mototaxista>> listarTodos();
}
