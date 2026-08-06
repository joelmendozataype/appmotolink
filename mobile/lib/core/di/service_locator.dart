import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/push/dispositivo_datasource.dart';
import 'package:mobile/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:mobile/features/auth/data/repositories/usuario_repository_impl.dart';
import 'package:mobile/features/auth/domain/usecases/eliminar_usuario.dart';
import 'package:mobile/features/auth/domain/usecases/listar_pasajeros.dart';
import 'package:mobile/features/auth/domain/usecases/listar_usuarios.dart';
import 'package:mobile/features/auth/domain/usecases/login_usuario.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usuario.dart';
import 'package:mobile/features/auth/domain/usecases/obtener_usuario_actual.dart';
import 'package:mobile/features/auth/domain/usecases/registrar_usuario.dart';
import 'package:mobile/features/negotiation/data/datasources/oferta_remote_datasource.dart';
import 'package:mobile/features/negotiation/data/repositories/oferta_repository_impl.dart';
import 'package:mobile/features/negotiation/domain/usecases/aceptar_solicitud.dart';
import 'package:mobile/features/negotiation/domain/usecases/contraofertar_solicitud.dart';
import 'package:mobile/features/negotiation/domain/usecases/obtener_ofertas.dart';
import 'package:mobile/features/negotiation/domain/usecases/rechazar_solicitud.dart';
import 'package:mobile/features/negotiation/domain/usecases/seleccionar_oferta.dart';
import 'package:mobile/features/profile/data/datasources/mototaxista_remote_datasource.dart';
import 'package:mobile/features/profile/data/repositories/mototaxista_repository_impl.dart';
import 'package:mobile/features/profile/domain/usecases/listar_mototaxistas.dart';
import 'package:mobile/features/profile/domain/usecases/registrar_perfil_mototaxista.dart';
import 'package:mobile/features/rating/data/datasources/calificacion_remote_datasource.dart';
import 'package:mobile/features/rating/data/repositories/calificacion_repository_impl.dart';
import 'package:mobile/features/rating/domain/usecases/enviar_calificacion.dart';
import 'package:mobile/features/trip_history/data/datasources/historial_remote_datasource.dart';
import 'package:mobile/features/trip_history/data/repositories/historial_repository_impl.dart';
import 'package:mobile/features/trip_history/domain/usecases/obtener_historial.dart';
import 'package:mobile/features/trip_request/data/datasources/solicitud_viaje_remote_datasource.dart';
import 'package:mobile/features/trip_request/data/repositories/solicitud_viaje_repository_impl.dart';
import 'package:mobile/features/trip_request/domain/usecases/cancelar_solicitud_viaje.dart';
import 'package:mobile/features/trip_request/domain/usecases/crear_solicitud_viaje.dart';
import 'package:mobile/features/trip_request/domain/usecases/obtener_solicitudes_disponibles.dart';
import 'package:mobile/features/trip_tracking/data/datasources/viaje_remote_datasource.dart';
import 'package:mobile/features/trip_tracking/data/repositories/viaje_repository_impl.dart';
import 'package:mobile/features/trip_tracking/domain/usecases/cancelar_viaje.dart';
import 'package:mobile/features/trip_tracking/domain/usecases/finalizar_viaje.dart';
import 'package:mobile/features/trip_tracking/domain/usecases/listar_viajes.dart';
import 'package:mobile/features/trip_tracking/domain/usecases/obtener_viaje_activo.dart';
import 'package:mobile/features/trip_tracking/domain/usecases/obtener_viaje_por_id.dart';

/// Punto de composición manual (sin paquete de DI): instancia una sola vez
/// el cliente HTTP y encadena datasource -> repository -> usecase para
/// cada feature, siguiendo ApiClient -> *RemoteDataSourceImpl ->
/// *RepositoryImpl -> *UseCase. Las páginas importan esta clase para
/// consumir el backend real.
class ServiceLocator {
  ServiceLocator._();

  static final ApiClient apiClient = ApiClient();
  static final _dispositivoDs = DispositivoDataSource(apiClient);

  // ---- Auth ----
  static final _usuarioDs = UsuarioRemoteDataSourceImpl(apiClient);
  static final _usuarioRepo = UsuarioRepositoryImpl(_usuarioDs);
  static final loginUsuario = LoginUsuario(_usuarioRepo);
  static final registrarUsuario = RegistrarUsuario(_usuarioRepo);
  static final obtenerUsuarioActual = ObtenerUsuarioActual(_usuarioRepo);
  static final logoutUsuario = LogoutUsuario(_usuarioRepo);

  static Future<void> pedirCodigoRecuperacion(String correo) =>
      _usuarioDs.pedirCodigoRecuperacion(correo);
  static Future<void> restablecerContrasena(
    String correo,
    String codigo,
    String contrasena,
  ) =>
      _usuarioDs.restablecerContrasena(correo, codigo, contrasena);
  static final listarUsuarios = ListarUsuarios(_usuarioRepo);
  static final listarPasajeros = ListarPasajeros(_usuarioRepo);
  static final eliminarUsuario = EliminarUsuario(_usuarioRepo);

  // ---- Profile (Mototaxista) ----
  static final _mototaxistaDs = MototaxistaRemoteDataSourceImpl(apiClient);
  static final _mototaxistaRepo = MototaxistaRepositoryImpl(_mototaxistaDs);
  static final registrarPerfilMototaxista =
      RegistrarPerfilMototaxista(_mototaxistaRepo);
  static final listarMototaxistas = ListarMototaxistas(_mototaxistaRepo);

  // ---- Trip request (SolicitudViaje) ----
  static final _solicitudDs = SolicitudViajeRemoteDataSourceImpl(apiClient);
  static final _solicitudRepo = SolicitudViajeRepositoryImpl(_solicitudDs);
  static final crearSolicitudViaje = CrearSolicitudViaje(_solicitudRepo);
  static final cancelarSolicitudViaje = CancelarSolicitudViaje(_solicitudRepo);
  static final obtenerSolicitudesDisponibles =
      ObtenerSolicitudesDisponibles(_solicitudRepo);

  // ---- Negotiation (Oferta) ----
  static final _ofertaDs = OfertaRemoteDataSourceImpl(apiClient);
  static final _ofertaRepo = OfertaRepositoryImpl(_ofertaDs);
  static final aceptarSolicitud = AceptarSolicitud(_ofertaRepo);
  static final contraofertarSolicitud = ContraofertarSolicitud(_ofertaRepo);
  static final rechazarSolicitud = RechazarSolicitud(_ofertaRepo);
  static final obtenerOfertas = ObtenerOfertas(_ofertaRepo);
  static final seleccionarOferta = SeleccionarOferta(_ofertaRepo);

  // ---- Trip tracking (Viaje) ----
  static final _viajeDs = ViajeRemoteDataSourceImpl(apiClient);
  static final _viajeRepo = ViajeRepositoryImpl(_viajeDs);
  static final obtenerViajeActivo = ObtenerViajeActivo(_viajeRepo);
  static final obtenerViajePorId = ObtenerViajePorId(_viajeRepo);
  static final finalizarViaje = FinalizarViaje(_viajeRepo);
  static final cancelarViaje = CancelarViaje(_viajeRepo);

  static Future<void> registrarDispositivo(String token) =>
      _dispositivoDs.registrar(token);
  static Future<void> darDeBajaDispositivo(String token) =>
      _dispositivoDs.darDeBaja(token);
  static final listarViajes = ListarViajes(_viajeRepo);

  // ---- Trip history (Historial) ----
  static final _historialDs = HistorialRemoteDataSourceImpl(apiClient);
  static final _historialRepo = HistorialRepositoryImpl(_historialDs);
  static final obtenerHistorial = ObtenerHistorial(_historialRepo);

  // ---- Rating (Calificación) ----
  static final _calificacionDs = CalificacionRemoteDataSourceImpl(apiClient);
  static final _calificacionRepo = CalificacionRepositoryImpl(_calificacionDs);
  static final enviarCalificacion = EnviarCalificacion(_calificacionRepo);
}
