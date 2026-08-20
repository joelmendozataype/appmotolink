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

  /// Límites de la tarifa, en soles. Los mismos que aplica el backend.
  ///
  /// El mínimo es 1 y no 0 porque un viaje gratis no es una tarifa: una
  /// solicitud de S/ 0 llegaba igual a todos los mototaxistas.
  static const tarifaMinima = 1.0;
  static const tarifaMaxima = 9999.99;

  /// Importe en soles: entero o con hasta dos decimales, desde S/ 1.
  ///
  /// El campo ya impide teclear otra cosa, pero esta comprobación queda
  /// como red: el filtro de escritura no cubre el pegado desde el
  /// portapapeles en todos los teclados.
  static String? tarifa(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa una tarifa';
    final monto = double.tryParse(v);
    if (monto == null) return 'Escribe solo números';
    if (monto < tarifaMinima) {
      return 'La tarifa mínima es S/ ${tarifaMinima.toStringAsFixed(0)}';
    }
    if (monto > tarifaMaxima) return 'Como mucho S/ $tarifaMaxima';
    final punto = v.indexOf('.');
    if (punto != -1 && v.length - punto - 1 > 2) {
      return 'Como mucho dos decimales';
    }
    return null;
  }

  /// Las coordenadas que escribe el botón del GPS: «-12.39031, -74.85911».
  ///
  /// Se comprueban aparte porque no parecen un nombre de lugar y, sin
  /// esta excepción, la validación rechazaría lo que la propia aplicación
  /// acaba de rellenar.
  static final _coordenadas = RegExp(r'^-?\d{1,3}\.\d+,\s*-?\d{1,3}\.\d+$');

  /// Un lugar empieza por letra o número, y admite lo que aparece en las
  /// direcciones de por aquí: «Jr. Grau 123», «Av. Los Andes», «Plaza de
  /// Pampas». Fuera quedan los signos que solo salen al teclear al azar.
  static final _lugar = RegExp(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9][A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,'\-/]*$",
  );

  static final _tieneLetra = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');

  /// Origen y destino de una solicitud.
  ///
  /// `campo` es «el origen» o «el destino», para que el mensaje diga cuál
  /// de los dos falta.
  static String? lugar(String? valor, {required String campo}) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa $campo';
    // Lo puso el GPS: se acepta tal cual.
    if (_coordenadas.hasMatch(v)) return null;
    if (v.length < 3) return 'Escribe al menos 3 caracteres';
    if (!_lugar.hasMatch(v)) {
      return 'Usa solo letras, números y espacios';
    }
    // «123» o «...» pasarían el filtro anterior sin nombrar ningún sitio.
    if (_tieneLetra.allMatches(v).length < 3) {
      return 'Escribe el nombre del lugar';
    }
    return null;
  }

  /// Letras y espacios entre palabras, nada más.
  ///
  /// Se admiten tildes y la eñe porque son letras corrientes en los
  /// nombres de aquí (José, Ñahui, Muñoz), y espacios entre palabras
  /// porque el campo pide el nombre completo. Lo que no entra: cifras,
  /// signos, y espacios al principio o al final.
  static final _nombre = RegExp(
    r'^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+( [A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$',
  );

  static String? nombre(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu nombre';
    if (v.length < 2) return 'Escribe tu nombre completo';
    // Mensaje aparte para el caso más frecuente, que es teclear cifras.
    if (RegExp(r'\d').hasMatch(v)) {
      return 'El nombre no puede tener números';
    }
    if (!_nombre.hasMatch(v)) {
      return 'Usa solo letras y espacios';
    }
    return null;
  }

  /// Algo@algo.algo, sin espacios y con al menos un punto en el dominio.
  ///
  /// No pretende cubrir el estándar completo de direcciones de correo, que
  /// admite rarezas que nadie escribe: basta con atajar lo que un usuario
  /// teclea por error.
  static final _correo = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$',
  );

  /// El backend usa EmailField de Django REST, que rechaza lo que no tenga
  /// forma de correo.
  ///
  /// Nace de una prueba real: el campo daba por bueno «12332werrd» y el
  /// usuario solo se enteraba del error después de llamar al servidor.
  static String? correo(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu correo';
    // Mensaje aparte para el caso más frecuente: escribir solo el usuario
    // y olvidar el dominio.
    if (!v.contains('@')) {
      return 'Falta el @ (ejemplo: tucorreo@gmail.com)';
    }
    if (!_correo.hasMatch(v)) {
      return 'Correo no válido (ejemplo: tucorreo@gmail.com)';
    }
    return null;
  }

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
