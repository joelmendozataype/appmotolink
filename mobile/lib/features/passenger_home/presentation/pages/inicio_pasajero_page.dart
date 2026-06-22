import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class InicioPasajeroPage extends StatelessWidget {
  const InicioPasajeroPage({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await context.read<AuthProvider>().cerrarSesion();
    if (context.mounted) context.go(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${usuario?.nombre ?? "Pasajero"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => context.push(AppRoutes.historialPasajero),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.electric_moped, size: 96, color: Colors.teal),
                const SizedBox(height: 24),
                Text(
                  '¿A dónde quieres ir?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.add_location_alt),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Solicitar un viaje'),
                  ),
                  onPressed: () => context.push(AppRoutes.crearSolicitud),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
