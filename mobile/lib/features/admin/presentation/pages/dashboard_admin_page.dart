import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  int _pasajeros = 0;
  int _mototaxistas = 0;
  int _viajes = 0;
  int _usuarios = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarConteos();
  }

  Future<void> _cargarConteos() async {
    final pasajeros = await ServiceLocator.listarPasajeros();
    final mototaxistas = await ServiceLocator.listarMototaxistas();
    final viajes = await ServiceLocator.listarViajes();
    final usuarios = await ServiceLocator.listarUsuarios();
    if (!mounted) return;
    setState(() {
      _pasajeros = pasajeros.length;
      _mototaxistas = mototaxistas.length;
      _viajes = viajes.length;
      _usuarios = usuarios.length;
      _cargando = false;
    });
  }

  Future<void> _cerrarSesion() async {
    await context.read<AuthProvider>().cerrarSesion();
    if (mounted) context.go(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    icon: Icons.people,
                    titulo: 'Pasajeros',
                    valor: '$_pasajeros',
                    color: Colors.indigo,
                    onTap: () => context.push(AppRoutes.listaPasajeros),
                  ),
                  _DashboardCard(
                    icon: Icons.two_wheeler,
                    titulo: 'Mototaxistas',
                    valor: '$_mototaxistas',
                    color: Colors.teal,
                    onTap: () => context.push(AppRoutes.listaConductores),
                  ),
                  _DashboardCard(
                    icon: Icons.directions_car,
                    titulo: 'Viajes totales',
                    valor: '$_viajes',
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    icon: Icons.manage_accounts,
                    titulo: 'Gestión de usuarios',
                    valor: '$_usuarios',
                    color: Colors.purple,
                    onTap: () => context.push(AppRoutes.gestionUsuarios),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.titulo,
    required this.valor,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                valor,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(titulo, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
