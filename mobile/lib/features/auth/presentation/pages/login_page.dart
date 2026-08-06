import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/shared/widgets/cabecera_curva.dart';
import 'package:mobile/shared/widgets/campo_contrasena.dart';
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

  /// Si se desmarca, la sesión dura solo hasta cerrar la app: no se
  /// guarda en el dispositivo. Útil en un teléfono prestado o compartido.
  bool _recordarme = true;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

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
        recordar: _recordarme,
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
    } catch (e) {
      // Los fallos de red no son ServerException: sin esta rama se
      // quedaban sin mensaje y el usuario no sabía qué había pasado.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeDeError(e)),
          duration: const Duration(seconds: 6),
        ),
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
    final colores = Theme.of(context).colorScheme;
    final mostrarRegistro = widget.rol != RolUsuario.administrador;

    return Scaffold(
      backgroundColor: colores.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cabecera(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _tarjetaFormulario(context),
                      if (mostrarRegistro) ...[
                        const SizedBox(height: 20),
                        _enlaceRegistro(context),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecera(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Stack(
      children: [
        CabeceraCurva(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.electric_moped,
                      size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Bienvenido!',
                  style: textos.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ingresa como $_tituloRol',
                  style: textos.bodyMedium
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ),
        // Vuelta atrás sobre la cabecera, ya que no hay AppBar.
        Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          left: 4,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Volver',
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.roleSelection),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaFormulario(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colores.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      // Los campos van sobre fondo oscuro: se sobreescribe el tema local
      // en vez de repetir la decoración campo por campo.
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            prefixIconColor: colores.primary,
            suffixIconColor: colores.primary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.black54),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _etiqueta('Correo electrónico'),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  hintText: 'tucorreo@ejemplo.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa tu correo' : null,
              ),
              const SizedBox(height: 16),
              _etiqueta('Contraseña'),
              CampoContrasena(
                controller: _contrasenaController,
                etiqueta: '',
                pista: '••••••••',
                iconoInicial: Icons.lock_outline,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Ingresa tu contraseña'
                    : null,
              ),
              const SizedBox(height: 4),
              _recordarmeFila(context),
              const SizedBox(height: 12),
              _botonIngresar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _recordarmeFila(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _recordarme,
            onChanged: (v) => setState(() => _recordarme = v ?? true),
            side: const BorderSide(color: Colors.white70, width: 1.5),
            checkColor: Theme.of(context).colorScheme.primary,
            fillColor: WidgetStateProperty.resolveWith(
              (estados) => estados.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.transparent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Toda la fila alterna la casilla: un cuadro de 24 px es un blanco
        // difícil de acertar con el pulgar.
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _recordarme = !_recordarme),
            child: const Text(
              'Mantener sesión iniciada',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _botonIngresar(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: _cargando ? null : _ingresar,
        child: _cargando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Ingresar'),
      ),
    );
  }

  Widget _enlaceRegistro(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    // Wrap y no Row: con el texto a un lado y el botón al otro, en
    // pantallas estrechas la fila se desbordaba y salía la franja de
    // aviso. Así pasa a la línea siguiente en vez de recortarse.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta?',
          style: TextStyle(color: colores.onSurfaceVariant),
        ),
        TextButton(
          onPressed: _irARegistro,
          child: const Text(
            'Regístrate',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
