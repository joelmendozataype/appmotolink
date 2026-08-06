import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/di/service_locator.dart';

/// Notificaciones push del dispositivo.
///
/// Socket.IO solo llega con la app abierta. Esto cubre el resto: avisa al
/// mototaxista de una solicitud nueva aunque tenga el teléfono guardado,
/// que es justo cuando más falta hace.
///
/// Todo el servicio está escrito para no romper nada si Firebase falla o
/// el usuario deniega el permiso: la app siguió funcionando sin push
/// hasta ahora y debe seguir haciéndolo.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  String? _token;
  bool _iniciado = false;

  /// Token del dispositivo, o null si aún no se obtuvo.
  String? get token => _token;

  /// Arranca Firebase. Se llama una vez, al iniciar la app.
  ///
  /// No pide permiso todavía ni registra el token: eso se hace tras el
  /// login, cuando ya se sabe a qué usuario asociarlo.
  Future<void> iniciar() async {
    if (_iniciado) return;
    try {
      await Firebase.initializeApp();
      _iniciado = true;
    } catch (e) {
      // Sin google-services.json válido, o sin Play Services en el
      // aparato. La app funciona igual, solo sin notificaciones.
      debugPrint('[PushService] Firebase no disponible: $e');
    }
  }

  /// Pide permiso, obtiene el token y lo registra en el backend.
  ///
  /// Se llama después de iniciar sesión: el backend asocia el token al
  /// usuario autenticado, así que antes no serviría de nada.
  Future<void> registrarDispositivo() async {
    if (!_iniciado) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final permiso = await messaging.requestPermission();
      if (permiso.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[PushService] el usuario denegó las notificaciones');
        return;
      }

      final token = await messaging.getToken();
      if (token == null) return;
      _token = token;
      await ServiceLocator.registrarDispositivo(token);

      // El token se renueva solo de vez en cuando; hay que volver a
      // registrarlo o el teléfono deja de recibir avisos en silencio.
      messaging.onTokenRefresh.listen((nuevo) async {
        _token = nuevo;
        try {
          await ServiceLocator.registrarDispositivo(nuevo);
        } catch (e) {
          debugPrint('[PushService] no se pudo renovar el token: $e');
        }
      });
    } catch (e) {
      debugPrint('[PushService] no se pudo registrar el dispositivo: $e');
    }
  }

  /// Da de baja el dispositivo al cerrar sesión.
  ///
  /// Sin esto, el teléfono seguiría recibiendo avisos de una cuenta que
  /// ya no está en uso: incómodo en un aparato compartido.
  Future<void> darDeBaja() async {
    final token = _token;
    if (token == null) return;
    try {
      await ServiceLocator.darDeBajaDispositivo(token);
    } catch (e) {
      debugPrint('[PushService] no se pudo dar de baja el token: $e');
    }
    _token = null;
  }

  /// Notificaciones que llegan con la app en primer plano.
  ///
  /// Android no las muestra solo en ese caso: el sistema asume que ya
  /// estás viendo la app. Se expone el flujo para que la interfaz decida
  /// qué hacer.
  Stream<RemoteMessage> get enPrimerPlano => FirebaseMessaging.onMessage;
}
