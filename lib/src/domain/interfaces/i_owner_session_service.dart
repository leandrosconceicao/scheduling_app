import 'package:flutter/foundation.dart';

/// Sessão do proprietário da empresa (área administrativa).
///
/// É um [Listenable] para que o roteador reavalie as guardas no login/logout.
abstract interface class IOwnerSessionService implements Listenable {
  bool get isAuthenticated;
  String get token;

  Future<void> start(String token);
  Future<void> end();
}
