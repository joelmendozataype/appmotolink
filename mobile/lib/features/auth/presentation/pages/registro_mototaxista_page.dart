import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/utils/validaciones.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';
import 'package:mobile/shared/widgets/campo_contrasena.dart';
import 'package:provider/provider.dart';

class RegistroMototaxistaPage extends StatefulWidget {
  const RegistroMototaxistaPage({super.key});

  @override
  State<RegistroMototaxistaPage> createState() =>
      _RegistroMototaxistaPageState();
}

class _RegistroMototaxistaPageState extends State<RegistroMototaxistaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _licenciaController = TextEditingController();
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  bool _cargando = false;

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await context.read<AuthProvider>().registrarMototaxista(
        Mototaxista(
          usuario: Usuario(
            id: '',
            nombre: _nombreController.text.trim(),
            correo: _correoController.text.trim(),
            contrasena: _contrasenaController.text,
            rol: RolUsuario.mototaxista,
          ),
          licencia: _licenciaController.text.trim(),
          placa: _placaController.text.trim(),
          marcaVehiculo: _marcaController.text.trim(),
          modeloVehiculo: _modeloController.text.trim(),
        ),
      );
      if (!mounted) return;
      context.go(AppRoutes.inicioMototaxista);
    } on ServerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar. ¿Correo ya en uso?')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Mototaxista')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration:
                          const InputDecoration(labelText: 'Nombre completo'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _correoController,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa tu correo' : null,
                    ),
                    const SizedBox(height: 16),
                    CampoContrasena(
                      controller: _contrasenaController,
                      esRegistro: true,
                      ayuda: 'Mínimo 8 caracteres. Evita contraseñas comunes.',
                      validator: Validaciones.contrasena,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenciaController,
                      decoration:
                          const InputDecoration(labelText: 'Número de licencia'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa tu licencia' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _placaController,
                      decoration: const InputDecoration(labelText: 'Placa'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa la placa' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _marcaController,
                      decoration:
                          const InputDecoration(labelText: 'Marca del vehículo'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa la marca' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modeloController,
                      decoration:
                          const InputDecoration(labelText: 'Modelo del vehículo'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa el modelo' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _cargando ? null : _registrar,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _cargando
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Crear cuenta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
