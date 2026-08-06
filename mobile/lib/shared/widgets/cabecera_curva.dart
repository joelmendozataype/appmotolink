import 'package:flutter/material.dart';

/// Recorta la cabecera con una curva suave, en vez de un borde recto.
///
/// La curva baja más por la izquierda que por la derecha para que no
/// quede simétrica, que es lo que le da el aspecto de onda.
class _OndaClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.25, size.height,
        size.width * 0.55, size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.85, size.height * 0.74,
        size.width, size.height * 0.42,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Cabecera con degradado y curva inferior, para las pantallas de acceso.
class CabeceraCurva extends StatelessWidget {
  final Widget child;
  final double altura;

  const CabeceraCurva({super.key, required this.child, this.altura = 260});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return ClipPath(
      clipper: _OndaClipper(),
      child: Container(
        height: altura,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colores.primary,
              Color.lerp(colores.primary, const Color(0xFFC8E063), 0.75)!,
            ],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
