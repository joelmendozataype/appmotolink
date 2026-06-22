import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final RolUsuario rol;

  const LoginPage({super.key, required this.rol});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _cargando = false;

  String get _tituloRol {
    switch (widget.rol) {
      case RolUsuario.pasajero:
        return 'Pasajero';
      case RolUsuario.mototaxista:
        return 'Mototaxista';
      case RolUsuario.administrador:
        return 'Administrador';
    }
  }

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final usuario = await context.read<AuthProvider>().login(
        _correoController.text.trim(),
        _contrasenaController.text,
      );

      String destino;
      switch (usuario.rol) {
        case RolUsuario.pasajero:
          destino = AppRoutes.inicioPasajero;
          break;
        case RolUsuario.mototaxista:
          destino = AppRoutes.inicioMototaxista;
          break;
        case RolUsuario.administrador:
          destino = AppRoutes.dashboardAdmin;
          break;
      }
      if (!mounted) return;
      context.go(destino);
    } on ServerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo o contraseña incorrectos')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _irARegistro() {
    if (widget.rol == RolUsuario.pasajero) {
      context.push(AppRoutes.registroPasajero);
    } else if (widget.rol == RolUsuario.mototaxista) {
      context.push(AppRoutes.registroMototaxista);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mostrarRegistro = widget.rol != RolUsuario.administrador;
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar sesión · $_tituloRol')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _correoController,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Ingresa tu correo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contrasenaController,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Ingresa tu contraseña'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _cargando ? null : _ingresar,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _cargando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ingresar'),
                    ),
                  ),
                  if (mostrarRegistro) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _irARegistro,
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
