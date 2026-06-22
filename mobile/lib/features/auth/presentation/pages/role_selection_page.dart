import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/routing/app_routes.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void _seleccionar(BuildContext context, RolUsuario rol) {
    context.push(AppRoutes.loginPath(rol.name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¿Cómo quieres usar MOTOLINK?')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoleCard(
                  icon: Icons.person,
                  titulo: 'Soy Pasajero',
                  subtitulo: 'Solicita un mototaxi y negocia tu tarifa',
                  onTap: () => _seleccionar(context, RolUsuario.pasajero),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.two_wheeler,
                  titulo: 'Soy Mototaxista',
                  subtitulo: 'Recibe solicitudes y ofrece tu tarifa',
                  onTap: () => _seleccionar(context, RolUsuario.mototaxista),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.admin_panel_settings,
                  titulo: 'Soy Administrador',
                  subtitulo: 'Gestiona usuarios de la plataforma',
                  onTap: () => _seleccionar(context, RolUsuario.administrador),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 36),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
