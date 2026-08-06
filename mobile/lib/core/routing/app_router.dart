import 'package:go_router/go_router.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/admin/presentation/pages/dashboard_admin_page.dart';
import 'package:mobile/features/admin/presentation/pages/gestion_usuarios_page.dart';
import 'package:mobile/features/admin/presentation/pages/lista_conductores_page.dart';
import 'package:mobile/features/admin/presentation/pages/lista_pasajeros_page.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/auth/presentation/pages/registro_mototaxista_page.dart';
import 'package:mobile/features/auth/presentation/pages/registro_pasajero_page.dart';
import 'package:mobile/features/auth/presentation/pages/role_selection_page.dart';
import 'package:mobile/features/driver_home/presentation/pages/inicio_mototaxista_page.dart';
import 'package:mobile/features/driver_home/presentation/pages/solicitudes_disponibles_page.dart';
import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';
import 'package:mobile/features/negotiation/presentation/pages/conductor_seleccionado_page.dart';
import 'package:mobile/features/negotiation/presentation/pages/contraoferta_page.dart';
import 'package:mobile/features/negotiation/presentation/pages/ofertas_recibidas_page.dart';
import 'package:mobile/features/auth/presentation/pages/recuperar_contrasena_page.dart';
import 'package:mobile/features/onboarding/presentation/pages/splash_page.dart';
import 'package:mobile/features/passenger_home/presentation/pages/inicio_pasajero_page.dart';
import 'package:mobile/features/rating/presentation/pages/calificacion_page.dart';
import 'package:mobile/features/trip_history/presentation/pages/historial_mototaxista_page.dart';
import 'package:mobile/features/trip_history/presentation/pages/historial_pasajero_page.dart';
import 'package:mobile/features/trip_request/presentation/pages/crear_solicitud_page.dart';
import 'package:mobile/features/trip_request/presentation/pages/proponer_tarifa_page.dart';
import 'package:mobile/features/trip_tracking/presentation/pages/viaje_asignado_page.dart';
import 'package:mobile/features/trip_tracking/presentation/pages/viaje_en_curso_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // ---------------- Autenticación ----------------
      GoRoute(
        path: AppRoutes.recuperarContrasena,
        name: AppRoutes.recuperarContrasenaName,
        builder: (context, state) => const RecuperarContrasenaPage(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        name: AppRoutes.roleSelectionName,
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) {
          final rol = RolUsuario.values.byName(
            state.pathParameters['rol']!,
          );
          return LoginPage(rol: rol);
        },
      ),
      GoRoute(
        path: AppRoutes.registroPasajero,
        name: AppRoutes.registroPasajeroName,
        builder: (context, state) => const RegistroPasajeroPage(),
      ),
      GoRoute(
        path: AppRoutes.registroMototaxista,
        name: AppRoutes.registroMototaxistaName,
        builder: (context, state) => const RegistroMototaxistaPage(),
      ),

      // ---------------- Pasajero ----------------
      GoRoute(
        path: AppRoutes.inicioPasajero,
        name: AppRoutes.inicioPasajeroName,
        builder: (context, state) => const InicioPasajeroPage(),
      ),
      GoRoute(
        path: AppRoutes.crearSolicitud,
        name: AppRoutes.crearSolicitudName,
        builder: (context, state) => const CrearSolicitudPage(),
      ),
      GoRoute(
        path: AppRoutes.proponerTarifa,
        name: AppRoutes.proponerTarifaName,
        builder: (context, state) {
          final args = state.extra as Map<String, String>;
          return ProponerTarifaPage(
            origen: args['origen']!,
            destino: args['destino']!,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.ofertasRecibidas,
        name: AppRoutes.ofertasRecibidasName,
        builder: (context, state) => OfertasRecibidasPage(
          solicitudId: state.pathParameters['solicitudId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.conductorSeleccionado,
        name: AppRoutes.conductorSeleccionadoName,
        builder: (context, state) => ConductorSeleccionadoPage(
          oferta: state.extra as Oferta,
        ),
      ),
      GoRoute(
        path: AppRoutes.viajeEnCurso,
        name: AppRoutes.viajeEnCursoName,
        builder: (context, state) => ViajeEnCursoPage(
          viajeId: state.pathParameters['viajeId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.calificacion,
        name: AppRoutes.calificacionName,
        builder: (context, state) => CalificacionPage(
          viajeId: state.pathParameters['viajeId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.historialPasajero,
        name: AppRoutes.historialPasajeroName,
        builder: (context, state) => const HistorialPasajeroPage(),
      ),

      // ---------------- Mototaxista ----------------
      GoRoute(
        path: AppRoutes.inicioMototaxista,
        name: AppRoutes.inicioMototaxistaName,
        builder: (context, state) => const InicioMototaxistaPage(),
      ),
      GoRoute(
        path: AppRoutes.solicitudesDisponibles,
        name: AppRoutes.solicitudesDisponiblesName,
        builder: (context, state) => const SolicitudesDisponiblesPage(),
      ),
      GoRoute(
        path: AppRoutes.contraoferta,
        name: AppRoutes.contraofertaName,
        builder: (context, state) => ContraofertaPage(
          solicitudId: state.pathParameters['solicitudId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.viajeAsignado,
        name: AppRoutes.viajeAsignadoName,
        builder: (context, state) => ViajeAsignadoPage(
          viajeId: state.pathParameters['viajeId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.historialMototaxista,
        name: AppRoutes.historialMototaxistaName,
        builder: (context, state) => const HistorialMototaxistaPage(),
      ),

      // ---------------- Administrador ----------------
      GoRoute(
        path: AppRoutes.dashboardAdmin,
        name: AppRoutes.dashboardAdminName,
        builder: (context, state) => const DashboardAdminPage(),
      ),
      GoRoute(
        path: AppRoutes.gestionUsuarios,
        name: AppRoutes.gestionUsuariosName,
        builder: (context, state) => const GestionUsuariosPage(),
      ),
      GoRoute(
        path: AppRoutes.listaConductores,
        name: AppRoutes.listaConductoresName,
        builder: (context, state) => const ListaConductoresPage(),
      ),
      GoRoute(
        path: AppRoutes.listaPasajeros,
        name: AppRoutes.listaPasajerosName,
        builder: (context, state) => const ListaPasajerosPage(),
      ),
    ],
  );
}
