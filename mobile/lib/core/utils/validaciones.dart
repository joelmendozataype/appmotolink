/// Validaciones de formulario que deben coincidir con las del backend.
///
/// Existe este archivo para que las dos pantallas de registro no cada una
/// por su cuenta: antes exigían 4 caracteres mientras el backend pedía 8,
/// así que la app daba por buena una contraseña que el servidor rechazaba
/// después con un error poco claro.
///
/// La validación del servidor sigue mandando —es la única que no se puede
/// saltar—; esto solo evita el viaje de ida y vuelta.
class Validaciones {
  static const longitudMinimaContrasena = 8;

  /// Las más probadas por los ataques automáticos. El backend usa la
  /// lista completa de Django, de unas 20 000; aquí basta con atajar las
  /// obvias antes de enviar.
  static const _comunes = {
    'password', 'contrasena', '12345678', '123456789', 'qwertyui',
    'motolink', 'admin123', 'password1', '11111111', 'abcd1234',
  };

  static String? contrasena(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Ingresa una contraseña';
    if (v.length < longitudMinimaContrasena) {
      return 'Mínimo $longitudMinimaContrasena caracteres';
    }
    if (RegExp(r'^\d+$').hasMatch(v)) {
      return 'No uses solo números';
    }
    if (_comunes.contains(v.toLowerCase())) {
      return 'Esa contraseña es demasiado común';
    }
    return null;
  }
}
