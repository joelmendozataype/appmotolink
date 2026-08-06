import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/enums/rol_usuario.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/shared/widgets/cabecera_curva.dart';
import 'package:mobile/shared/widgets/campo_contrasena.dart';
import 'package:provider/provider.dart';

Widget _pantalla(RolUsuario rol) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: LoginPage(rol: rol),
    ),
  );
}

void main() {
  testWidgets('muestra la cabecera curva y el rol elegido', (tester) async {
    await tester.pumpWidget(_pantalla(RolUsuario.mototaxista));

    expect(find.byType(CabeceraCurva), findsOneWidget);
    expect(find.text('¡Bienvenido!'), findsOneWidget);
    expect(find.text('Ingresa como Mototaxista'), findsOneWidget);
  });

  testWidgets('trae los dos campos y el botón', (tester) async {
    await tester.pumpWidget(_pantalla(RolUsuario.pasajero));

    expect(find.byType(CampoContrasena), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('la casilla de sesión viene marcada por defecto',
      (tester) async {
    await tester.pumpWidget(_pantalla(RolUsuario.pasajero));

    expect(find.text('Mantener sesión iniciada'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('tocar el texto alterna la casilla, no solo el cuadro',
      (tester) async {
    await tester.pumpWidget(_pantalla(RolUsuario.pasajero));

    await tester.tap(find.text('Mantener sesión iniciada'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets('valida los campos vacíos antes de llamar al backend',
      (tester) async {
    await tester.pumpWidget(_pantalla(RolUsuario.pasajero));

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('el administrador no ve el enlace de registro',
      (tester) async {
    // Registrarse como administrador está prohibido en el backend: el
    // enlace solo confundiría.
    await tester.pumpWidget(_pantalla(RolUsuario.administrador));
    expect(find.text('Regístrate'), findsNothing);

    await tester.pumpWidget(_pantalla(RolUsuario.pasajero));
    expect(find.text('Regístrate'), findsOneWidget);
  });
}
