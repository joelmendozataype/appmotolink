import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _decidirDestino();
  }

  /// Si había sesión guardada y sigue siendo válida, entra directo a la
  /// pantalla del rol correspondiente; si no, a elegir rol.
  ///
  /// La espera mínima de un segundo evita el parpadeo del splash cuando
  /// la respuesta es inmediata. No se suman: se espera lo que tarde la
  /// más lenta de las dos.
  Future<void> _decidirDestino() async {
    final espera = Future<void>.delayed(const Duration(seconds: 1));
    final usuario = await context.read<AuthProvider>().restaurarSesion();
    await espera;

    if (!mounted) return;
    if (usuario == null) {
      context.go(AppRoutes.roleSelection);
      return;
    }
    context.go(switch (usuario.rol) {
      RolUsuario.pasajero => AppRoutes.inicioPasajero,
      RolUsuario.mototaxista => AppRoutes.inicioMototaxista,
      RolUsuario.administrador => AppRoutes.dashboardAdmin,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // El logo va sobre un recuadro blanco porque sus dos colores
            // —azul y verde— se pierden contra el verde del fondo. Y ya
            // trae el nombre escrito, así que no se repite debajo.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(
                'assets/logo_motolink.png',
                width: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
